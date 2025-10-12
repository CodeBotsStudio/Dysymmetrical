--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Hitbox = require(ReplicatedStorage.Classes.Hitbox)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Ability = require(ReplicatedStorage.Classes.Ability)

local SlashModule = {}

--- Creates a new Slash ability instance. Use this in every killer that you want to have a slash ability in.
function SlashModule.New()
	local Slash = Ability:GetDefaultAbilitySettings()
	Slash.Name = "Slash"
	Slash.InputName = "Slash"
	Slash.Cooldown = 2
	Slash.Duration = 0.54
	Slash.Damage = 20
	Slash.RenderImage = "rbxassetid://11218451110"
	Slash.UseSound = "rbxassetid://12222200"
	Slash.UseAnimation = "rbxassetid://133504250023139"
	Slash.UICorner = true
	Slash.Delay = 0.1
	Slash.HitboxSize = Vector3.new(5, 6, 4.5)
	Slash.HitboxOffset = CFrame.new(0, 0, -2.5)

	function Slash:Behaviour()
		if RunService:IsServer() then
			Sounds:PlaySound(self.UseSound, {Parent = self.OwnerProperties.HRP})
			task.delay(self.Delay, function()
				Hitbox:New(self.Owner, {
					CFrameOffset = self.HitboxOffset,
					Size = self.HitboxSize,
					Time = self.Duration,
					Damage = self.Damage,
					Reason = "Slash Attack",
					ExecuteOnKill = true,
				})
			end)
		else
			self.OwnerProperties.TurnToMoveDirection:AddHeadPreventionFactor("Slash")
			table.insert(self.Connections, task.delay(self.UseAnimationTrack.Length - (1/20 * 2), function()
				self.OwnerProperties.TurnToMoveDirection:RemoveHeadPreventionFactor("Slash")
			end))
		end
	end

	function Slash:IncreaseDamage(amount: number)
		self.Damage += amount
	end

	return Slash
end

return SlashModule
