--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect.CreateEffect({
    Name = "Spawn Protection",
    Description = "Prevents a killer from being stunned for a set time, generally 12 seconds.",
    Duration = 12,
    ShowInGUI = false,
    ApplyEffect = function(self: Effect.Effect, level: number, char: Model, duration: number)
        local HRP = Utils.Character.GetAliveRootPart(char)
        local UI = HRP:FindFirstChild("StunSpawnProtection")
        if UI then
            UI:FindFirstChildWhichIsA("ParticleEmitter").Enabled = true
        end
    end,
    RemoveEffect = function(self: Effect.Effect, char: Model)
        local HRP = Utils.Character.GetAliveRootPart(char)
        local UI = HRP:FindFirstChild("StunSpawnProtection")
        if UI then
            UI:FindFirstChildWhichIsA("ParticleEmitter").Enabled = false
        end
    end,
})
