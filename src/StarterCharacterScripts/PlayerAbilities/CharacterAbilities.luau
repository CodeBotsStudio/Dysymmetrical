local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local CharacterAbilities = {
    CharacterModule = {}, --this is here as a utility local for possible usage
    Abilities = {},
}

function CharacterAbilities:Init()
    local janitorInstance = Janitor.new()
    janitorInstance:LinkToInstance(game:GetService("Players").LocalPlayer.Character)
    janitorInstance:Add(function()
        table.clear(CharacterAbilities.Abilities)
    end, true)
end

return CharacterAbilities
