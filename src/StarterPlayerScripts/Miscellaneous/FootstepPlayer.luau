--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local FootstepPlayer = {
	DefaultSFXID = "rbxassetid://78754179999047",
	ControlledCharacters = {},
}

function FootstepPlayer.PlayFootstep(player: Player, Anchor: BasePart)
	if Anchor:FindFirstChildWhichIsA("LinearVelocity") or Anchor.Parent:GetAttribute("Emoting") then return end
	
	Sounds.PlaySound(FootstepPlayer.ControlledCharacters[player.UserId] or FootstepPlayer.DefaultSFXID, {
		MinPitch = 0.9,
		MaxPitch = 1.05,
		Position = Anchor.Position - Vector3.new(0, 3, 0),
	})
end

function FootstepPlayer._SetupChar(player: Player, character: Model)
	local Humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not Humanoid then
		return
	end
	local HRP = Utils.Character.GetRootPart(character)
	if not HRP then
		return
	end

	if character:GetAttribute("CharacterName") then
		local CharModule = require(Utils.Instance.GetCharacterModule(character.Role.Value, character:GetAttribute("CharacterName"), character:GetAttribute("CharacterSkinName")))
		if CharModule.Config.Sounds.FootstepSounds then
			FootstepPlayer.ControlledCharacters[player.UserId] = CharModule.Config.Sounds.FootstepSounds
		end
	end

	Humanoid:FindFirstChildWhichIsA("Animator").AnimationPlayed:Connect(function(track: AnimationTrack)
		track:GetMarkerReachedSignal("Footstep"):Connect(function()
			if Humanoid.FloorMaterial == Enum.Material.Air or HRP.Anchored then
				return
			end
			FootstepPlayer.PlayFootstep(player, HRP)
		end)
	end)
end

function FootstepPlayer:Init()
	Utils.Player.ObservePlayers(function(plr: Player)
		Utils.Character.ObserveCharacter(plr, function(newChar: Model)
			FootstepPlayer._SetupChar(plr, newChar)
		end)
	end)
	Players.PlayerRemoving:Connect(function(plr: Player)
		if FootstepPlayer.ControlledCharacters[plr.UserId] then
			FootstepPlayer.ControlledCharacters[plr.UserId] = nil
		end
	end)
end

return FootstepPlayer
