local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local function toMS(s: number): string
	return string.format("%02i:%02i", s/60, s%60)
end

return {
    Init = function(_)
        local TimeStats = ReplicatedStorage.RoundInfo

        local TimeRemaining = TimeStats.TimeRemaining
        local State = TimeStats.CurrentState

        local Frame = Utils:FindFirstChild(script, "TimeInfo")
        Frame.Parent = Utils:FindFirstChild(game:GetService("Players").LocalPlayer.PlayerGui, "Time")
        local TimeLabel = Frame.TimeLabel
        local Label = Frame.Label

        local EnoughPlayers = ReplicatedStorage.RoundInfo.EnoughPlayers

        local LabelTexts = {
        	Lobby = "Round begins in...",
        	InRound = "Round ends in...",
        	NotEnough = "Waiting for players...",
        }

        TimeLabel.Text = toMS(TimeRemaining.Value)
        Label.Text = LabelTexts[State.Value]

        TimeRemaining.Changed:Connect(function(value: number)
        	TimeLabel.Text = toMS(value)
        end)
        State.Changed:Connect(function(value: string)
        	if LabelTexts[value] then
        		Label.Text = LabelTexts[value]
        	else

        		Label.Text = "PLACEHOLDER"
        	end
        end)

        RunService.PreRender:Connect(function()
        	if State.Value == "Lobby" and not EnoughPlayers.Value then
        		Label.Text = LabelTexts.NotEnough
        	else
        		Label.Text = LabelTexts[State.Value]
        	end
        end)
    end,
}
