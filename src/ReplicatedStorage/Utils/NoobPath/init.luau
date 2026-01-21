-- Version 1.811 (optimized visualize, cached Enums, changed CheckForTimeout to CheckTimeout, Jump no long returns the waypoint position[unintended], OnDestroy now fires instantly when destroy is called, did a small change to the Humanoid Jump logic)

--[[

MIT License

Copyright (c) <2025> <grewsxb4>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

local Path = require(script:WaitForChild("Path"))
local RS = game:GetService("RunService")
local Signal = require(script.Parent.Signal)

local module = {}

local NoobPath = {}
NoobPath.__index = NoobPath

local JUMP = Enum.PathWaypointAction.Jump
local AIR = Enum.Material.Air
local JUMPING = Enum.HumanoidStateType.Jumping
local FREEFALL = Enum.HumanoidStateType.Freefall

export type Location = Vector3 | BasePart | Model

local function GetPrimaryPivot(Model : Model)
	return Model.PrimaryPart and Model.PrimaryPart:GetPivot() or Model:GetPivot()
end

local function ToVector3(Location : Location)
	if typeof(Location) == "Vector3" then
		return Location
	elseif Location:IsA("Model") then
		return GetPrimaryPivot(Location).Position
	elseif Location:IsA("BasePart") then
		return Location:GetPivot().Position
	end

    return
end

local function RemoveNetworkOwner(Character : Model)
	local Descendants = Character:GetDescendants()
	for i = 1, #Descendants do
		local Item = Descendants[i]
		if Item:IsA("BasePart") and Item:CanSetNetworkOwnership() then
			Item:SetNetworkOwner(nil)
		end
	end
end

local function Default(AgentParams, NoobPath)
	NoobPath.Path = Path.new(AgentParams)
	NoobPath.Route = {}
	NoobPath.Index = 1
	NoobPath.Idle = true
	NoobPath.InAir = false
	NoobPath.Estimate = {}
	NoobPath.Destroying = false
	NoobPath.Goal = nil
	NoobPath.Partial = false

	NoobPath.Overide = Signal.new()
	NoobPath.Reached = Signal.new()
	NoobPath.WaypointReached = Signal.new()
	NoobPath.Error = Signal.new()
	NoobPath.Trapped = Signal.new()
	NoobPath.Stopped = Signal.new()
	NoobPath.OnDestroy = Signal.new()

	NoobPath.Timeout = false -- trigger trapped if didn't arrive in time, time is auto estimated using speed
	NoobPath.Speed = 16 -- default speed
	NoobPath.Visualize = false -- if there are many npcs with visualize on, it can create lag & disrupt pathfind
end

local Server = RS:IsServer()

-- Constructor
function module.new(Character: Model, AgentParams: Path.AgentParams?, Move: (Vector3) -> nil, Jump: (() -> nil)?, JumpFinished: RBXScriptSignal, MoveFinished: RBXScriptSignal)
	if Server then
		RemoveNetworkOwner(Character)
	end
	
	local self = setmetatable({
		Character = Character,

		Move = Move,
		Jump = Jump,
		MoveFinished = MoveFinished,
		JumpFinished = JumpFinished,

		MoveFinishedC = nil,
		JumpFinishedC = nil,

	}, NoobPath)
	
	Default(AgentParams, self)
	
	self:Activate()
	
	return self
end

-- Constructor With Default Humanoid Signals
function module.Humanoid(Character : Model, AgentParams : Path.AgentParams?, Precise : boolean?)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local Move = function(WaypointPosition) Humanoid:MoveTo(WaypointPosition) end
	
	local JumpFinished = Signal.new()
	local MoveFinished = Humanoid.MoveToFinished
	
	local self = module.new(Character, AgentParams, Move, nil, JumpFinished, MoveFinished)
	
	local Jump = function() 
		if Humanoid.FloorMaterial ~= AIR then
			Humanoid:ChangeState(JUMPING)
			return
		end
		
		local C : RBXScriptConnection
		local A : RBXScriptConnection
		local B : RBXScriptConnection
		
		if Precise then
			C = self.Overide:Connect(function()
				C:Disconnect()
				A:Disconnect()
				B:Disconnect()
			end)
		else
			C = self.Overide:Connect(function()
				C:Disconnect()
				A:Disconnect()
				B:Disconnect()
				self.InAir = false -- this allow the agent to still compute path even in air, which is often inaccurate. However, it works exceptionally well when given a relatively low jump power and obstacles that fits with such a jump power, and works nicely for default humanoids with a jump power of 50.
				-- copy this down if you want this behavior in custom implementations, otherwise computing path is paused while the agent is in air by default.
			end)
		end
		
		A = Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			if Humanoid.FloorMaterial ~= AIR then
				Humanoid:ChangeState(JUMPING)
				C:Disconnect()
				A:Disconnect()
				B:Disconnect()
			end
		end)
		B = self.OnDestroy:Connect(function()
			C:Disconnect()
			A:Disconnect()
			B:Disconnect()
		end)
	end
	
	local C = Humanoid.StateChanged:Connect(function(Old, New)
		if (Old == JUMPING or Old == FREEFALL) and (New ~= JUMPING and New ~= FREEFALL) then
			JumpFinished:Fire()
		end
	end)
	
	local A
	A = self.OnDestroy:Connect(function()
		A:Disconnect()
		C:Disconnect()
	end)
	
	self.Jump = Jump
	
	return self
end

function module.View(AgentParams : Path.AgentParams)
	local self = setmetatable({
		View = true,

	}, NoobPath)
	
	Default(AgentParams, self)
	
	return self
end

function NoobPath:Compute(PointA : Vector3, PointB : Vector3)
	local Route, Partial = self.Path:Generate(PointA, PointB)
	
	if self.Destroying ~= false then
		return
	end

	if not self:ValidateRoute(Route, Partial) then
		return
	end
	
	self.Route = Route
	self.Partial = Partial
	
	if self.Timeout then
		if not self.Speed then
			error("No Speed Provided")
		end
		self:Predict()
	end

	if self.Visualize then
		self:Show()
	end
	
	return true
end

function NoobPath:Show()
	self.Path:Show(self.Route)
end

function NoobPath:Hide()
	self.Path:Hide()
end

function NoobPath:Predict()
	self.Estimate = self.Path:Estimate(self.Route, self.Speed)
end

function NoobPath:GetEstimateTotal()
	local Estimate = self.Estimate
	
	local Sum = 0
	for i = 1, #Estimate do
		Sum += Estimate[i]
	end
	
	return Sum
end

function NoobPath:Activate()
	if Server then
		self.DescendantAddedC = self.Character.DescendantAdded:Connect(function(Item)
			if Item:IsA("BasePart") and Item:CanSetNetworkOwnership() then
				Item:SetNetworkOwner(nil)
			end
		end)
	end
	
	self.MoveFinishedC = self.MoveFinished:Connect(function(Success) -- if you are using custom MoveFinished, Fire(true) if successfully reached
		if self.Idle then
			return
		end
		if Success then
			local NextWaypoint = self:GetNextWaypoint()
			if NextWaypoint then
				self:TravelNextWaypoint()
				self.WaypointReached:Fire(self:GetWaypoint(), NextWaypoint)

			else
				self:Arrive()
			end
		else
			self:Stop()
			self.Trapped:Fire("ReachFailed")
		end
	end)
	self.JumpFinishedC = self.JumpFinished:Connect(function()
		self.InAir = false
	end)
end

function NoobPath:PauseUntilLanded()
	local C :RBXScriptConnection
	local A : RBXScriptConnection
	local B :RBXScriptConnection
	
	C = self.Overide:Connect(function()
		C:Disconnect()
		A:Disconnect()
		B:Disconnect()
	end)
	
	A = self.JumpFinished:Connect(function()
		C:Disconnect()
		A:Disconnect()
		B:Disconnect()
		self:Run()
	end)
	
	B = self.OnDestroy:Connect(function()
		C:Disconnect()
		A:Disconnect()
		B:Disconnect()
	end)
end

function NoobPath:ValidateRoute(Route : Path.Route, Partial : boolean)
	if not Route then
		self.Error:Fire("ComputationError") -- No Route Generated/Error when generating
		return
	end
	if #Route == 0 then
		self.Error:Fire("TargetUnreachable") -- Can't Find Path
		return
	end
	if #Route < 2 then -- Route too short, likely already arrived
		self:Arrive(Route, Partial)
		return
	end
	return true
end

-- Caculate Route To Location & Move The Character There
function NoobPath:Run(Location : Location)
	if self.Destroying ~= false then
		return
	end
	
	self.Overide:Fire()
	
	if Location then
		self.Goal = Location
	else
		Location = self.Goal or error("No Destination Provided")
	end
	
	if self.InAir then
		self:PauseUntilLanded()
		return
	end
	
	if not self:Compute(GetPrimaryPivot(self.Character).Position, ToVector3(Location)) then
		return
	end
	
	self.Index = 1
	self.Idle = false
	
	self:TravelNextWaypoint()
end

-- Stop The Character From Moving
function NoobPath:Stop()
	if self.Destroying ~= false then
		return
	end
	self.Idle = true
	
	self.Overide:Fire()
	self.Move(GetPrimaryPivot(self.Character).Position)
	self.Stopped:Fire()
end

function NoobPath:GetLastWaypoint()
	local Route = self.Route
	return Route[#Route]
end

function NoobPath:GetWaypoint()
	return self.Route[self.Index]
end

function NoobPath:GetNextWaypoint()
	return self.Route[self.Index + 1]
end

function NoobPath:GetEstimateTime()
	return self.Estimate[self.Index]
end

function NoobPath:CheckTimeout()
	local Time = self:GetEstimateTime()
	if not Time then
		return
	end
	
	local Route = self.Route
	local Index = self.Index
	
	task.delay(Time * 2, function() -- usually double time work best, not too sensitive
		if not self.Idle and self.Route == Route and self.Index == Index then
			self.Trapped:Fire("ReachTimeout")
		end
	end)
end

function NoobPath:TravelNextWaypoint()
	self.Index += 1
	self:TravelWaypoint()
end

function NoobPath:TravelWaypoint()
	local Waypoint = self:GetWaypoint()
	if self.Idle or not Waypoint then
		return
	end
	self.Move(Waypoint.Position)
	if self.Timeout then
		self:CheckTimeout()
	end
	if Waypoint.Action == JUMP then
		self.InAir = true
		self.Jump()
	end
end

function NoobPath:Arrive(Route, Partial)
	Route = Route or self.Route
	local Waypoint = Route[#Route]
	
	self.Idle = true
	self.Overide:Fire()
	self.Reached:Fire(Waypoint, Partial or self.Partial)
end

local function Terminate(self)
	self.Path:Destroy()
	self.Reached:DisconnectAll()
	self.WaypointReached:DisconnectAll()
	self.Trapped:DisconnectAll()
	self.Error:DisconnectAll()
	self.Overide:DisconnectAll()
	self.OnDestroy:DisconnectAll()

	table.clear(self)
	setmetatable(self, nil)
	self = nil
end

function NoobPath:Dump()
	self.Destroying = true
	self.OnDestroy:Fire()
	
	task.defer(Terminate, self) -- defer for things to settle down
end

-- Destroy The NoobPath Object
function NoobPath:Destroy()
	self:Stop()
	self.Destroying = true
	
	self.MoveFinishedC:Disconnect()
	self.JumpFinishedC:Disconnect()
	
	if Server then
		self.DescendantAddedC:Disconnect()
	end
	
	self:Dump()
end

return module
