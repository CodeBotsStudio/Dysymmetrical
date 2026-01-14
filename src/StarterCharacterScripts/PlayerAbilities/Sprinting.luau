local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

return {
    Init = function(_)
        local Character = Players.LocalPlayer.Character
        local Sprinting = Character:FindFirstChild("PlayerAttributes"):FindFirstChild("Sprinting")

        local FOVManager = require(Character.PlayerAttributeScripts.FOVManager)
        local InputManager = require(Players.LocalPlayer.PlayerScripts.InputManager)

        local JanitorInstance = Janitor.new()
        JanitorInstance:LinkToInstance(Character)

        local function Reload(value: boolean)
            if value then
                if not FOVManager.FOVFactors["Sprint"] then
                    FOVManager:AddFOVFactor("Sprint", 1.2)
                end
                return
            end

            if FOVManager.FOVFactors["Sprint"] then
                FOVManager:RemoveFOVFactor("Sprint")
            end
        end

        Utils.Instance.ObserveProperty(Sprinting, "Value", Reload)
        Reload(Sprinting.Value)

        local Key = InputManager:GetInputAction("Default.Sprint")
        JanitorInstance:Add(Key.Pressed:Connect(function()
            Network:FireServerConnection("ChangeSprintState", "REMOTE_EVENT", true)
        end))
        JanitorInstance:Add(Key.Released:Connect(function()
            Network:FireServerConnection("ChangeSprintState", "REMOTE_EVENT", false)
        end))
    end,
}