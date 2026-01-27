local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local PlayerRespawnManager = require(script.PlayerRespawnManager)
local Utils = require(ReplicatedStorage.Modules.Utils)

local PlayerManager = {}

function PlayerManager:Init()
    Network:SetConnection("AddLoadedPlayer", "REMOTE_EVENT", PlayerManager._OnPlayerLoaded)

    Utils.Player.ObservePlayers(function(Player: Player)
        PlayerRespawnManager.LoadCharacter(Player)
    end)
end

function PlayerManager._OnPlayerLoaded(Player: Player)
    --prevent remote spam
    if ReplicatedStorage.LoadedPlayers:FindFirstChild(Player.Name) then
        return
    end

    task.wait(3)

    if not Player then
        return
    end

    local Value = Instance.new("ObjectValue")
    Value.Name = Player.Name
    Value.Value = Player
    Value.Parent = ReplicatedStorage.LoadedPlayers

    Utils.PlayerData.GetSpecificObject(Player, "Misc.LastSeenLog").Value = game.PlaceVersion
end

return PlayerManager
