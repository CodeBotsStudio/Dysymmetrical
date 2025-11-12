local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Effect = require(ReplicatedStorage.Classes.Effect)
local Utils = require(ReplicatedStorage.Modules.Utils)

local Blindness = Effect:GetDefaultEffect()
Blindness.Name = "Blindness"
Blindness.Description = "Blinds the affected player for a set time. This effect will flash white if the Photosensitive setting is off, and black if it's on."

local DisappearThread

Blindness.ApplyEffect = function(own: Effect.Effect, char: Model, level: number, duration: number)
    if not RunService:IsServer() then
        if DisappearThread then
            task.cancel(DisappearThread)
        end

        local CC: ColorCorrectionEffect = Lighting:FindFirstChild("BlindnessColorCorrection")
        if CC then
            CC:Destroy()
        end

        CC = Instance.new("ColorCorrectionEffect")
        CC.Name = "BlindnessColorCorrection"
        CC.Brightness = Utils:GetPlayerSetting(Players.LocalPlayer, "Accessibility.EpilepsyMode") and 0.99 or -0.24
        CC.Saturation = 1
        CC.Parent = Lighting

        local Q = duration / 4
        DisappearThread = task.delay(Q * 3, function()
            TweenService:Create(CC, TweenInfo.new(Q, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Brightness = 0, Saturation = 0}):Play()
        end)
    end
end

Blindness.RemoveEffect = function(own: Effect.Effect, char: Model)
    if not RunService:IsServer() then
        if DisappearThread then
            task.cancel(DisappearThread)
        end
        
        local CC = Lighting:FindFirstChild("BlindnessColorCorrection")
        if CC then
            CC:Destroy()
        end
    end
end

return Blindness
