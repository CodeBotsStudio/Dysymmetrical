--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local LocalPlayer = Players.LocalPlayer

local SideBar = {
    Enabled = true,
    ToggleDuration = 0.5,
    MenuModules = {},
}

type Button = {
    Render: string,
    InvertedRender: string?,
    MenuModule: any,
    LayoutOrder: number,
    CloseOnOtherOpen: boolean,
    CloseOthersOnOpen: boolean,
}

local UI
local BarButtonPrefab = Utils:FindFirstChild(script, "Button")

function SideBar:Toggle(visible: boolean)
    UI.Visible = visible
    self.Enabled = visible
end

function SideBar:CloseAll(Remaining: any)
    for _, menu in self.MenuModules do
        if menu == Remaining or not menu.CloseOnOtherOpen then continue end
        if menu.Opened then
            menu:Close(self.ToggleDuration)
            TweenService:Create(menu.Button.InvertedIcon, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
            TweenService:Create(menu.Button.Inverted, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
            TweenService:Create(menu.Button.Button, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
            TweenService:Create(menu.Button.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
        end
    end
end

function SideBar:Init()
    UI = Utils:FindFirstChild(script, "SideBarUI"):Clone()
    UI.Parent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "SideBar")

    local MoneyLabel = UI.Money.CurrentBalance

    local Cash = Utils:GetPlayerStat(LocalPlayer, "Currency.Money", false)
    MoneyLabel.Text = tostring(Cash.Value).." $"
    Cash.Changed:Connect(function(value: number)
        MoneyLabel.Text = tostring(value).." $"
    end)

    local ButtonContainer = UI.Buttons

    local PlayerUIModules = LocalPlayer.PlayerScripts.UI

    local Buttons: {[string]: Button} = {
        Shop = {
            Render = "rbxassetid://140391842164127",
            InvertedRender = "rbxassetid://106935872381429",
            MenuModule = PlayerUIModules.Shop,
            LayoutOrder = 0,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Inventory = {
            Render = "rbxassetid://124486892591913",
            InvertedRender = "rbxassetid://97795375278271",
            MenuModule = PlayerUIModules.Inventory,
            LayoutOrder = 1,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Stats = {
            Render = "rbxassetid://130488549713780",
            InvertedRender = "rbxassetid://72911514685580",
            MenuModule = PlayerUIModules.StatsMenu,
            LayoutOrder = 3,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Spectate = {
            Render = "rbxassetid://89862280432932",
            InvertedRender = "rbxassetid://134398825115015",
            MenuModule = PlayerUIModules.Spectate,
            LayoutOrder = 4,
            CloseOnOtherOpen = false,
            CloseOthersOnOpen = false,
        },
        Settings = {
            Render = "rbxassetid://95524701319726",
            InvertedRender = "rbxassetid://113951492478970",
            MenuModule = PlayerUIModules.Settings,
            LayoutOrder = 5,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Credits = {
            Render = "rbxassetid://82434587437333",
            InvertedRender = "rbxassetid://113410904986274",
            MenuModule = PlayerUIModules.Credits,
            LayoutOrder = 6,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
    }

    for name, button: Button in Buttons do
        local BarButton = BarButtonPrefab:Clone()
        BarButton.Name = name
        BarButton.Icon.Image = button.Render
        BarButton.Button.Image = button.Render
        BarButton.InvertedIcon.Image = button.InvertedRender or BarButton.InvertedIcon.Image
        BarButton.Inverted.Image = button.InvertedRender or BarButton.Inverted.Image
        BarButton.LayoutOrder = button.LayoutOrder
        local Menu = require(button.MenuModule)
        Menu.CloseOnOtherOpen = button.CloseOnOtherOpen
        BarButton.Button.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            if not Menu.Opened then
                Menu:Open(self.ToggleDuration)
                TweenService:Create(BarButton.InvertedIcon, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
                TweenService:Create(BarButton.Inverted, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
                TweenService:Create(BarButton.Button, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
                TweenService:Create(BarButton.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
                if button.CloseOthersOnOpen then
                    self:CloseAll(Menu)
                end
            else
                Menu:Close(self.ToggleDuration)
                TweenService:Create(BarButton.InvertedIcon, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
                TweenService:Create(BarButton.Inverted, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
                TweenService:Create(BarButton.Button, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
                TweenService:Create(BarButton.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
            end
        end)
        Menu.Button = BarButton

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
            Menu:Toggle(Utils:FindFirstChild(char, "Role").Value == "Spectator")
        end)

        self.MenuModules[name] = Menu
        BarButton.Parent = ButtonContainer
    end

    LocalPlayer.CharacterAdded:Connect(function(char: Model)
        self:Toggle(Utils:FindFirstChild(char, "Role").Value == "Spectator")
    end)
end

return SideBar
