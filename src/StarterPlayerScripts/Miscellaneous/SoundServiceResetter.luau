local SoundServiceResetter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Utils = require(ReplicatedStorage.Modules.Utils)

function SoundServiceResetter:Init()
    Utils.Character.ObserveCharacter(game:GetService("Players").LocalPlayer, function(_Character: Model)
        for _, Descendant in SoundService.SoundGroups:GetDescendants() do
            if not Descendant:IsA("SoundGroup") then
                Descendant:Destroy()
            end
        end
    end)
end

return SoundServiceResetter
