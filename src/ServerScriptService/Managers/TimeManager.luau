--- Class used to manage the game's time in its current state, let it be Lobby or Round or any custom state you implement.
local TimeManager = {
    CurrentTime = 0,
    Config = {
        LobbyTime = 5, --0:45 / 45
        RoundTime = 210, --3:30 / 210
        LastManStandingTime = 90, --1:30 / 90

        --- If true, `TimeManager` will wait until `TimeManager.Config.MinimumPlayerAmount` players have loaded their game to tick down.
        WaitForEnoughPlayers = true,
        MinimumPlayerAmount = 4, --change this to 1 to test rounds alone instead of using `WaitForEnoughPlayers`
    },
    --- Function that'll execute whenever the timer reaches 0.
    OnTimerEnd = function() end, --func
    CanDecreaseTime = true,
}
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
--
local TimeValue: NumberValue = ReplicatedStorage.RoundInfo.TimeRemaining
local State: StringValue = ReplicatedStorage.RoundInfo.CurrentState
local EnoughPlayers: BoolValue = ReplicatedStorage.RoundInfo.EnoughPlayers
local LoadedPlayers = ReplicatedStorage.LoadedPlayers
--
function TimeManager:Init()
    --print("FINISH TIMEMANAGER LATER >:(") --gotta save this line for memories lol
    
    RunService.Heartbeat:Connect(function(delta: number)
        if self.Config.WaitForEnoughPlayers and State.Value == "Lobby" and self:_EnoughPlayers() then
            EnoughPlayers.Value = false
            if self.CurrentTime ~= self.Config.LobbyTime then
                self:SetTime(self.Config.LobbyTime)
            end
            return
        end
        
        EnoughPlayers.Value = true
        if self.CanDecreaseTime then
            self:SetTime(TimeValue.Value - delta)
            if TimeValue.Value <= 0 then
                self.CanDecreaseTime = false
                self:SetTime(0)
                self.OnTimerEnd()
            end
        end
    end)

    self:SetTime(self.Config.LobbyTime) --starting with lobby since `Init()` is called when the server initializes
end

function TimeManager:_EnoughPlayers()
    local PlayersAvailable = LoadedPlayers:GetChildren()
    for _, obj in PlayersAvailable do
        if obj.Value.PlayerData.Settings.Game.AFK.Value then
            table.remove(PlayersAvailable, table.find(PlayersAvailable, obj))
        end
    end

    return #PlayersAvailable < self.Config.MinimumPlayerAmount
end

--- You can use this instead of changing the value directly. It works better.
function TimeManager:SetTime(value: number)
    self.CurrentTime = value
    TimeValue.Value = value
end

return TimeManager
