local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local InkFX = require(ReplicatedStorage.Modules.InkFX)

return {
    Init = function(_)
        local TimeStats = ReplicatedStorage.RoundInfo

        local TimeRemaining = TimeStats.TimeRemaining
        local State = TimeStats.CurrentState

        local Frame = Utils.Instance.FindFirstChild(script, "TimeInfo")
        Frame.Parent = Utils.Instance.FindFirstChild(game:GetService("Players").LocalPlayer.PlayerGui, "Time")
        local TimeLabel = Frame.TimeLabel
        local Label = Frame.Label

        local EnoughPlayers = ReplicatedStorage.RoundInfo.EnoughPlayers

        local LabelTexts = {
        	Lobby = "La ronda empieza en...",
        	InRound = "La ronda acaba en...",
        	NotEnough = "Esperando jugadores...",
            Frozen = "¡Tiempo congelado!",
        }

        TimeLabel.Text = Utils.Math.ConvertToMinSec(math.ceil(TimeRemaining.Value))
        Label.Text = LabelTexts[State.Value]

        local LastSecond = math.ceil(TimeRemaining.Value)
        TimeRemaining.Changed:Connect(function(value: number)
        	TimeLabel.Text = Utils.Math.ConvertToMinSec(math.ceil(value))
            local Second = math.ceil(value)
            if Second ~= LastSecond and State.Value == "InRound" and Second <= 10 and Second > 0 then
                InkFX.Pop(TimeLabel, 1.22, 0.35)
                InkFX.Ripple(Frame, 1.25, 0.6)
            end
            LastSecond = Second
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

        State.Changed:Connect(function(value: string)
            Update(value)
            InkFX.Ripple(Frame, 1.6, 0.7)
        end)
        EnoughPlayers.Changed:Connect(function()
            Update(State.Value)
        end)
        Utils.Instance.ObserveAttribute(workspace, "FreezeTime", function()
            Update(State.Value)
        end)
        Update(State.Value)
    end,
}
