local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function()
            if Lighting:FindFirstChild("HealthDesat") then
                Lighting.HealthDesat:Destroy()
            end
        end)
    end,
}