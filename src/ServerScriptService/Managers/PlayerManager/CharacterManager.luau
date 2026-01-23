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

--- Loads a player's character directly, as a spectator.
function CharacterManager.LoadDefaultCharacter(Player: Player): Model
    if not Player.Parent then
        return
    end

    Player:LoadCharacterAsync()

    Player.Character:SetAttribute("Role", "Spectator")

    return Player.Character
end

return CharacterManager
