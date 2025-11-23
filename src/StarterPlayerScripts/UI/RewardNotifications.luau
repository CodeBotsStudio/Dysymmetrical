--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

local RewardNotifications = {}

function RewardNotifications:Init()
    local Container = Utils:FindFirstChild(script, "RewardNotificationContainer")
    Container.Parent = Utils:FindFirstChild(Players.LocalPlayer.PlayerGui, "RewardNotifications")

    local Prefab = Utils:FindFirstChild(script, "RewardNotification")
    local AchievementPrefab = Utils:FindFirstChild(script, "AchievementNotification")

    Network:SetConnection("ShowRewardNotification", "REMOTE_EVENT", function(Module: ModuleScript | string, Type: string)
        if not Type then
            Type = "QuotedGrantedSkin"
        end

        local IsAchievement = Type:lower():find("achievement")

        local Card = (IsAchievement and AchievementPrefab or Prefab):Clone()
        local Info = IsAchievement and Utils:GetAchievementData(Module) or require(Module)
        
        Card.ImageContainer.Render.Image = IsAchievement and Info.Icon or Info.Config.Render

        local Text = (Type:lower():find("bought") and "Bought" or "Received").." \""..tostring(Info.Config.Name).."\" "

        if Type:lower():find("emote") then
            Text = Text.." emote"
        elseif Type:lower():find("skin") then
            Text = Text.." skin"
        elseif Type:lower():find("achievement") then
            Text = "Achievement granted!"
        end

        Card.TextContainer.RewardLabel.Text = Text
        
        local Quote = Info.Config and Info.Config.Quote or Info.Title
        if Type:lower():find("quoted") then
            Quote = "\""..Quote.."\""
        end

        Card.TextContainer.RewardQuote.Text = Quote

        Card.Size = Utils.UDim.Zero
        Card.Parent = Container
        TweenService:Create(Card, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 0.2)}):Play()
        task.wait(5)
        TweenService:Create(Card, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = Utils.UDim.Zero}):Play()
        task.wait(1)
        Card:Destroy()
    end)
end

return RewardNotifications
