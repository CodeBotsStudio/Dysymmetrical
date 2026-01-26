local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        local Camera = workspace.CurrentCamera

        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(Character: Model)
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
            if not Humanoid then
                return
            end

            Camera.CameraSubject = Humanoid
        end)
    end,
}