--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Hitbox = require(ReplicatedStorage.Classes.Hitbox)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Ability = require(ReplicatedStorage.Classes.Ability)
local Utils = require(ReplicatedStorage.Modules.Utils)

local SlashModule = {}

--- Creates a new Slash ability instance. Use this in every killer that you want to have a slash ability in.
function SlashModule.New(Props: Ability?): Ability

	-- Doesn't require you to unintuitively slot in an empty table for it to work at all– someone was confused about this a bit earlier, so I figured a fix was in order.
	Props = Props or {}

	Utils.Type.DeepTableWrite(Props, Ability:CreateAbility({
		Name = "Slash",
		InputName = "Slash",
		Cooldown = 2,
		Duration = 0.54,
		Damage = 20,
		RenderImage = "rbxassetid://11218451110",
		UseSound = "rbxassetid://12222200",
		UseAnimation = "rbxassetid://133504250023139",
		UICorner = true,
		Delay = 0.1,
		HitboxSize = Vector3.new(5, 6, 4.5),
		HitboxOffset = CFrame.new(0, 0, -2.5),
		Behaviour = function(self: Ability.Ability)
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
		end,
		IncreaseDamage = function(self: Ability.Ability, amount: number)
			self.Damage += amount
		end,
	}))

	return Props
end

return SlashModule
