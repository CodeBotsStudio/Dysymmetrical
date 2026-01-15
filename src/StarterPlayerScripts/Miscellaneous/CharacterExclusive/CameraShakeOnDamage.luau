local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(Character: Model)
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
        end)
    end,
}