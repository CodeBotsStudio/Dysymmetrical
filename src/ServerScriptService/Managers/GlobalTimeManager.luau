local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)

local GlobalTimeManager = {
    --- The current time value that's being operated on by the manager.
    Time = 0,
    --- Some common config for time.
    Config = {
        --- The time it will take to start a round.
        LobbyTime = 50,
        --- The time it will take to finish a round.
        RoundTime = 240,
        --- The time it will take to finish a round in LMS.
        DefaultLMSTime = 90,

        --- If `true`, the manager will wait until the count of loaded players is equal to or higher than `MinimumPlayerCount`.
        WaitForEnoughPlayers = true,
        --- The minimum amount of players there must be for the manager to operate on time if `WaitForEnoughPlayers` is `true`.
        MinimumPlayerCount = 2,
    },
    --- A callback that'll be executed when the time reaches 0.
    OnTimerEnd = nil,
    --- If `false`, the time won't be decreased.
    CanDecreaseTime = true,
    --- If `true`, the time won't be decreased AND a message saying "Time frozen!" will appear in the time label.
    FreezeTime = true,
}

local RoundInfo: Configuration = ReplicatedStorage.RoundInfo

function GlobalTimeManager:Init()
    --setting up FreezeTime
    GlobalTimeManager.FreezeTime = workspace:GetAttribute("FreezeTime")
    Utils.Instance.ObserveAttribute(workspace, "FreezeTime", function(value: boolean)
        GlobalTimeManager.FreezeTime = value
    end)
    
    --general loop
    RunService.Heartbeat:Connect(function(delta: number)
        --if there are not enough players, reset the time and stop
        if GlobalTimeManager.Config.WaitForEnoughPlayers and RoundInfo:GetAttribute("State") == "Lobby" and not GlobalTimeManager._EnoughPlayersPresent() then
            RoundInfo:SetAttribute("EnoughPlayers", false)
            if GlobalTimeManager.Time ~= GlobalTimeManager.Config.LobbyTime then
                GlobalTimeManager.SetTime(GlobalTimeManager.Config.LobbyTime)
            end

            return
        end
        
        --enough players, set the time
        RoundInfo:SetAttribute("EnoughPlayers", true)
        if GlobalTimeManager.CanDecreaseTime and not GlobalTimeManager.FreezeTime then
            GlobalTimeManager.SetTime(GlobalTimeManager.Time - delta)

            --if it reached 0, stop and execute the callback
            if GlobalTimeManager.Time <= 0 then
                GlobalTimeManager.CanDecreaseTime = false
                GlobalTimeManager.SetTime(0)

                if GlobalTimeManager.OnTimerEnd then
                    GlobalTimeManager.OnTimerEnd()
                end
            end
        end
    end)
end

function GlobalTimeManager._EnoughPlayersPresent()
    return Utils.Player.GetLoadedPlayers(false) >= GlobalTimeManager.Config.MinimumPlayerCount
end

--- You can use this instead of changing the value directly. It works better.
function GlobalTimeManager.SetTime(value: number)
    GlobalTimeManager.Time = value
    RoundInfo:SetAttribute("Time", value)
end

return GlobalTimeManager
