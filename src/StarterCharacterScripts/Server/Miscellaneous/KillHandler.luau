local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)
return {
    Init = function(_)
        local Char = script.Parent.Parent.Parent
        local Player = Players:GetPlayerFromCharacter(Char)

        local Role = CommonUtils:FindFirstChild(Char, "Role")
        task.wait(0.7)
        if Role.Value == "Spectator" then
            return
        elseif Role.Value == "Killer" then
            Network:SetConnection("KilledPlayer", "REMOTE_EVENT", function(_deadPlayer: Player)
                Player.PlayerData.Stats.KillerStats.Kills.Value += 1
            end)
            return
        end

        local Thread: thread

        local Killer = Instance.new("ObjectValue")
        Killer.Name = "Killer"
        Killer.Parent = Char
        Killer.Changed:Connect(function(value: boolean) --no need to add to Conns since it automatically disconnects due to Killer being destroyed on death
            if Thread then
                task.cancel(Thread)
            end
            if value then
                Thread = task.delay(15, function()
                    Killer.Value = nil
                end)
            end
        end)

        local Conns = {}
        
        table.insert(Conns, Char:FindFirstChildOfClass("Humanoid").Died:Connect(function()
            if Killer.Value and Killer.Value:IsA("Player") then
                Network:FireClientConnection(Killer.Value, "KilledPlayer", "REMOTE_EVENT", Player)
                Network:FireConnection("KilledPlayer", Killer.Value, Player)
            end
        end))

        table.insert(Conns, Players.PlayerRemoving:Connect(function(p: Player)
            if p == Player then
                Network:FireClientConnection(Killer.Value, "KilledPlayer", "REMOTE_EVENT", Player)
                Network:FireConnection("KilledPlayer", Killer.Value, Player)
            end
        end))
        table.insert(Conns, Char.Destroying:Connect(function()
            if Char.Parent then
                return
            end
            for _, i in Conns do
                i:Disconnect()
            end
        end))
    end
}