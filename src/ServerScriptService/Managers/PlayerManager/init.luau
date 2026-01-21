local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local PlayerManager = {}

function PlayerManager:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        
    end)
end

return PlayerManager
