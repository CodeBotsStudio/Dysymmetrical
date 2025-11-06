local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

local MoneyXPRewards = {}

function MoneyXPRewards:Init()
    local UI = Utils:FindFirstChild(Players.LocalPlayer.PlayerGui, "MoneyXPRewards")
    local Container = Utils:FindFirstChild(script, "MoneyXPRewardsContainer")
    Container.Parent = UI
    local Prefab = Utils:FindFirstChild(script, "Reward")

    Network:SetConnection("GrantReward", "REMOTE_EVENT", function(Money: number?, EXP: number?, Reason: string?)
        if not Utils:GetPlayerSetting(Players.LocalPlayer, "Miscellaneous.ShowRewardNotifications") then
            return
        end

        local Notification = Prefab:Clone()
        local Size = Notification.Size
        Notification.Size = Utils.UDim.Zero

        local Text = "Granted "
        if Money and EXP then
            Text = Text..tostring(Money).."$ and "..tostring(EXP).." EXP"
        elseif Money then
            Text = Text..tostring(Money).."$"
        elseif EXP then
            Text = Text..tostring(EXP).." EXP"
        else
            Notification:Destroy()
            return
        end

        if Reason then
            Text = Text.." for "..Reason
        end
        Text = Text.."."

        Notification.Text = Text

        Notification.Parent = Container

        TweenService:Create(Notification, TweenInfo.new(0.4), {Size = Size}):Play()
        task.wait(5.4)
        TweenService:Create(Notification, TweenInfo.new(0.4), {Size = Utils.UDim.Zero}):Play()
        Debris:AddItem(Notification, 1)
    end)
end

return MoneyXPRewards
