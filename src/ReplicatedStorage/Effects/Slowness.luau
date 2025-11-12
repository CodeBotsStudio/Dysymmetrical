--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effect = require(ReplicatedStorage.Classes.Effect)

local Slowness: Effect.Effect = Effect:GetDefaultEffect()
Slowness.Name = "Slowness"
Slowness.Description = "Makes the player slower the higher the level."

Slowness.ApplyEffect = function(_own: Effect.Effect, level: number)
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):AddSpeedFactor("SlownessEffect", math.clamp(1 - 0.14 * level, 0, 1))
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):AddFOVFactor("SlownessEffect", math.clamp(1 - 0.07 * level, 0.5, 1))
end
Slowness.RemoveEffect = function()
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):RemoveSpeedFactor("SlownessEffect")
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):RemoveFOVFactor("SlownessEffect")
end

return Slowness
