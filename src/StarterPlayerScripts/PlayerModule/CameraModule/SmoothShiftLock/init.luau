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
local CONTEXT_ACTION_NAME = "MouseLockSwitchAction"
local MOUSELOCK_ACTION_PRIORITY = Enum.ContextActionPriority.Medium.Value

--// Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings

--// Requires
local CameraUtils = require(script.Parent:WaitForChild("CameraUtils"))
local Maid = require(script.Parent:WaitForChild("Maid"))

--// Instances
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Configuration
local Config = require(script:WaitForChild("Settings"))

--// SmoothShiftLock constructor
function SmoothShiftLock.new()
	local self = setmetatable({}, SmoothShiftLock)
	self._runtimeMaid = Maid.new()
	
	self.isEnabled = false
	self.isMouseLocked = false
	self.mouseLockToggledEvent = Instance.new("BindableEvent")
	
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

	local function OnCharacterAdded(Character: Model)
		self.Character = Character
		self.Humanoid = self.Character:WaitForChild("Humanoid")
		self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")
	end
	
	if LocalPlayer.Character then
		OnCharacterAdded(LocalPlayer.Character)
	end
	
	LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

	self:UpdateMouseLockAvailability()

	return self
end

-- [[ Functions ]]:

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
function SmoothShiftLock:EnableMouseLock(Enable: boolean)
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
	ContextActionService:BindActionAtPriority(CONTEXT_ACTION_NAME, function(name, state, input)
		return self:DoMouseLockSwitch(name, state, input)
	end, false, MOUSELOCK_ACTION_PRIORITY, unpack(Config.SHIFT_LOCK_KEYBINDS))
end

-- function SmoothShiftLock:BindContextActions()
-- 	self.ContextActionConnection = InputManager:GetInputAction("Miscellaneous.ShiftLock").Pressed:Connect(function()
-- 		self:DoMouseLockSwitch(nil, Enum.UserInputState.Begin, nil)
-- 	end)
-- end

--// Unbind keybinds
function SmoothShiftLock:UnbindContextActions()
	if self.ContextActionConnection then
		self.ContextActionConnection:Disconnect()
	end
	-- ContextActionService:UnbindAction(CONTEXT_ACTION_NAME)
end

--// Toggle shift lock
function SmoothShiftLock:ToggleShiftLock(Toggle: boolean)
	self.isMouseLocked = Toggle

	if (self.isMouseLocked) then
		CameraUtils.setMouseIconOverride(Config.LOCKED_MOUSE_ICON)
		--// Start
		if (self.isMouseLocked) and self.Character then
			self._runtimeMaid:GiveTask(RunService.RenderStepped:Connect(function(Delta: number)
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