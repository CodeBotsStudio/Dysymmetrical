--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local InkFX = {}

local InkVeilImage = "rbxassetid://118511292501872"
local InkRingImage = "rbxassetid://116404627712698"
local InkDiscImage = "rbxassetid://121024594981035"
local InkStrokeImage = "rbxassetid://125872915180924"

function InkFX.Calm(): boolean
    return Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer, "Customization.ScreenShakeEnabled") == false
end

local Layers: {[string]: Frame} = {}
local function Layer(Host: GuiObject, Name: string, ZIndex: number): Frame?
    local Gui = Host:FindFirstAncestorWhichIsA("ScreenGui")
    if not Gui then
        return nil
    end
    local Key = Gui:GetFullName() .. Name
    local Found = Layers[Key]
    if not Found or not Found.Parent then
        Found = Instance.new("Frame")
        Found.Name = Name
        Found.Size = UDim2.fromScale(1, 1)
        Found.BackgroundTransparency = 1
        Found.ZIndex = ZIndex
        Found.Parent = Gui
        Layers[Key] = Found
    end
    return Found
end

function InkFX.Ripple(Host: GuiObject, Grow: number, Duration: number)
    local Layer = Layer(Host, "InkLayer", 0)
    if InkFX.Calm() or not Layer then
        return
    end
    local Size = Host.AbsoluteSize
    local Center = Host.AbsolutePosition + Size / 2 - Layer.AbsolutePosition
    if Size.X > Size.Y * 1.6 then
        local Below = if Host.BackgroundTransparency < 1 then Size.Y * 0.5 + 6 else Size.Y * 0.42
        local Stroke = Instance.new("ImageLabel")
        Stroke.Image = InkStrokeImage
        Stroke.BackgroundTransparency = 1
        Stroke.ImageTransparency = 0.15
        Stroke.AnchorPoint = Vector2.new(0, 0.5)
        Stroke.Position = UDim2.fromOffset(Center.X - Size.X * 0.55, Center.Y + Below)
        Stroke.Size = UDim2.fromOffset(0, math.min(Size.Y * 0.3, 14))
        Stroke.Parent = Layer
        TweenService:Create(Stroke, TweenInfo.new(Duration * 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(Size.X * 1.1, Stroke.Size.Y.Offset)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(Duration * 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, Duration * 0.4), {ImageTransparency = 1}):Play()
        task.delay(Duration, Stroke.Destroy, Stroke)
        return
    end
    for Index, Delay in {0, 0.07} do
        local Ring = Instance.new("ImageLabel")
        Ring.Image = InkRingImage
        Ring.BackgroundTransparency = 1
        Ring.ImageTransparency = 0.1 + Index * 0.25
        Ring.AnchorPoint = Vector2.new(0.5, 0.5)
        Ring.Position = UDim2.fromOffset(Center.X, Center.Y)
        Ring.Size = UDim2.fromOffset(Size.Y * 0.95, Size.Y * 0.95)
        Ring.Rotation = math.random(0, 360)
        Ring.Parent = Layer
        local Info = TweenInfo.new(Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, Delay)
        TweenService:Create(Ring, Info, {Size = UDim2.fromOffset(Size.Y * Grow, Size.Y * Grow), Rotation = Ring.Rotation + 40, ImageTransparency = 1}):Play()
        task.delay(Duration + Delay, Ring.Destroy, Ring)
    end
end

local function Bounds(Menu: GuiObject): (Vector2, Vector2)
    local Min, Max = Menu.AbsolutePosition + Menu.AbsoluteSize, Menu.AbsolutePosition
    local Items: {GuiObject} = if Menu:FindFirstChildOfClass("UIAspectRatioConstraint") then {Menu} else {}
    for _, Child in Menu:GetChildren() do
        if Child:IsA("GuiObject") and Child.Visible and Child.AbsoluteSize.X > 30 and Child.AbsoluteSize.Y > 30 then
            table.insert(Items, Child)
        end
    end
    for _, Item in Items do
        Min = Min:Min(Item.AbsolutePosition)
        Max = Max:Max(Item.AbsolutePosition + Item.AbsoluteSize)
    end
    return Min, Max - Min
end

local Versions: {[GuiObject]: number} = {}
local Veils: {[GuiObject]: Frame} = {}
function InkFX.Transition(Menu: GuiObject, Opening: boolean, Duration: number, Full: UDim2)
    local Version = (Versions[Menu] or 0) + 1
    Versions[Menu] = Version
    local Previous = Veils[Menu] and Veils[Menu]:FindFirstChildOfClass("ImageLabel")
    local From = Previous and Previous.Position
    if Veils[Menu] then
        Veils[Menu]:Destroy()
        Veils[Menu] = nil
    end
    local Top = Layer(Menu, "InkTop", 100)
    if InkFX.Calm() or Duration <= 0 or not Top then
        Menu.Size = if Opening then Full else UDim2.new()
        return
    end
    Menu.Size = Full
    local Scale = Menu:FindFirstChild("InkScale") :: UIScale? or Instance.new("UIScale")
    Scale.Name = "InkScale"
    Scale.Scale = 1
    Scale.Parent = Menu
    local Position, Size = Bounds(Menu)
    local Clip = Instance.new("Frame")
    Clip.Name = "InkVeil"
    Clip.Position = UDim2.fromOffset(Position.X - Top.AbsolutePosition.X, Position.Y - Top.AbsolutePosition.Y)
    Clip.Size = UDim2.fromOffset(Size.X, Size.Y)
    Clip.BackgroundTransparency = 1
    Clip.ClipsDescendants = true
    local Veil = Instance.new("ImageLabel")
    Veil.Image = InkVeilImage
    Veil.BackgroundTransparency = 1
    Veil.ScaleType = Enum.ScaleType.Stretch
    Veil.Size = UDim2.fromScale(2, 1)
    Veil.Position = From or UDim2.fromScale(if Opening then 0 else -1.15, 0)
    Veil.ImageTransparency = if Opening and not From then 1 else 0
    Veil.Parent = Clip
    Clip.Parent = Top
    Veils[Menu] = Clip
    if Opening and not From then
        Scale.Scale = 0.94
        TweenService:Create(Veil, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
    end
    local Info = TweenInfo.new(Duration, Enum.EasingStyle.Quint, if Opening then Enum.EasingDirection.Out else Enum.EasingDirection.InOut)
    TweenService:Create(Scale, Info, {Scale = if Opening then 1 else 0.97}):Play()
    TweenService:Create(Veil, Info, {Position = UDim2.fromScale(if Opening then -1.15 else 0, 0)}):Play()
    task.delay(Duration, function()
        if Versions[Menu] ~= Version then
            return
        end
        if Opening then
            Clip:Destroy()
            Veils[Menu] = nil
            return
        end
        Menu.Size = UDim2.new()
        Scale.Scale = 1
        TweenService:Create(Veil, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {ImageTransparency = 1}):Play()
        task.delay(0.15, function()
            if Veils[Menu] == Clip then
                Veils[Menu] = nil
            end
            Clip:Destroy()
        end)
    end)
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
