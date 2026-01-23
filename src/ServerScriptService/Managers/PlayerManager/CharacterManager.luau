local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

--- Manages character instance filling (e.g. assigning the `Role` attribute or creating the hitboxes) and player rig loading.
local CharacterManager = {
    DefaultAttributes = {
        Sprinting = false,
        AnimationTransitionTime = 0.1,
        Role = "Spectator",
    },
}

function CharacterManager:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model)
            require(Character:FindFirstChild("Initter")):Init(Character)
        end)
    end)
end

--- Sets up any missing attributes from a character.
function CharacterManager._SetupDefaultAttributes(Character: Model)
    for Name, Value in CharacterManager.DefaultAttributes do
        if Character:GetAttribute(Name) ~= nil then
            continue
        end

        Character:SetAttribute(Name, Value)
    end
end

return CharacterManager
