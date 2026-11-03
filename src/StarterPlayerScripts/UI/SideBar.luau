local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local InkFX = require(ReplicatedStorage.Modules.InkFX)

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
local function Sway(BarButton: GuiObject)
    for _, Name in {"Button", "Inverted"} do
        local Image = BarButton:FindFirstChild(Name) :: GuiObject
        local Lean = TweenService:Create(Image, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = -5})
        Lean.Completed:Once(function(State: Enum.PlaybackState)
            if State ~= Enum.PlaybackState.Completed then
                return
            end
            TweenService:Create(Image, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
        end)
        Lean:Play()
    end
end

local function Breathe(Buttons: {[GuiObject]: number})
    local Clock = 0
    game:GetService("RunService").RenderStepped:Connect(function(dt: number)
        Clock += dt
        local Calm = InkFX.Calm()
        for Scale, Phase in Buttons do
            Scale.Scale = if Calm then 1 else 1 + 0.025 * math.sin(Clock * 1.6 + Phase)
        end
    end)
end

local UI
local BarButtonPrefabs = {
    Button = Utils.Instance.FindFirstChild(script, "Button"),
    SmallButton = Utils.Instance.FindFirstChild(script, "SmallButton"),
}

local function TweenInverted(BarButton, Inverted: boolean)
    for _, Child in BarButton:GetChildren() do
        if #Child:GetChildren() > 0 then
            TweenInverted(Child, Inverted)
        end

        if Child:IsA("TextLabel") then
            local Value = Inverted and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            TweenService:Create(Child, InvertedInfo, {TextColor3 = Value}):Play()
        elseif Child:IsA("ImageLabel") or Child:IsA("ImageButton") then
            local Value = not Inverted and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            local Transp = 0
            if Child.Name:lower():find("inverted") then
                Transp = Inverted and 0 or 1
            elseif Child.Parent.Name ~= "Holder" then
                continue
            end

            TweenService:Create(Child, InvertedInfo, {ImageTransparency = Transp, BackgroundColor3 = Value}):Play()
        end
    end
end

function SideBar.Toggle(visible: boolean)
    UI.Visible = visible
    SideBar.Enabled = visible

    for _, m in SideBar.MenuModules do
        if not m.Button then
            continue
        end
        TweenInverted(m.Button, false)
    end
end

function SideBar.CloseAll(Remaining: any)
    for _, menu in SideBar.MenuModules do
        if menu == Remaining or not menu.CloseOnOtherOpen or not menu.UIInstance then continue end
        if menu.Opened then
            menu.Close(SideBar.ToggleDuration)
            if not menu.Button then
                continue
            end
            TweenInverted(menu.Button, false)
        end
    end
end

function SideBar.OpenMenu(Menu)
    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
    if not Menu.Opened then
        if Menu.Open(SideBar.ToggleDuration) == "Prevented" then
            return
        end
        if Menu.Button then
            TweenInverted(Menu.Button, true)
        end
        InkFX.Reveal(Menu.UIInstance, false)
        if Menu.CloseOthersOnOpen then
            SideBar.CloseAll(Menu)
        end
    else
        InkFX.Reveal(Menu.UIInstance, true)
        Menu.Close(SideBar.ToggleDuration)
        if Menu.Button then
            TweenInverted(Menu.Button, false)
        end
    end
end

function SideBar:Init()
    UI = Utils.Instance.FindFirstChild(script, "SideBarUI"):Clone()
    UI.Parent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "SideBar")

    local MoneyLabel = UI.Money.CurrentBalance

    local Cash = Utils.PlayerData.GetPlayerStat(LocalPlayer, "Currency.Money", false)
    MoneyLabel.Text = tostring(Cash.Value).." $"
    Cash.Changed:Connect(function(value: number)
        MoneyLabel.Text = tostring(value).." $"
    end)

    local ButtonContainer = UI.Buttons

    local PlayerUIModules = LocalPlayer.PlayerScripts.UI

    local Breathing = {}
    Breathe(Breathing)

    local Buttons: {[string]: Button} = {
        Shop = {
            Render = "rbxassetid://92125848707503",
            Type = "Button",
            InvertedRender = "rbxassetid://88124154416159",
            MenuModule = PlayerUIModules.Shop,
            LayoutOrder = 0,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Inventory = {
            Render = "rbxassetid://133773587567288",
            Type = "Button",
            InvertedRender = "rbxassetid://135032912792327",
            MenuModule = PlayerUIModules.Inventory,
            LayoutOrder = 1,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Achievements = {
            Render = "rbxassetid://116072020411630",
            Type = "Button",
            InvertedRender = "rbxassetid://132952592975074",
            MenuModule = PlayerUIModules.AchievementsMenu,
            LayoutOrder = 2,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Stats = {
            Render = "rbxassetid://136234713338136",
            Type = "Button",
            InvertedRender = "rbxassetid://126222746123066",
            MenuModule = PlayerUIModules.StatsMenu,
            LayoutOrder = 3,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Spectate = {
            Render = "rbxassetid://98665327829798",
            Type = "Button",
            InvertedRender = "rbxassetid://99614397357911",
            MenuModule = PlayerUIModules.Spectate,
            LayoutOrder = 4,
            CloseOnOtherOpen = false,
            CloseOthersOnOpen = false,
        },
        Settings = {
            Render = "rbxassetid://115123853519355",
            Type = "Button",
            InvertedRender = "rbxassetid://112043618362631",
            MenuModule = PlayerUIModules.Settings,
            LayoutOrder = 5,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Credits = {
            Render = "rbxassetid://102863849269730",
            Type = "Button",
            InvertedRender = "rbxassetid://82305913763140",
            MenuModule = PlayerUIModules.Credits,
            LayoutOrder = 6,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Rules = {
            Render = "rbxassetid://88200919300377",
            Type = "SmallButton",
            InvertedRender = "rbxassetid://105621437001449",
            MenuModule = PlayerUIModules.RulesMenu,
            LayoutOrder = 7,
            CloseOnOtherOpen = true,
            CloseOthersOnOpen = true,
        },
        Changelog = {
            Render = "rbxassetid://102863849269730",
            Type = "SmallButton",
            InvertedRender = "rbxassetid://82305913763140",
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
            InkFX.Ripple(BarButton, 1.75, 0.6)
            SideBar.OpenMenu(Menu)
        end)
        Breathing[Instance.new("UIScale", BarButton)] = button.LayoutOrder * 0.7
        Menu.Button = BarButton

        --TODO: replace these variables only if the size is the hidden one to handle resolution changes
        local OriginalSize = BarButton.Size
        local HoverSize = UDim2.fromScale(OriginalSize.X.Scale * 1.2, OriginalSize.Y.Scale * 1.2)

        SideBar.MenuModules[name] = Menu
        BarButton.Parent = ButtonContainer

        local OriginalYLabelBound = BarButton.Title.Holder.Label.AbsoluteSize.Y
        local function Hover()
            if not InkFX.Calm() then
                InkFX.Ripple(BarButton, 1.45, 0.45)
                Sway(BarButton)
            end
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            TweenService:Create(BarButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = HoverSize}):Play()
            -- Why does `TextLabel.AutomaticSize` not fucking work with `TextLabel.TextScaled`? No idea! I'm mentally insane! :D
            -- `TextLabel.TextSize` doesn't either. What world are we living in?
            -- 
            -- reading this 2 months later makes me realize i was a dumbass -Dys 2026
            local Size = TextService:GetTextSize(BarButton.Title.Holder.Label.Text, OriginalYLabelBound, BarButton.Title.Holder.Label.Font, BarButton.Title.Holder.Label.AbsoluteSize)
            TweenService:Create(BarButton.Title.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.15, Size.X + 56, 0.5, 0)
            }):Play()
        end
        BarButton.MouseEnter:Connect(Hover)
        BarButton.Button.SelectionGained:Connect(Hover)
        BarButton.MouseLeave:Connect(function()
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            TweenService:Create(BarButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = OriginalSize}):Play()
            TweenService:Create(BarButton.Title.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0.5, 0)
            }):Play()
        end)

        Utils.Character.ObserveCharacter(LocalPlayer, function(char: Model)
            if not Menu.UIInstance then
                return
            end
            Menu.Toggle(char:FindFirstChild("Role").Value == "Spectator")
        end)
    end

    Utils.Character.ObserveCharacter(LocalPlayer, function(char: Model)
        SideBar.Toggle(char:FindFirstChild("Role").Value == "Spectator")
    end)
end

return SideBar
