--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local LocalPlayer = Players.LocalPlayer

local SideBar = {
    Enabled = true,
    ToggleDuration = 0.5,
    MenuModules = {},
}

type Button = {
    Render: string,
    MenuModule: any,
    LayoutOrder: number,
}

local UI
local BarButtonPrefab = CommonUtils:FindFirstChild(script, "Button")

function SideBar:Toggle(visible: boolean)
    UI.Visible = visible
    self.Enabled = visible
end

function SideBar:CloseAll(Remaining: any)
    for _, menu in self.MenuModules do
        if menu == Remaining then continue end
        if menu.Opened then
            menu:Close(self.ToggleDuration)
        end
    end
end

function SideBar:Init()
    UI = CommonUtils:FindFirstChild(script, "SideBarUI"):Clone()
    UI.Parent = CommonUtils:FindFirstChild(LocalPlayer.PlayerGui, "SideBar")

    local MoneyLabel = UI.Money.CurrentBalance

    local Cash = CommonUtils:GetPlayerStat(LocalPlayer, "Currency.Money", false)
    MoneyLabel.Text = tostring(Cash.Value).." $"
    Cash.Changed:Connect(function(value: number)
        MoneyLabel.Text = tostring(value).." $"
    end)

    local ButtonContainer = UI.Buttons

    local PlayerUIModules = LocalPlayer.PlayerScripts.UI

    local Buttons: {[string]: Button} = {
        Shop = {
            Render = "rbxassetid://115748427612108",
            MenuModule = PlayerUIModules.Shop,
            LayoutOrder = 0,
        },
        Inventory = {
            Render = "rbxassetid://121848294238586",
            MenuModule = PlayerUIModules.Inventory,
            LayoutOrder = 2,
        },
        Stats = {
            Render = "rbxassetid://86407971397188",
            MenuModule = PlayerUIModules.StatsMenu,
            LayoutOrder = 3,
        },
        Settings = {
            Render = "rbxassetid://138518322199012",
            MenuModule = PlayerUIModules.Settings,
            LayoutOrder = 5,
        },
        Credits = {
            Render = "rbxassetid://86407971397188",
            MenuModule = PlayerUIModules.Credits,
            LayoutOrder = 6,
        },
    }

    for name, button: Button in Buttons do
        local BarButton = BarButtonPrefab:Clone()
        BarButton.Name = name
        BarButton.Icon.Image = button.Render
        BarButton.LayoutOrder = button.LayoutOrder
        local Menu = require(button.MenuModule)
        BarButton.Button.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            if not Menu.Opened then
                Menu:Open(self.ToggleDuration)
            else
                Menu:Close(self.ToggleDuration)
            end
        end)

        local OriginalSize = BarButton.Size
        local HoverSize = UDim2.fromScale(OriginalSize.X.Scale * 1.2, OriginalSize.Y.Scale * 1.2)

        BarButton.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            TweenService:Create(BarButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = HoverSize}):Play()
        end)
        BarButton.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            TweenService:Create(BarButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = OriginalSize}):Play()
        end)

        LocalPlayer.CharacterAdded:Connect(function(char: Model)
            Menu:Toggle(CommonUtils:FindFirstChild(char, "Role").Value == "Spectator")
        end)

        self.MenuModules[name] = Menu
        BarButton.Parent = ButtonContainer
    end

    LocalPlayer.CharacterAdded:Connect(function(char: Model)
        self:Toggle(CommonUtils:FindFirstChild(char, "Role").Value == "Spectator")
    end)
end

return SideBar
