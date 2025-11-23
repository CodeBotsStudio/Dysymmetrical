--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effect = require(ReplicatedStorage.Classes.Effect)

local PlayerModule = not RunService:IsServer() and require(Players.LocalPlayer.PlayerScripts.PlayerModule) or nil

return Effect:CreateEffect({
    Name = "Disoriented",
    Description = "Inverts the player's contorls for the duration of the effect.",
    Duration = 4.2,
    ShowInGUI = false,
    ApplyEffect = function()
        if not RunService:IsServer() then
            PlayerModule.controls.disoriented = true
        end
    end,
    RemoveEffect = function()
        if not RunService:IsServer() then
            PlayerModule.controls.disoriented = false
        end
    end,
})
