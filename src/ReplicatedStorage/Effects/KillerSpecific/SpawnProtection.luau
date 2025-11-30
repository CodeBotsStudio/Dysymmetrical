--!nocheck

local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect.CreateEffect({
    Name = "Spawn Protection",
    Description = "Prevents a killer from being stunned for a set time, generally 12 seconds.",
    Duration = 12,
    ShowInGUI = false,
    ApplyEffect = function(self: Effect.Effect, level: number, char: Model, duration: number)
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local UI = HRP:FindFirstChild("StunSpawnProtection")
        if UI then
            UI:FindFirstChildOfClass("ParticleEmitter").Enabled = true
        end
    end,
    RemoveEffect = function(self: Effect.Effect, char: Model)
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local UI = HRP:FindFirstChild("StunSpawnProtection")
        if UI then
            UI:FindFirstChildOfClass("ParticleEmitter").Enabled = false
        end
    end,
})
