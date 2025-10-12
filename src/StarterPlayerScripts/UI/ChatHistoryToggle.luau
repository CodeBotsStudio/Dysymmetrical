--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

local success
repeat
	success = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	task.wait()
until success --this means that it has initialized

return {
    Init = function(_)
        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(Char)
            local IsSpectator = CommonUtils:FindFirstChild(Char, "Role").Value == "Spectator"
            TextChatService:FindFirstChildOfClass("ChatWindowConfiguration").Enabled = IsSpectator
            StarterGui:SetCore("ResetButtonCallback", IsSpectator)
        end)
    end,
}