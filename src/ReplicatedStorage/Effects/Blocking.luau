--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effect = require(ReplicatedStorage.Classes.Effect)

local Blocking: Effect.Effect = Effect:GetDefaultEffect()
Blocking.Name = "Blocking"
Blocking.Description = "Not really an effect, but just used to check if the player is blocking (character-dependant)."
Blocking.Duration = 1
Blocking.ShowInGUI = false
Blocking.ApplyEffect = function()
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):AddSpeedFactor("Blocking", 0.3)
end
Blocking.RemoveEffect = function()
    if RunService:IsServer() then
        return
    end
    require(Players.LocalPlayer.Character.PlayerAttributeScripts.SpeedManager):RemoveSpeedFactor("Blocking")
end
Blocking.Attacks = {
    "Slash Attack",
}

return Blocking
