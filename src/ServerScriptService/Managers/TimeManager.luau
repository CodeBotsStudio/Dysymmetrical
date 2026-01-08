--- Class used to manage the game's time in its current state, let it be Lobby or Round or any custom state you implement.
local TimeManager = {
    CurrentTime = 0,
    Config = {
        LobbyTime = 45, --0:45 / 45
        RoundTime = 240, --4:00 / 240
        LastManStandingTime = 90, --1:30 / 90

        --- If true, `TimeManager` will wait until `TimeManager.Config.MinimumPlayerAmount` players have loaded their game to tick down.
        WaitForEnoughPlayers = true,
        MinimumPlayerAmount = 2, --change this to 1 to test rounds alone instead of using `WaitForEnoughPlayers`
    },
    --- Function that'll execute whenever the timer reaches 0.
    OnTimerEnd = function() end, --func
    --differentiate these two
    CanDecreaseTime = true, --used internally
    FreezeTime = false, --used with the workspace attribute
}
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
--
local TimeValue: NumberValue = ReplicatedStorage.RoundInfo.TimeRemaining
local State: StringValue = ReplicatedStorage.RoundInfo.CurrentState
local EnoughPlayers: BoolValue = ReplicatedStorage.RoundInfo.EnoughPlayers
--
function TimeManager:Init()
    --print("FINISH TIMEMANAGER LATER >:(") --gotta save this line for memories lol

    TimeManager.FreezeTime = workspace:GetAttribute("FreezeTime")
    Utils.Instance.ObserveAttribute(workspace, "FreezeTime", function(value: boolean)
        TimeManager.FreezeTime = value
    end)
    
    RunService.Heartbeat:Connect(function(delta: number)
        if TimeManager.Config.WaitForEnoughPlayers and State.Value == "Lobby" and not TimeManager._EnoughPlayers() then
            EnoughPlayers.Value = false
            if TimeManager.CurrentTime ~= TimeManager.Config.LobbyTime then
                TimeManager.SetTime(TimeManager.Config.LobbyTime)
            end
            return
        end
        
        EnoughPlayers.Value = true
        if TimeManager.CanDecreaseTime and not TimeManager.FreezeTime then
            TimeManager.SetTime(TimeManager.CurrentTime - delta)
            if TimeManager.CurrentTime <= 0 then
                TimeManager.CanDecreaseTime = false
                TimeManager.SetTime(0)
                TimeManager.OnTimerEnd()
            end
        end
    end)

    TimeManager.SetTime(TimeManager.Config.LobbyTime) --starting with lobby since `Init()` is called when the server initializes
end

function TimeManager._EnoughPlayers()
    return #Utils.Player.GetLoadedPlayers(false) >= TimeManager.Config.MinimumPlayerAmount
end

--- You can use this instead of changing the value directly. It works better.
function TimeManager.SetTime(value: number)
    TimeManager.CurrentTime = value
    TimeValue.Value = value
end

return TimeManager
