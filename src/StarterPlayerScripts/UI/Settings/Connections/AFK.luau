local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local AFKLabel = Utils:FindFirstChild(Players.LocalPlayer.PlayerGui, "AFKLabel")

return function(Value: boolean)
    AFKLabel.Enabled = Value
end