local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(script.Parent)
local Utils = require(ReplicatedStorage.Modules.Utils)

local DefaultLabels = {
    Lobby = "Round begins in...",
    InRound = "Round ends in...",
    NotEnough = "Waiting for players...",
    Frozen = "Time frozen!",
}

return {
    Init = function(_)
        local Info = ReplicatedStorage.RoundInfo
        local Frame = Utils.Instance.AwaitChild(script, "TimeFrame"):Clone()
        Frame.Parent = UIManager.FetchScreenGui("Time")

        local TimeCounter = Frame.TimeCounter
        local Label = Frame.Label

        local function UpdateLabel()
            if workspace:GetAttribute("FreezeTime") == true then
                Label.Text = DefaultLabels.Frozen
                return
            end
            
            local CurrentState = Info:GetAttribute("State")

            if CurrentState == "Lobby" and Info:GetAttribute("EnoughPlayers") == false then
                Label.Text = DefaultLabels.NotEnough
                return
            end

            Label.Text = DefaultLabels[CurrentState] or "PLACEHOLDER"
        end

        local function UpdateTime()
            TimeCounter.Text = Utils.Math.ConvertToMinSec(math.ceil(Info:GetAttribute("Time")))
        end

        Utils.Instance.ObserveAttribute(Info, "Time", UpdateTime)
        Utils.Instance.ObserveAttribute(Info, "State", UpdateLabel)
        Utils.Instance.ObserveAttribute(Info, "EnoughPlayers", UpdateLabel)
        Utils.Instance.ObserveAttribute(workspace, "FreezeTime", UpdateLabel)
    end,
}