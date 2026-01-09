local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local StarterGui = game:GetService("StarterGui")

local ItemGUI = require(ReplicatedStorage.Classes.Item.ItemGUI)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(char: Model)
            local Role = char:FindFirstChild("Role")

            if Role.Value ~= "Spectator" then
                -- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

                ItemGUI.InitGUI()
                
                -- return
            end

            -- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
        end)
    end,
}