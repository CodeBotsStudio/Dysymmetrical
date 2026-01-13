local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)
local PlayerSpeedManager = RunService:IsServer() and require(game:GetService("ServerScriptService").Managers.PlayerManager.PlayerSpeedManager) or nil

return Effect.New({
    Name = "Slowness",
    Description = "Makes the player slower the higher the level.",
    ApplyEffect = function(_own: Types.Effect, level: number, char: Model)
        if RunService:IsServer() then
            PlayerSpeedManager.AddSpeedFactor(Players:GetPlayerFromCharacter(char), "SlownessEffect", 1 - 0.26 * level)
            return
        end
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):AddFOVFactor("SlownessEffect", math.clamp(1 - 0.07 * level, 0, 1))
    end,
    RemoveEffect = function(_own: Types.Effect, char: Model)
        if RunService:IsServer() then
            PlayerSpeedManager.RemoveSpeedFactor(Players:GetPlayerFromCharacter(char), "SlownessEffect")
            return
        end
        require(Players.LocalPlayer.Character.PlayerAttributeScripts.FOVManager):RemoveFOVFactor("SlownessEffect")
    end,
})
