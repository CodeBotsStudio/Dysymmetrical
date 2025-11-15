--!nocheck

local TweenService = game:GetService("TweenService")
local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect:CreateEffect({
    Name = "Spawn Protection",
    Description = "Prevents a killer from being stunned for a set time, generally 12 seconds.",
    Duration = 12,
    ShowInGUI = false,
    ApplyEffect = function(self: Effect.Effect, level: number, char: Model, duration: number)
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local UI = HRP:FindFirstChild("StunSpawnProtection")
        if UI then
            local Label = UI:FindFirstChildOfClass("ImageLabel")
            TweenService:Create(Label, TweenInfo.new(1), {ImageTransparency = 0.5}):Play()
        end
    end,
    RemoveEffect = function(self: Effect.Effect, char: Model)
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local UI = HRP:FindFirstChild("StunSpawnProtection")
        if UI then
            local Label = UI:FindFirstChildOfClass("ImageLabel")
            TweenService:Create(Label, TweenInfo.new(1), {ImageTransparency = 1}):Play()
        end
    end,
})
