--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effect = require(ReplicatedStorage.Classes.Effect)

local PlayerModule: ModuleScript

local Disoriented: Effect.Effect = Effect:GetDefaultEffect()
Disoriented.Name = "Disoriented"
Disoriented.Description = "Inverts the player's controls for the duration of the effect."
Disoriented.Duration = 4.2
Disoriented.ShowInGUI = false

if not RunService:IsServer() then
    PlayerModule = require(Players.LocalPlayer.PlayerScripts.PlayerModule)
end

Disoriented.ApplyEffect = function()
    if not RunService:IsServer() then
        PlayerModule.controls.disoriented = true
    end
end
Disoriented.RemoveEffect = function()
    if not RunService:IsServer() then
        PlayerModule.controls.disoriented = false
    end
end

return Disoriented
