local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

return {
    Init = function(_)
        CommonUtils:FindFirstChild(workspace, "TempObjectFolders.Hitboxes").ChildAdded:Connect(function(Child)
            if Child:IsA("BasePart") and CommonUtils:GetPlayerSetting(Players.LocalPlayer, "Advanced.ShowHitboxes") then
                Child.Material = Enum.Material.ForceField
                Child.Transparency = 0.65
            end
        end)
    end,
}