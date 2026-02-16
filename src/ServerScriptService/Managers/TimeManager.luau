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
    _CurrentMap = nil, -- Current map name for MapConfig lookups
    _CurrentKiller = nil, -- Current killer character name for LMS override lookup
    _CurrentKillerConfig = nil, -- Current killer's character config with LastManStandingTheme
    _LMSMusicDuration = nil, -- Cached LMS duration from music
}
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
local MapConfig = require(game:GetService("ServerScriptService").System.MapConfig)
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

--- Set the current map for MapConfig lookups
---@param mapName string The name of the current map
function TimeManager.SetCurrentMap(mapName: string)
    TimeManager._CurrentMap = mapName
    -- Pre-load LMS music duration if available
    if MapConfig.IsLMSEnabled(mapName) then
        TimeManager._LMSMusicDuration = MapConfig.GetLMSDuration(mapName)
    end
end

--- Set the current killer character (for character-level LMS overrides)
---@param characterName string? The killer's character name
function TimeManager.SetCurrentKiller(characterName: string?)
    TimeManager._CurrentKiller = characterName
end

--- Switch to Last Man Standing timing (uses character override, map config, or fallback)
---@param lmsTimeOverride number? Optional override for LMS duration in seconds
function TimeManager.StartLastManStanding(lmsTimeOverride: number?)
    local lmsTime = lmsTimeOverride
    
    -- Try to use character-level override first
    if not lmsTime and TimeManager._CurrentKiller then
        lmsTime = MapConfig.GetLMSDuration(TimeManager._CurrentMap or "Unknown", TimeManager._CurrentKiller)
    end
    
    -- Try to use map-based duration if no character override
    if not lmsTime and TimeManager._CurrentMap then
        if TimeManager._LMSMusicDuration then
            lmsTime = TimeManager._LMSMusicDuration
        else
            lmsTime = MapConfig.GetLMSDuration(TimeManager._CurrentMap)
        end
    end
    
    -- Fall back to config or default
    lmsTime = lmsTime or TimeManager.Config.LastManStandingTime or 90
    
    TimeManager.Config.LastManStandingTime = lmsTime
    TimeManager.SetTime(lmsTime)
end

--- You can use this instead of changing the value directly. It works better.
function TimeManager.SetTime(value: number)
    TimeManager.CurrentTime = value
    TimeValue.Value = value
end

return TimeManager
