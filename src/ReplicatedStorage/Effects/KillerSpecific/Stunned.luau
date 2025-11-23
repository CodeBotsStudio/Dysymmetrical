--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effect = require(ReplicatedStorage.Classes.Effect)

local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil

return Effect:CreateEffect({
    Name = "Stunned",
    Description = "Keeps the player still and unable to use their abilities for a specific amount of time.",
    Duration = 3,
    -- ShowInGUI = false, -- (true because of suggestions from Quinn)
    ApplyEffect = function()
        if RunService:IsServer() then
            return
        end
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):AddSpeedFactor("Stunned", 0)
    end,
    RemoveEffect = function(self: Effect.Effect, char: Model)
        if RunService:IsServer() then
            CommonFunctions:ApplyEffect(char:FindFirstChild("Humanoid"), "SpawnProtection", nil, nil, "KillerSpecific")

            return
        end
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):RemoveSpeedFactor("Stunned")
    end
})
