local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils:FindFirstChild(workspace, "TempObjectFolders.Hitboxes").ChildAdded:Connect(function(Child)
            if Child:IsA("BasePart") and Utils:GetPlayerSetting(Players.LocalPlayer, "Advanced.ShowHitboxes") then
                Child.Material = Enum.Material.ForceField
                Child.Transparency = 0.65
            end
        end)
    end,
}