local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)

local GlobalFootstepPlayer = {
    DefaultFootstep = "rbxassetid://78754179999047",
    ManagedCharacters = {},
}

function GlobalFootstepPlayer:Init()
    --setup any instanced characters, present and future
	Utils.Player.ObservePlayers(function(plr: Player)
		Utils.Character.ObserveCharacter(plr, function(newChar: Model)
			GlobalFootstepPlayer._SetupChar(plr, newChar)
		end)
	end)
    --remove any players from the table when they leave to prevent clutter
	Players.PlayerRemoving:Connect(function(plr: Player)
		if GlobalFootstepPlayer.ManagedCharacters[plr.UserId] then
			GlobalFootstepPlayer.ManagedCharacters[plr.UserId] = nil
		end
	end)
end

--- Will play a footstep sound on a player's character's feet.
--- 
--- If applicable, a preset custom footstep will play. This is set through character modules.
function GlobalFootstepPlayer.PlayFootstep(player: Player, Anchor: BasePart)
    --if the character is emoting or being affected by a constraint, halt
	if Anchor:FindFirstChildWhichIsA("Constraint") or Anchor.Parent:GetAttribute("Emoting") then return end
	
    --play le footstep
	Sounds.PlaySound(GlobalFootstepPlayer.ManagedCharacters[player.UserId] or GlobalFootstepPlayer.DefaultFootstep, {
		--add pitch stuff
        --NOTE: might make this customizable later
        MinPitch = 0.9,
		MaxPitch = 1.05,
        --le position right at the character's feet
		Position = Anchor.Position - Vector3.new(0, 2.5, 0),
	})
end

--- INTERNAL FUNCTION: Sets up a character's connections to automatically play footsteps based on animations.
function GlobalFootstepPlayer._SetupChar(player: Player, character: Model)
    --if there is no humanoid, halt
	local Humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not Humanoid then
		return
	end
    --if it doesn't have a root part, halt
	local HRP = Utils.Character.GetRootPart(character)
	if not HRP then
		return
	end

    --NOTE: uncomment this when characters are added properly
    --if the character has a module and custom footsteps, grab those
	-- if character:GetAttribute("Role") ~= "Spectator" then
	-- 	local CharModule = require(Utils.Instance.GetCharacterModule(character:GetAttribute("Role"), character:GetAttribute("CharacterName"), character:GetAttribute("CharacterSkin")))
	-- 	if CharModule.Config.Sounds.Footsteps then
	-- 		GlobalFootstepPlayer.ManagedCharacters[player.UserId] = CharModule.Config.Sounds.Footsteps
	-- 	end
    --if not, roll back to defaults
	-- elseif GlobalFootstepPlayer.ManagedCharacters[player.UserId] then
	-- 	GlobalFootstepPlayer.ManagedCharacters[player.UserId] = nil
	-- end

    --make a track table to not reconnect footsteps every time to a track when it replays
	local ConnectedTracks = {}
    --connect to animation playing to get the markers of any track
	Humanoid:FindFirstChildWhichIsA("Animator").AnimationPlayed:Connect(function(track: AnimationTrack)
		--prevent reconnections
        if table.find(ConnectedTracks, track) then
			return
		end
        --add it to not connect again later
		table.insert(ConnectedTracks, track)

        --get its footstep markers to play a footstep every time they're reached
		track:GetMarkerReachedSignal("Footstep"):Connect(function()
            --if the character isn't grounded or it's anchored, halt
			if Humanoid.FloorMaterial == Enum.Material.Air or HRP.Anchored then
				return
			end
            --play le footstep
			GlobalFootstepPlayer.PlayFootstep(player, HRP)
		end)
	end)
end

return GlobalFootstepPlayer
