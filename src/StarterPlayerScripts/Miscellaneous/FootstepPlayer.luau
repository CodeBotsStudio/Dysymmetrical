--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local FootstepPlayer = {
	SFXID = "rbxassetid://78754179999047"
}

function FootstepPlayer:PlayFootstep(Anchor: BasePart)
	if Anchor:FindFirstChildOfClass("BodyVelocity") or Anchor.Parent:GetAttribute("Emoting") then return end
	Sounds:PlaySound(FootstepPlayer.SFXID, {
		MinPitch = 0.9,
		MaxPitch = 1.05,
	}, {
		Position = Anchor.Position - Vector3.new(0, 3, 0),
	})
end

function FootstepPlayer:_SetupChar(character: Model)
	local HRP = Utils:FindFirstChild(character, "HumanoidRootPart")
	if not HRP then
		return
	end
	local Humanoid = Utils:FindFirstChild(character, "Humanoid")
	if not Humanoid then
		return
	end
	Utils:FindFirstChild(Humanoid, "Animator").AnimationPlayed:Connect(function(track: AnimationTrack)
		track:GetMarkerReachedSignal("Footstep"):Connect(function()
			if (character.PlayerAttributes.Sprinting and character.PlayerAttributes.Sprinting.Value) or Humanoid.FloorMaterial == Enum.Material.Air or HRP.Anchored then
				return
			end
			FootstepPlayer:PlayFootstep(HRP)
		end)
	end)
end

function FootstepPlayer:Init()
	for _, i in Players:GetPlayers() do
		if i.Character then
			FootstepPlayer:_SetupChar(i.Character)
		end

		i.CharacterAdded:Connect(function(newChar: Model)
			FootstepPlayer:_SetupChar(newChar)
		end)
	end

	Players.PlayerAdded:Connect(function(plr: Player)
		plr.CharacterAdded:Connect(function(newChar: Model)
			FootstepPlayer:_SetupChar(newChar)
		end)
	end)
end

return FootstepPlayer
