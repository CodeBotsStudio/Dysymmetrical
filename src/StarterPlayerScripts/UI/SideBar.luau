--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
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
    Type: "Button" | "SmallButton",
    InvertedRender: string?,
    MenuModule: any,
    LayoutOrder: number,
    CloseOnOtherOpen: boolean,
    CloseOthersOnOpen: boolean,
}

local InvertedInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local UI
local BarButtonPrefabs = {
    Button = Utils:FindFirstChild(script, "Button"),
    SmallButton = Utils:FindFirstChild(script, "SmallButton"),
}

local function TweenInverted(BarButton, Inverted: boolean)
    for _, i in BarButton:GetChildren() do
        if #i:GetChildren() > 0 then
            TweenInverted(i, Inverted)
        end

        if i:IsA("TextLabel") then
            local Value = Inverted and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            TweenService:Create(i, InvertedInfo, {TextColor3 = Value}):Play()
        elseif i:IsA("ImageLabel") or i:IsA("ImageButton") then
            local Value = not Inverted and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            local Transp = 0
            if i.Name:lower():find("inverted") then
                Transp = Inverted and 0 or 1
            elseif i.Parent.Name ~= "Holder" then
                continue
            end

            TweenService:Create(i, InvertedInfo, {ImageTransparency = Transp, BackgroundColor3 = Value}):Play()
        end
    end
end

function SideBar:Toggle(visible: boolean)
    UI.Visible = visible
    self.Enabled = visible

    for _, m in self.MenuModules do
        TweenInverted(m.Button, false)
    end
end

function SideBar:CloseAll(Remaining: any)
    for _, menu in self.MenuModules do
        if menu == Remaining or not menu.CloseOnOtherOpen then continue end
        if menu.Opened then
            menu:Close(self.ToggleDuration)
            TweenInverted(menu.Button, false)
        end
    end
end

function SideBar:OpenMenu(Menu)
    Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
    if not Menu.Opened then
        if Menu:Open(self.ToggleDuration) == "Prevented" then
            return
        end
        TweenInverted(Menu.Button, true)
        if Menu.CloseOthersOnOpen then
            self:CloseAll(Menu)
        end
    else
        Menu:Close(self.ToggleDuration)
        TweenInverted(Menu.Button, false)
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
            Type = "Button",
            InvertedRender = "rbxassetid://106935872381429",
            MenuModule = PlayerUIModules.Shop,
            LayoutOrder = 0,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Inventory = {
            Render = "rbxassetid://124486892591913",
            Type = "Button",
            InvertedRender = "rbxassetid://97795375278271",
            MenuModule = PlayerUIModules.Inventory,
            LayoutOrder = 1,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Stats = {
            Render = "rbxassetid://130488549713780",
            Type = "Button",
            InvertedRender = "rbxassetid://72911514685580",
            MenuModule = PlayerUIModules.StatsMenu,
            LayoutOrder = 3,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Spectate = {
            Render = "rbxassetid://89862280432932",
            Type = "Button",
            InvertedRender = "rbxassetid://134398825115015",
            MenuModule = PlayerUIModules.Spectate,
            LayoutOrder = 4,
            CloseOnOtherOpen = false,
            CloseOthersOnOpen = false,
        },
        Settings = {
            Render = "rbxassetid://95524701319726",
            Type = "Button",
            InvertedRender = "rbxassetid://113951492478970",
            MenuModule = PlayerUIModules.Settings,
            LayoutOrder = 5,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Credits = {
            Render = "rbxassetid://82434587437333",
            Type = "Button",
            InvertedRender = "rbxassetid://113410904986274",
            MenuModule = PlayerUIModules.Credits,
            LayoutOrder = 6,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Rules = {
            Render = "rbxassetid://83147016587963",
            Type = "SmallButton",
            InvertedRender = "rbxassetid://90249013398230",
            MenuModule = PlayerUIModules.RulesMenu,
            LayoutOrder = 7,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Changelog = {
            Render = "rbxassetid://82434587437333",
            Type = "SmallButton",
            InvertedRender = "rbxassetid://113410904986274",
            MenuModule = PlayerUIModules.Changelog,
            LayoutOrder = 8,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
    }

    for name, button: Button in Buttons do
        local BarButton = BarButtonPrefabs[button.Type]:Clone()
        BarButton.Name = name
        BarButton.Icon.Image = button.Render
        BarButton.Button.Image = button.Render
        BarButton.InvertedIcon.Image = button.InvertedRender or BarButton.InvertedIcon.Image
        BarButton.Inverted.Image = button.InvertedRender or BarButton.Inverted.Image
        BarButton.Title.Holder.Label.Text = name
        BarButton.LayoutOrder = button.LayoutOrder
        local Menu = require(button.MenuModule)
        Menu.CloseOnOtherOpen = button.CloseOnOtherOpen
        Menu.CloseOthersOnOpen = button.CloseOthersOnOpen
        BarButton.Button.MouseButton1Click:Connect(function()
            self:OpenMenu(Menu)
        end)
        Menu.Button = BarButton

        local OriginalSize = BarButton.Size
        local HoverSize = UDim2.fromScale(OriginalSize.X.Scale * 1.2, OriginalSize.Y.Scale * 1.2)

        self.MenuModules[name] = Menu
        BarButton.Parent = ButtonContainer

        local OriginalYLabelBound = BarButton.Title.Holder.Label.AbsoluteSize.Y
        BarButton.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            TweenService:Create(BarButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = HoverSize}):Play()
            -- Why does `TextLabel.AutomaticSize` not fucking work with `TextLabel.TextScaled`? No idea! I'm mentally insane! :D
            -- `TextLabel.TextSize` doesn't either. What world are we living in?
            local Size = TextService:GetTextSize(BarButton.Title.Holder.Label.Text, OriginalYLabelBound, BarButton.Title.Holder.Label.Font, BarButton.Title.Holder.Label.AbsoluteSize)
            TweenService:Create(BarButton.Title.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.15, Size.X + 56, 0.5, 0)
            }):Play()
        end)
        BarButton.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            TweenService:Create(BarButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = OriginalSize}):Play()
            TweenService:Create(BarButton.Title.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0.5, 0)
            }):Play()
        end)

        LocalPlayer.CharacterAdded:Connect(function(char: Model)
            Menu:Toggle(Utils:FindFirstChild(char, "Role").Value == "Spectator")
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function(char: Model)
        self:Toggle(Utils:FindFirstChild(char, "Role").Value == "Spectator")
    end)
end

return SideBar
