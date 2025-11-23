local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Network:SetConnection("KilledPlayer", "REMOTE_EVENT", function()
            local FX = Instance.new("ColorCorrectionEffect")
            FX.Name = "KillFX"
            
            local Epilepsy = Utils:GetPlayerSetting(Players.LocalPlayer, "Accessibility")

            FX.TintColor = Epilepsy and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 20, 20)
            FX.Contrast = Epilepsy and 0.5 or 2

            FX.Parent = Lighting

            TweenService:Create(FX, TweenInfo.new(1), {
                Contrast = 0,
                TintColor = Color3.fromRGB(255, 255, 255),
            }):Play()
            Debris:AddItem(FX, 1)
        end)
    end,
}