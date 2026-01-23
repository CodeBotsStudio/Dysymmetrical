local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

return {
    Init = function(_)
        --core stuff
        local Character = Players.LocalPlayer.Character
        
        local FOVManager = require(Character.PlayerAttributeManagers.FOVManager)
        local InputManager = require(Players.LocalPlayer.PlayerScripts.InputManager)

        --janitor to prevent mem leaks
        local JanitorInstance = Janitor.new()
        JanitorInstance:LinkToInstance(Character)

        local function Reload(value: boolean)
            --if sprinting, add the factor
            if value then
                if not FOVManager.Factors.Sprint then
                    FOVManager:AddFactor("Sprint", 1.2)
                end

                return
            end

            --if not, remove it
            if FOVManager.Factors.Sprint then
                FOVManager:RemoveFactor("Sprint")
            end
        end

        --connecting
        Utils.Instance.ObserveAttribute(Character, "Sprinting", Reload)

        --key press connections
        local Key = InputManager:GetInputAction("Default.Sprint")
        JanitorInstance:Add(Key.Pressed:Connect(function()
            Network:FireServerConnection("ChangeSprintState", "REMOTE_EVENT", true)
        end))
        JanitorInstance:Add(Key.Released:Connect(function()
            Network:FireServerConnection("ChangeSprintState", "REMOTE_EVENT", false)
        end))
    end,
}
