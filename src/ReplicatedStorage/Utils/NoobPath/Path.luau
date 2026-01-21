local PFS = game:GetService("PathfindingService")

local module = {}

local Path = {}
Path.__index = Path

local JUMP = Enum.PathWaypointAction.Jump
local PARTIAL = Enum.PathStatus.ClosestNoPath

export type Route = {PathWaypoint}
export type AgentParams = {
	AgentRadius : number, --(The Radius Of The Object(Half Its width))
	AgentHeight : number, --(The Height Of The Object)
	AgentCanClimb : boolean, --(Whether or not it can climb)
	AgentCanJump : boolean, --(Whether or not it allows jumps)
	Costs : {}, --(What Material or Pathfinding Modifiers should be avoided(High = Avoid, Low = Okay))
	WaypointSpacing : number, --(Spacing between Waypoints)
	PathSettings : {SupportPartialPath : boolean}
}

function module.new(AgentParams: AgentParams)
	local self = setmetatable({
		Path = PFS:CreatePath(AgentParams),
		Visual = {},
		Destroying = false,
	}, Path)

	return self
end

-- Generate a Path from PointA to PointB, Return Route, IsPartialPath
function Path:Generate(PointA : Vector3, PointB : Vector3): (Route?, boolean?)
	local Success, Message = pcall(function()
		self.Path:ComputeAsync(PointA, PointB)
	end)
	if not Success then
		warn(Message)
		return
	end
	
	if self.Destroying ~= false then
		return
	end

	local Route : Route = self.Path:GetWaypoints()

	for i = #Route - 1, 1, -1 do
		local Waypoint = Route[i]
		local NextWaypoint = Route[i + 1]
		local Distance = (Waypoint.Position - NextWaypoint.Position).Magnitude

		if Waypoint.Action ~= JUMP and Distance < 2 then
			table.remove(Route, i)
		end
	end
	return Route, self.Path.Status == PARTIAL
end

local VisualFolder = workspace:FindFirstChild("VisualWaypoints")
if not VisualFolder then
	VisualFolder = Instance.new("Folder")
	VisualFolder.Name = "VisualWaypoints"
	VisualFolder.Parent = workspace
end

local NoobPath = script.Parent

local GREEN = BrickColor.new("Bright green").Color
local YELLOW = BrickColor.new("Bright yellow").Color
local BLUE = BrickColor.new("Bright blue").Color
local RED = BrickColor.new("Bright red").Color

local function CreatePoint(Position : Vector3)
	local Point = Instance.new("Part")
	Point.Color = GREEN
	Point.CastShadow = false
	Point.Material = Enum.Material.Neon
	Point.Size = Vector3.new(0.5, 0.5, 0.5)
	Point.Shape = Enum.PartType.Ball
	Point.CanCollide = false
	Point.CanTouch = false
	Point.CanQuery = false
	Point.Anchored = true
	Point.Position = Position
	Point.Parent = VisualFolder

	return Point
end

local function GraphLine(Position : Vector3, Next : Vector3)
	local Point = CreatePoint(Position)
	local Direction = Next - Position

	local Line = Instance.new("LineHandleAdornment")
	Line.Parent = Point
	Line.Adornee = Point
	Line.CFrame = CFrame.new(Vector3.zero, Direction)
	Line.Length = Direction.Magnitude
	Line.Color3 = BLUE

	Line.Thickness = 3

	return Point, Line
end

-- Visualize the given Route
function Path:Show(Route)
	self:Hide()
	local Visual = self.Visual
	local Length = #Route

	if NoobPath:GetAttribute("GraphPath") then
		for i = 1, Length - 1 do
			local Waypoint = Route[i]
			local Point = GraphLine(Waypoint.Position, Route[i + 1].Position)

			if Waypoint.Action == JUMP then
				Point.Color = YELLOW
			end

			Visual[i] = Point
		end
	else
		for i = 1, Length - 1 do
			local Waypoint = Route[i]
			local Point = CreatePoint(Waypoint.Position)

			if Waypoint.Action == JUMP then
				Point.Color = YELLOW
			end

			Visual[i] = Point
		end
	end

	local Point = CreatePoint(Route[Length].Position)
	Point.Color = RED

	Visual[Length] = Point
end

-- Hide all Path Visualizations
function Path:Hide()
	local Visual = self.Visual
	for i = 1, #Visual do
		Visual[i]:Destroy()
	end
end

-- Estimate time required to travel the given Route based on given Speed
function Path:Estimate(Route, Speed)
	local Estimate : {number} = {}
	
	for i = 1, #Route - 1 do
		local Waypoint = Route[i]
		local NextWaypoint = Route[i + 1]

		local Distance = (Waypoint.Position - NextWaypoint.Position).Magnitude
		local Time = Distance / Speed -- Estimated time
		
		Estimate[i] = Time
	end

	return Estimate
end

-- Get the current status of the Path
function Path:GetStatus() : Enum.PathStatus
	return self.Path.Status
end

-- Destroy the Object
function Path:Destroy()
	self.Destroying = true
	self:Hide()
	self.Path:Destroy()
	table.clear(self)
	setmetatable(self, nil)
	self = nil
end

return module
