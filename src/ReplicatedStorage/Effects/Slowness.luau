local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect.New({
    Name = "Slowness",
    Description = "Makes the player slower the higher the level.",
    ApplyEffect = function(_own: Types.Effect, level: number)
        if RunService:IsServer() then
            return
        end
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):AddSpeedFactor("SlownessEffect", math.clamp(1 - 0.26 * level, 0, 1))
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):AddFOVFactor("SlownessEffect", math.clamp(1 - 0.07 * level, 0.5, 1))
    end,
    RemoveEffect = function()
        if RunService:IsServer() then
            return
        end
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):RemoveSpeedFactor("SlownessEffect")
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):RemoveFOVFactor("SlownessEffect")
    end,
})
