--[[

	@ Name: SmoothShiftLock
	@ Author: rixtys
	@ Version: PlayerModule Pair 0.0.1
	
	@ Desc: Smooth shift lock module that adds smoothness to the Roblox's shift lock
	│ @ for this to work, disable the default Roblox's shift lock
	│ @ game.StarterPlayer.EnableMouseLockOption = false
	│ @ and start the custom shift lock module with
	└ @ SmoothShiftLock:Init()
	
	@ Methods = {
		SmoothShiftLock:Init()
		Initializes the module. (Should be done on client and only once)
		
		SmoothShiftLock:IsEnabled()
		Gets ShiftLock's enabled state
	}

--]]

local SmoothShiftLock = {}
SmoothShiftLock.__index = SmoothShiftLock

--// Context action
-- local CONTEXT_ACTION_NAME = "MouseLockSwitchAction"
-- local MOUSELOCK_ACTION_PRIORITY = Enum.ContextActionPriority.Medium.Value

--// Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- local ContextActionService = game:GetService("ContextActionService")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

--// Requires
local InputManager = require(Players.LocalPlayer.PlayerScripts.InputManager)
local CameraUtils = require(script.Parent:WaitForChild("CameraUtils"))
local Maid = require(script.Parent:WaitForChild("Maid"))

--// Instances
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local RoundInfo = ReplicatedStorage:WaitForChild("RoundInfo")
local RoundStateValue = RoundInfo:WaitForChild("CurrentState")

--// Configuration
local Config = require(script:WaitForChild("Settings"))

--// SmoothShiftLock constructor
function SmoothShiftLock.new()
	local self = setmetatable({}, SmoothShiftLock)
	self._runtimeMaid = Maid.new()
	
	self.isEnabled = false
	self.isMouseLocked = false
	self.mouseLockToggledEvent = Instance.new("BindableEvent")
	self._roundState = RoundStateValue.Value
	self._neck = nil
	self._neckOriginalC0 = nil
	RoundStateValue:GetPropertyChangedSignal("Value"):Connect(function()
		local previous = self._roundState
		self._roundState = RoundStateValue.Value
		if self._roundState == "Lobby" then
			self:_ResetNeck()
		end
		if previous == "Lobby" and self._roundState ~= "Lobby" then
			self:_ResetNeck()
		end
	end)

	--// Check for client setting changes
	GameSettings.Changed:Connect(function(property)
		if property == "ControlMode" or property == "ComputerMovementMode" then
			self:UpdateMouseLockAvailability()
		end
	end)

	--// Check for MouseLock availability changes
	LocalPlayer:GetPropertyChangedSignal("DevEnableMouseLock"):Connect(function()
		self:UpdateMouseLockAvailability()
	end)

	--// Check for ComputerMovementMode changes
	LocalPlayer:GetPropertyChangedSignal("DevComputerMovementMode"):Connect(function()
		self:UpdateMouseLockAvailability()
	end)

	local function OnCharacterAdded(Character)
		self.Character = Character
		self.Humanoid = self.Character:WaitForChild("Humanoid")
		self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")
		self._neck = nil
		self._neckOriginalC0 = nil
	end
	
	if LocalPlayer.Character then
		OnCharacterAdded(LocalPlayer.Character)
	end
	
	LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

	self:UpdateMouseLockAvailability()

	return self
end

-- [[ Functions ]]:

