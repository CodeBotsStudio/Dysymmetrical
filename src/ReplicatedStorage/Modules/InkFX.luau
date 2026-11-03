--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local InkFX = {}

local InkVeilImage = "rbxassetid://94299335585756"
local InkRingImage = "rbxassetid://106770110603452"
local InkDiscImage = "rbxassetid://77200941814063"

function InkFX.Calm(): boolean
    return Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer, "Customization.ScreenShakeEnabled") == false
end

function InkFX.Ripple(Host: GuiObject, Grow: number, Duration: number, ZIndex: number?)
    if InkFX.Calm() then
        return
    end
    for Index, Delay in {0, 0.07} do
        local Ring = Instance.new("ImageLabel")
        Ring.Image = InkRingImage
        Ring.AnchorPoint = Vector2.new(0.5, 0.5)
        Ring.Position = UDim2.fromScale(0.5, 0.5)
        Ring.Size = UDim2.fromScale(0.95, 0.95)
        Ring.Rotation = math.random(0, 360)
        Ring.BackgroundTransparency = 1
        Ring.ImageTransparency = 0.1 + Index * 0.25
        Ring.ZIndex = ZIndex or 6
        Ring.SizeConstraint = Enum.SizeConstraint.RelativeYY
        Ring.Parent = Host
        local Info = TweenInfo.new(Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, Delay)
        TweenService:Create(Ring, Info, {Size = UDim2.fromScale(Grow, Grow), Rotation = Ring.Rotation + 40, ImageTransparency = 1}):Play()
        task.delay(Duration + Delay, Ring.Destroy, Ring)
    end
end

function InkFX.Reveal(Menu: GuiObject?, Closing: boolean)
    if not Menu or not Menu:IsA("GuiObject") or InkFX.Calm() then
        return
    end
    local Clip = Instance.new("Frame")
    Clip.Name = "InkVeil"
    Clip.Size = UDim2.fromScale(1, 1)
    Clip.BackgroundTransparency = 1
    Clip.ClipsDescendants = true
    Clip.ZIndex = 50
    local Veil = Instance.new("ImageLabel")
    Veil.Image = InkVeilImage
    Veil.BackgroundTransparency = 1
    Veil.ScaleType = Enum.ScaleType.Stretch
    Veil.Size = UDim2.fromScale(2, 1)
    Veil.Position = UDim2.fromScale(if Closing then 0 else -1, 0)
    Veil.ZIndex = 50
    Veil.Parent = Clip
    Clip.Parent = Menu
    local Duration = if Closing then 0.3 else 0.5
    local Style = if Closing then Enum.EasingDirection.In else Enum.EasingDirection.Out
    TweenService:Create(Veil, TweenInfo.new(Duration, Enum.EasingStyle.Sine, Style), {Position = UDim2.fromScale(if Closing then -1 else 0, 0)}):Play()
    task.delay(Duration, Clip.Destroy, Clip)
    if not Closing and not Menu:FindFirstChildOfClass("UIScale") then
        local Settle = Instance.new("UIScale")
        Settle.Scale = 0.96
        Settle.Parent = Menu
        TweenService:Create(Settle, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        task.delay(0.55, Settle.Destroy, Settle)
    end
end

function InkFX.Pop(Host: GuiObject, From: number, Duration: number, Delay: number?)
    if InkFX.Calm() then
        return
    end
    local Scale = Host:FindFirstChildOfClass("UIScale")
    if not Scale then
        Scale = Instance.new("UIScale")
        Scale:SetAttribute("Rest", 1)
        Scale.Parent = Host
    end
    local Rest = Scale:GetAttribute("Rest") or Scale.Scale
    Scale:SetAttribute("Rest", Rest)
    Scale.Scale = From * Rest
    TweenService:Create(Scale, TweenInfo.new(Duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, Delay or 0), {Scale = Rest}):Play()
end

function InkFX.Drain(Host: GuiObject, Seconds: number)
    local Icon = Host:FindFirstChild("ImageLabel")
    if not Icon or not Icon:IsA("ImageLabel") then
        return
    end
    local Old = Icon:FindFirstChild("InkDrain")
    if Old then
        Old:Destroy()
    end
    local Ink = Instance.new("ImageLabel")
    Ink.Name = "InkDrain"
    Ink.Image = InkDiscImage
    Ink.ImageTransparency = 0.25
    Ink.BackgroundTransparency = 1
    Ink.AnchorPoint = Vector2.new(0.5, 0.5)
    Ink.Position = UDim2.fromScale(0.5, 0.5)
    Ink.Size = UDim2.fromScale(1, 1)
    Ink.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Ink.ZIndex = Icon.ZIndex + 1
    Ink.Parent = Icon
    local Tween = TweenService:Create(Ink, TweenInfo.new(Seconds, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 0), Rotation = 90})
    Tween.Completed:Once(function(State: Enum.PlaybackState)
        Ink:Destroy()
        if State == Enum.PlaybackState.Completed and Host.Parent then
            InkFX.Ripple(Host, 1.5, 0.5)
            InkFX.Pop(Host, 1.12, 0.35)
        end
    end)
    Tween:Play()
end

return InkFX
