--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        local Player = Players.LocalPlayer
        local Character = Player.Character
        if Utils:FindFirstChild(Character, "Role").Value == "Killer" then
            return
        end
        local Humanoid = Utils:FindFirstChild(Character, "Humanoid")

        local LastValue = Humanoid.Health
        Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if Humanoid.Health >= LastValue or LastValue - Humanoid.Health < 10 then
                LastValue = Humanoid.Health
                return
            end

            Utils:ShakeCamera(1.56 * (LastValue - Humanoid.Health) / 100, 0.4)

            LastValue = Humanoid.Health
        end)
    end,
}