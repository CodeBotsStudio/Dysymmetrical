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
            Frozen = "Time frozen!",
        }

        TimeLabel.Text = Utils:ConvertToMinSec(math.ceil(TimeRemaining.Value))
        Label.Text = LabelTexts[State.Value]

        TimeRemaining.Changed:Connect(function(value: number)
        	TimeLabel.Text = Utils:ConvertToMinSec(math.ceil(value))
        end)

        local function Update(value: string)
            if workspace:GetAttribute("FreezeTime") then
                Label.Text = LabelTexts.Frozen
            elseif value == "Lobby" and not EnoughPlayers.Value then
                Label.Text = LabelTexts.NotEnough
        	else
        		Label.Text = LabelTexts[value] or "PLACEHOLDER"
        	end
        end

        State.Changed:Connect(Update)
        Update(State.Value)
    end,
}
