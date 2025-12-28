--!nocheck

local Sprinting = {
	AttemptingSprint = false,
	PressingSprintWhileRecovering = false,
	Recovering = false,
	Exhausted = false,
	Stamina = 100,
	TweenSpeed = true,
	SpeedApplied = true,
	SprintMultiplier = 2.66666,
	CanGainStamina = true,
	Janitor = nil,
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local InputManager = require(PlayerScripts.InputManager)

local playersFolder = workspace.Players

local FootstepPlayer = require(LocalPlayer.PlayerScripts.Miscellaneous.FootstepPlayer)

local FactorName = "Sprint"

local RecoverDelay = 0.75
local RecoverExhaustionDelay = 2

local FOVFactorName = "Sprint"
local SprintFOVMultiplier = 1.2

local MovementAnimSpeedDiv = 30

function Sprinting:ReloadAnimation(animId: string)
	if self.FootstepConnection then
		self.FootstepConnection:Disconnect()
	end
	self.SprintTrack = Utils.Character.LoadAnimationFromID(self.Char, animId)
	self.FootstepConnection = self.SprintTrack:GetMarkerReachedSignal("Footstep"):Connect(function()
		FootstepPlayer.PlayFootstep(LocalPlayer, self.HRP)
	end)
end

function Sprinting:_Stop(StopExhausted: boolean)
	self.FOVManager:RemoveFOVFactor(FOVFactorName)
	self.Recovering = true

	if self.SprintTrack and self.SprintTrack.IsPlaying then
		self.SprintTrack:Stop(self.AnimationTransitionTime.Value)
	end

	if StopExhausted then
		self.Stamina = 0
		self.PressingSprintWhileRecovering = true
		self.Exhausted = true
		task.delay(RecoverExhaustionDelay, function()
			self.Recovering = false
			self.Exhausted = false
		end)
	else
		self.RecoveryThread = task.delay(RecoverDelay, function()
			self.Recovering = false
		end)
	end
end

function Sprinting:_DrainStamina(delta: number)
	self.Stamina -= self.StaminaDrainRate.Value * delta
end

function Sprinting:_GainStaminaLegally(delta: number)
	if not self.Recovering and not self.Exhausted and self.Stamina <= self.MaxStamina.Value then
		self.Stamina = math.clamp(self.Stamina + self.StaminaRegenRate.Value * delta, 0, self.MaxStamina.Value)
	end
end

function Sprinting:Init()
	while not (InputManager.DefaultActions and InputManager.DefaultActions.Sprint) do
		task.wait()
	end
	
	local char = LocalPlayer.Character
	local HumanoidRootPart: BasePart = Utils.Instance.FindFirstChild(char, "HumanoidRootPart")
	self.HRP = HumanoidRootPart
	local Humanoid = Utils.Instance.FindFirstChild(char, "Humanoid")

	self.Char = char

	self.Janitor = Janitor.new()
	self.Janitor:LinkToInstance(char)

	self.AnimationTransitionTime = Utils.Instance.FindFirstChild(char, "PlayerAttributes.AnimationTransitionTime")

	local PlayerAttributeScripts = char.PlayerAttributeScripts
	local SpeedManager = require(PlayerAttributeScripts.SpeedManager)
	local FOVManager = require(PlayerAttributeScripts.FOVManager)
	self.FOVManager = FOVManager

	local Role = Utils.Instance.FindFirstChild(char, "Role")
	
	local StaminaValue = char.PlayerAttributes.Stamina
	self.MaxStamina = char.PlayerAttributes.MaxStamina
	self.StaminaRegenRate = char.PlayerAttributes.StaminaGain
	self.StaminaDrainRate = char.PlayerAttributes.StaminaDrain
	
	local SprintValue = char.PlayerAttributes.Sprinting

	SpeedManager:AddSpeedFactor(FactorName, 1)

	self.Janitor:Add(InputManager.DefaultActions.Sprint.Pressed:Connect(function()
		self.AttemptingSprint = true
		if self.Exhausted then
			self.PressingSprintWhileRecovering = true
		end
	end), "Disconnect")

	self.Janitor:Add(InputManager.DefaultActions.Sprint.Released:Connect(function()
		self.AttemptingSprint = false
		self.PressingSprintWhileRecovering = false
	end), "Disconnect")

	self.Janitor:Add(RunService.PreSimulation:Connect(function(delta: number)
		local DirectionOfMovement = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.AssemblyLinearVelocity)
		local HumanoidDirectionOfMovement = Vector3.new(Humanoid.MoveDirection.X, 0, Humanoid.MoveDirection.Z)
		local Moving = not HumanoidRootPart.Anchored and Humanoid.WalkSpeed > 0 and DirectionOfMovement.Magnitude > 0.1 and HumanoidDirectionOfMovement.Magnitude > 0

		if Moving and self.AttemptingSprint and not self.Exhausted and not self.PressingSprintWhileRecovering and SpeedManager.LastMultiplier >= 0.65 and SpeedManager.CanSprint then

			self.SpeedApplied = true

			if not FOVManager.FOVFactors[FOVFactorName] then
				FOVManager:AddFOVFactor(FOVFactorName, SprintFOVMultiplier)
			end

			if self.SprintTrack and not self.SprintTrack.IsPlaying then
				self.SprintTrack:Play(self.AnimationTransitionTime.Value)
			end

			if self.RecoveryThread then
                task.cancel(self.RecoveryThread)
            end

			--killer's stamina should only deplete when other survivors are close
			--using `playersFolder` is fine since spectators will be around 1000 studs away in the lobby
			if Role.Value == "Killer" then
				local found = false
				for _, otherChar in playersFolder:GetChildren() do
					if otherChar ~= char then
						local charHRP = otherChar:FindFirstChild("HumanoidRootPart")
						if not charHRP then continue end

						if (charHRP.Position - HumanoidRootPart.Position).Magnitude <= 110 then
							found = true
							break
						end
					end
				end
				if found then
					self:_DrainStamina(delta)
				elseif self.CanGainStamina then
					self:_GainStaminaLegally(delta)
				end
			else
				self:_DrainStamina(delta)
			end

			if self.Stamina <= 0 then
				self:_Stop(true)
			end

		else

			if self.SpeedApplied then
				self:_Stop(false)
				self.SpeedApplied = false
			end

			if self.CanGainStamina then
				self:_GainStaminaLegally(delta)
			end

		end

		if self.TweenSpeed then
			local ValueToTweenTo = self.SpeedApplied and self.SprintMultiplier or 1
			
			SpeedManager.SpeedFactors[FactorName] = Utils.Math.Lerp(SpeedManager.SpeedFactors[FactorName], ValueToTweenTo, delta * 5.5)
		else
			SpeedManager.SpeedFactors[FactorName] = self.SpeedApplied and self.SprintMultiplier or 1
		end

		if StaminaValue.Value ~= self.Stamina then
			StaminaValue.Value = self.Stamina
		end

		if SprintValue.Value ~= self.SpeedApplied then
			SprintValue.Value = self.SpeedApplied
			Network:FireServerConnection("SprintValueToggle", "REMOTE_EVENT", self.SpeedApplied)
		end

		--backpedaling
		if self.SprintTrack then
			DirectionOfMovement = Vector3.new(DirectionOfMovement.X / Humanoid.WalkSpeed, 0, DirectionOfMovement.Z / Humanoid.WalkSpeed)
			local AnimSpeed = Humanoid.WalkSpeed / MovementAnimSpeedDiv
			if DirectionOfMovement.Z > 0.1 then
				self.SprintTrack:AdjustSpeed(-AnimSpeed)
			else
				self.SprintTrack:AdjustSpeed(AnimSpeed)
			end
		end
	end))

	self.Janitor:Add(function()
		if self.FootstepConnection then
			self.FootstepConnection:Disconnect()
		end
		if self.RecoveryThread then
			task.cancel(self.RecoveryThread)
		end
	end, true)
end

return Sprinting
