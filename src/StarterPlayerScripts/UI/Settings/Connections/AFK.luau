local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

local AFKLabel = CommonUtils:FindFirstChild(Players.LocalPlayer.PlayerGui, "AFKLabel")

return function(Value: boolean)
    AFKLabel.Enabled = Value
end