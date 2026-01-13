local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local PlayerStreamingManager = {}

function PlayerStreamingManager:Init()
    if not workspace.StreamingEnabled then
        return
    end

    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, PlayerStreamingManager.OnCharacterAdded)
    end)
end

function PlayerStreamingManager.OnCharacterAdded(Character: Model)
    for _, Player: Player in Players:GetPlayers() do
        Player:AddReplicationFocus(Utils.Character.GetRootPart(Character))
    end
end

return PlayerStreamingManager
