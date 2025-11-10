local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

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

        TimeLabel.Text = Utils:ConvertToMinSec(TimeRemaining.Value)
        Label.Text = LabelTexts[State.Value]

        TimeRemaining.Changed:Connect(function(value: number)
        	TimeLabel.Text = Utils:ConvertToMinSec(value)
        end)
        State.Changed:Connect(function(value: string)
            if value == "Lobby" and not EnoughPlayers.Value then
                Label.Text = LabelTexts.NotEnough
        	elseif LabelTexts[value] then
        		Label.Text = LabelTexts[value]
        	else
        		Label.Text = "PLACEHOLDER"
        	end
        end)
    end,
}
