local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local LocalPlayer = Players.LocalPlayer

local Images = {
    Victim = {
        Killer = {
            "rbxassetid://125952385779817",
        },
        Survivor = {
            "rbxassetid://125952385779817",
        },
    },
    Source = {
        Killer = {
            "rbxassetid://122348374983136",
        },
        Survivor = {
            "rbxassetid://122348374983136",
        },
    },
}

local SoundsTable = {
    Victim = {
        Killer = {
            "rbxassetid://7188420724",
        },
        Survivor = {
            "rbxassetid://7188420724",
        },
    },
    Source = {
        Killer = {
            "rbxassetid://7188420724",
        },
        Survivor = {
            "rbxassetid://7188420724",
        },
    },
}

return function()
    Utils:PreloadAssets({Images, SoundsTable})

    local ImagePreset = Utils:FindFirstChild(script, "ImageLabel")

    Network:SetConnection("ShowJokeSettingImage", "REMOTE_EVENT", function(isVictim: boolean, role: string)
        if not role then
            return
        end

        local UsedImageTable = if isVictim then Images.Victim else Images.Source
        UsedImageTable = UsedImageTable[role] or UsedImageTable.Survivor

        local UsedSoundTable = if isVictim then SoundsTable.Victim else SoundsTable.Source
        UsedSoundTable = UsedSoundTable[role] or UsedSoundTable.Survivor
        
        local Image = ImagePreset:Clone()
        Image.Image = UsedImageTable[math.random(1, #UsedImageTable)]
        Image.Parent = LocalPlayer.PlayerGui.TemporaryUI

        TweenService:Create(Image, TweenInfo.new(1.2), {
            ImageTransparency = 1
        }):Play()
        Sounds:PlaySound(UsedSoundTable)

        Debris:AddItem(Image, 1.5)
    end)
end