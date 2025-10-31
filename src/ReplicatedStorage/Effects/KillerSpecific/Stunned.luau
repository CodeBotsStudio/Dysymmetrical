--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Effect = require(ReplicatedStorage.Classes.Effect)

local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil

local Stunned: Effect.Effect = Effect:GetDefaultEffect()

Stunned.Name = "Stunned"
Stunned.Description = "Keeps the player still and unable to use their abilities for a specific amount of time."
-- Stunned.ShowInGUI = false (true because of suggestions from Quinn)
Stunned.Duration = 3

Stunned.ApplyEffect = function()
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):AddSpeedFactor("Stunned", 0)
end

Stunned.RemoveEffect = function(self: Effect.Effect, char: Model)
    if RunService:IsServer() then
        CommonFunctions:ApplyEffect(char:FindFirstChild("Humanoid"), "SpawnProtection", nil, nil, "KillerSpecific")

        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):RemoveSpeedFactor("Stunned")
end

return Stunned
