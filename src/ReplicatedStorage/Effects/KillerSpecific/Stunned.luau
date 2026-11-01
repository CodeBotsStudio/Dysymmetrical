local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effect = require(ReplicatedStorage.Classes.Effect)
local Types = require(ReplicatedStorage.Classes.Types)

local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil
local PlayerSpeedManager = RunService:IsServer() and require(game:GetService("ServerScriptService").Managers.PlayerManager.PlayerSpeedManager) or nil

return Effect.New({
    Name = "Stunned",
    Description = "Deja al jugador quieto y sin poder usar habilidades durante un tiempo.",
    Duration = 3,
    ShowInGUI = true,
    ApplyEffect = function(_own: Types.Effect, _level: number, char: Model)
        if not RunService:IsServer() then
            return
        end
        PlayerSpeedManager.AddSpeedFactor(Players:GetPlayerFromCharacter(char), "Stunned", 0)
    end,
    RemoveEffect = function(self: Types.Effect, char: Model)
        if not RunService:IsServer() then
            return
        end
        
        CommonFunctions.ApplyEffect({
            TargetHumanoid = char:FindFirstChildWhichIsA("Humanoid"),
            EffectSettings = {
                Name = "SpawnProtection",
                Subfolder = "KillerSpecific",
            },
        })

        PlayerSpeedManager.RemoveSpeedFactor(Players:GetPlayerFromCharacter(char), "Stunned")
    end
})
