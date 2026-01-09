local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        local Player = Players.LocalPlayer
        local Character = Player.Character
        if Character:FindFirstChild("Role").Value == "Killer" then
            return
        end
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

        local LastValue = Humanoid.Health
        Utils.Instance.ObserveProperty(Humanoid, "Health", function(value: number)
            if value >= LastValue or LastValue - value < 10 then
                LastValue = value
                return
            end

            Utils.Player.ShakeCamera(1.56 * (LastValue - value) / 100, 0.4)

            LastValue = value
        end)
    end,
}