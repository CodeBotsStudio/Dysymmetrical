local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local InputManager = require(script.Parent.Parent.InputManager)
local PlayerInfoWindow = require(script.PlayerInfoWindow)

local PlayerList = {}

local LocalPlayer = Players.LocalPlayer

function PlayerList:Init()
    local UI = Utils:FindFirstChild(script, "PlayerList")
    UI.Parent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "PlayerList")

    local PlayerPrefab = Utils:FindFirstChild(script, "PlayerContainer")

    local ToggleButton = Utils:FindFirstChild(UI, "Topbar.ToggleButton")

    local CurrentPlayerWindow

    local Open = true
    local function Toggle(Force: boolean?)
        Open = Force ~= nil and Force or not Open
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

        ToggleButton.Text = Open and ">" or "<"
        TweenService:Create(UI, TweenInfo.new(0.245, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(Open and 1 or 1.148, 0.065)}):Play()
    end

    local function SetupPlayer(Player: Player)
        local Container = PlayerPrefab:Clone()
        if Player == LocalPlayer then
            Container.LayoutOrder = -1
        end
        Container.Name = tostring(Player.UserId)

        --name
        Container.PlayerLabel.Text = Player.DisplayName

        --money
        local HiddenMoney = Utils:FindFirstChild(Player, "PlayerData.Settings.Privacy.HideMoney", false)
        local MoneyValue = Utils:FindFirstChild(Player, "leaderstats.Money")

        Container.MoneyLabel.Text = HiddenMoney.Value and "(Hidden)" or tostring(MoneyValue.Value)
        Container.MoneyLabel.TextColor3 = HiddenMoney.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)

        MoneyValue.Changed:Connect(function(value: number)
            Container.MoneyLabel.Text = HiddenMoney.Value and "(Hidden)" or tostring(value)
            Container.MoneyLabel.TextColor3 = HiddenMoney.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
        end)
        HiddenMoney.Changed:Connect(function(value: boolean)
            Container.MoneyLabel.Text = value and "(Hidden)" or tostring(MoneyValue.Value)
            Container.MoneyLabel.TextColor3 = value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
        end)

        --malice
        local MaliceValue = Utils:FindFirstChild(Player, "leaderstats.Malice")
        Container.MaliceLabel.Text = tostring(MaliceValue.Value)
        MaliceValue.Changed:Connect(function(value: number)
            Container.MaliceLabel.Text = tostring(value)
        end)

        Container.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end)
        Container.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end)
        Container.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            if CurrentPlayerWindow then
                local ClickedSame = CurrentPlayerWindow.PlayerShown == Player
                CurrentPlayerWindow:Hide()
                if ClickedSame then
                    return
                end
            end

            CurrentPlayerWindow = PlayerInfoWindow.New(Player, UI.Parent)
            CurrentPlayerWindow.Removed:Connect(function()
                CurrentPlayerWindow = nil
            end)
        end)

        Container.Parent = UI.Content
    end

    LocalPlayer.CharacterAdded:Connect(function(Char: Model)
        local Role = Utils:FindFirstChild(Char, "Role")
        if Role.Value ~= "Spectator" then
            if CurrentPlayerWindow then
                CurrentPlayerWindow:Hide(true)
            end

            UI.Visible = false
        else
            UI.Visible = true
        end
    end)

    InputManager.Miscellaneous.TogglePlayerList.Pressed:Connect(function()
        Toggle()
    end)
    ToggleButton.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    ToggleButton.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)
    ToggleButton.MouseButton1Click:Connect(function()
        Toggle()
    end)

    Players.PlayerAdded:Connect(SetupPlayer)
    Players.PlayerRemoving:Connect(function(Player: Player)
        if UI.Content:FindFirstChild(tostring(Player.UserId)) then
            UI.Content[tostring(Player.UserId)]:Destroy()
        end
    end)

    for _, i in Players:GetPlayers() do
        SetupPlayer(i)
    end
end

return PlayerList
