return {
    Init = function(_self)
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local Utils = require(ReplicatedStorage.Modules.Utils)
        local Sounds = require(ReplicatedStorage.Modules.Sounds)

        local Character = Players.LocalPlayer.Character

        local function ToggleTheme(role: string)
            if role == "Spectator" then
                Sounds:PlayTheme("rbxassetid://75034945737494", {Priority = 1, Volume = 0.2})
            else
                Sounds:StopTheme("rbxassetid://75034945737494")
            end
        end

        local Role = Utils:FindFirstChild(Character, "Role")
        ToggleTheme(Role.Value)
        Role.Changed:Connect(function(Value: string)
            ToggleTheme(Value)
        end)
    end
}