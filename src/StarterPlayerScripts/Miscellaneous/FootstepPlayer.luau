--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local FootstepPlayer = {
	DefaultSFXID = "rbxassetid://78754179999047",
	ControlledCharacters = {},
}

function FootstepPlayer:PlayFootstep(player: Player, Anchor: BasePart)
	if Anchor:FindFirstChildOfClass("LinearVelocity") or Anchor.Parent:GetAttribute("Emoting") then return end
	
	Sounds.PlaySound(self.ControlledCharacters[player.UserId] or self.DefaultSFXID, {
		MinPitch = 0.9,
		MaxPitch = 1.05,
	}, {
		Position = Anchor.Position - Vector3.new(0, 3, 0),
	})
end

function FootstepPlayer:_SetupChar(player: Player, character: Model)
	local HRP = Utils.Instance.FindFirstChild(character, "HumanoidRootPart")
	if not HRP then
		return
	end
	local Humanoid = Utils.Instance.FindFirstChild(character, "Humanoid")
	if not Humanoid then
		return
	end

	if character:GetAttribute("CharacterName") then
		local CharModule = require(Utils.Instance.GetCharacterModule(character.Role.Value, character:GetAttribute("CharacterName"), character:GetAttribute("CharacterSkinName")))
		if CharModule.Config.Sounds.FootstepSounds then
			self.ControlledCharacters[player.UserId] = CharModule.Config.Sounds.FootstepSounds
		end
	end

	Utils.Instance.FindFirstChild(Humanoid, "Animator").AnimationPlayed:Connect(function(track: AnimationTrack)
		track:GetMarkerReachedSignal("Footstep"):Connect(function()
			if (character.PlayerAttributes.Sprinting and character.PlayerAttributes.Sprinting.Value) or Humanoid.FloorMaterial == Enum.Material.Air or HRP.Anchored then
				return
			end
			self:PlayFootstep(player, HRP)
		end)
	end)
end

function FootstepPlayer:Init()
	Utils.Player.ObservePlayers(function(plr: Player)
		Utils.Character.ObserveCharacter(plr, function(newChar: Model)
			self:_SetupChar(plr, newChar)
		end)
	end)
	Players.PlayerRemoving:Connect(function(plr: Player)
		if self.ControlledCharacters[plr.UserId] then
			self.ControlledCharacters[plr.UserId] = nil
		end
	end)
end

return FootstepPlayer