function SmoothShiftLock:_GetNeckMotor()
	if not self.Character then
		return nil
	end
	local existing = self._neck
	if existing and existing.Parent then
		return existing
	end
	local neck = self.Character:FindFirstChild("Neck", true)
	if neck and neck:IsA("Motor6D") then
		self._neck = neck
		return neck
	end
	for _, desc in ipairs(self.Character:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Name == "Neck" then
			self._neck = desc
			return desc
		end
	end
	return nil
end

function SmoothShiftLock:_ResetNeck()
	local neck = self:_GetNeckMotor()
	if neck and self._neckOriginalC0 then
		neck.C0 = self._neckOriginalC0
	end
end

function SmoothShiftLock:_UpdateLobbyNeckRotation()
	if not self.Character or not self.HumanoidRootPart then
		return
	end
	local neck = self:_GetNeckMotor()
	if not neck then
		return
	end
	if not self._neckOriginalC0 then
		self._neckOriginalC0 = neck.C0
	end
	local relativeLook = self.HumanoidRootPart.CFrame:VectorToObjectSpace(Camera.CFrame.LookVector)
	local yaw = math.atan2(-relativeLook.X, -relativeLook.Z)
	local pitch = math.asin(math.clamp(relativeLook.Y, -1, 1))
	yaw = math.clamp(yaw, math.rad(-70), math.rad(70))
	pitch = math.clamp(pitch, math.rad(-35), math.rad(35))
	neck.C0 = self._neckOriginalC0 * CFrame.Angles(pitch, yaw, 0)
end

--// Update MouseLock availability
function SmoothShiftLock:UpdateMouseLockAvailability()
	local DevAllowsMouseLock = LocalPlayer.DevEnableMouseLock
	local DevMovementModeIsScriptable = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
	local UserHasMouseLockModeEnabled = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
	local UserHasClickToMoveEnabled =  GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
	local MouseLockAvailable = DevAllowsMouseLock and UserHasMouseLockModeEnabled and not UserHasClickToMoveEnabled and not DevMovementModeIsScriptable

	if MouseLockAvailable ~= self.isEnabled then
		self:EnableMouseLock(MouseLockAvailable)
	end
end

--// Return bindable toggle event
function SmoothShiftLock:GetBindableToggleEvent()
	return self.mouseLockToggledEvent.Event
end

--// Enable or disable MouseLock
function SmoothShiftLock:EnableMouseLock(Enable)
	if Enable ~= self.isEnabled then
		self.isEnabled = Enable
		
		if self.isEnabled then
			self:BindContextActions()
		else
			self:UnbindContextActions()
			self:ToggleShiftLock(false)
		end
	end
end

--// MouseLock switch
function SmoothShiftLock:DoMouseLockSwitch(name, state, input)
	if state == Enum.UserInputState.Begin then
		self:ToggleShiftLock(not self.isMouseLocked)
		return Enum.ContextActionResult.Sink
	end
	
	return Enum.ContextActionResult.Pass
end

--// Bind keybinds
function SmoothShiftLock:BindContextActions()
	self.ContextActionConnection = InputManager:GetInputAction("Miscellaneous.ShiftLock").Pressed:Connect(function()
		self:DoMouseLockSwitch(nil, Enum.UserInputState.Begin, nil)
	end)
end

--// Unbind keybinds
function SmoothShiftLock:UnbindContextActions()
	if self.ContextActionConnection then
		self.ContextActionConnection:Disconnect()
	end
	-- ContextActionService:UnbindAction(CONTEXT_ACTION_NAME)
end

--// Toggle shift lock
function SmoothShiftLock:ToggleShiftLock(Toggle)
	self.isMouseLocked = Toggle

	if (self.isMouseLocked) then
		CameraUtils.setMouseIconOverride(Config.LOCKED_MOUSE_ICON)
		--// Start
		if (self.isMouseLocked) and self.Character then
			self._runtimeMaid:GiveTask(RunService.RenderStepped:Connect(function(Delta)
				if not self.Humanoid or not self.HumanoidRootPart then return end
				self.Humanoid.AutoRotate = not self.isMouseLocked
				--// Rotate character
				if self.Humanoid.Sit then return end
				if (Config.CHARACTER_SMOOTH_ROTATION) then
					local _, y, _ = Camera.CFrame:ToOrientation()
					self.HumanoidRootPart.CFrame = self.HumanoidRootPart.CFrame:Lerp(CFrame.new(self.HumanoidRootPart.Position) * CFrame.Angles(0, y, 0), Delta * 5 * Config.CHARACTER_ROTATION_SPEED)
				else
					local _, y, _ = Camera.CFrame:ToOrientation()
					self.HumanoidRootPart.CFrame = CFrame.new(self.HumanoidRootPart.Position) * CFrame.Angles(0, y, 0)
				end
			end))
		end
	else
		self._runtimeMaid:Destroy()
		self:_ResetNeck()
		if self.Humanoid then
			self.Humanoid.AutoRotate = not self.isMouseLocked
		end
		
		CameraUtils.restoreMouseIcon()
	end
	
	self.mouseLockToggledEvent:Fire()
end

function SmoothShiftLock:GetIsMouseLocked()
	return self.isMouseLocked
end

return SmoothShiftLock