local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

--- Manages character instance filling (e.g. assigning the `Role` attribute or creating the hitboxes) and player rig loading.
local CharacterManager = {}

function CharacterManager:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model)

        end)
    end)
end

function CharacterManager.LoadCharacter(Player: Player)
    
end

return CharacterManager
