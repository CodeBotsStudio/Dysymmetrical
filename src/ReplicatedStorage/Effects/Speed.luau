--!nocheck
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

local Speed: Effect.Effect = Effect:GetDefaultEffect()
Speed.Name = "Speed"
Speed.Description = "Makes the player faster the higher the level."

Speed.ApplyEffect = function(_own: Effect.Effect, level: number)
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):AddSpeedFactor("SpeedEffect", 1 + 0.73 * level)
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):AddFOVFactor("SpeedEffect", math.clamp(1 + 0.07 * level, 1, 1.5))
end
Speed.RemoveEffect = function()
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):RemoveSpeedFactor("SpeedEffect")
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):RemoveFOVFactor("SpeedEffect")
end

return Speed
