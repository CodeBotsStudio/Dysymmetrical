--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Mouse = LocalPlayer:GetMouse()
local InputManager = require(LocalPlayer.PlayerScripts.InputManager)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

local EmotePanel = {
    Open = false,

    EmoteSpaces = {},
}

local UI
local UISize = UDim2.fromScale(0.407, 0.723)

function EmotePanel:Init()
    local ScreenGui = CommonUtils:FindFirstChild(LocalPlayer.PlayerGui, "EmotePanel")

    UI = CommonUtils:FindFirstChild(script, "EmotePanel")
    UI.Parent = ScreenGui

    local Selector = CommonUtils:FindFirstChild(UI, "Selector")
    local EmoteButtonContainer = CommonUtils:FindFirstChild(UI, "EmoteContainer")

    local SelectedEmote = ""

    local function CheckEmotePlay()
        if not self.Open then
            return
        end
        self:_Close()

        local EmoteToPlay = EmoteButtonContainer[SelectedEmote]:GetAttribute("Name")
        if LocalPlayer.Character and EmoteToPlay and #EmoteToPlay > 0 then
            local EmoteManager = require(CommonUtils:FindFirstChild(LocalPlayer.Character, "Miscellaneous.EmoteManager"))
            if EmoteManager.CurrentlyPlayingEmote and EmoteManager.CurrentlyPlayingEmote.Name == EmoteToPlay then return end
            EmoteManager:PlayEmote(EmoteToPlay)
        end
    end

    local function ReloadContent()
        for _, i in EmoteButtonContainer:GetChildren() do
            local EquippedEmote = CommonUtils:GetPlayerEquipped(LocalPlayer, "Emotes."..i.Name)
            local EmoteModule = EquippedEmote and #EquippedEmote > 0 and CommonUtils:GetEmoteModule(EquippedEmote)
            if EmoteModule then
                i:SetAttribute("Name", EquippedEmote)
                EmoteModule = require(EmoteModule)
                i:SetAttribute("DisplayName", EmoteModule.Config.Name)

                i.Render.Image = EmoteModule.Config.Render
                i.NameLabel.Text = EmoteModule.Config.Name

                i.Render.ImageTransparency = 0
                i.NameLabel.TextTransparency = 0
            else
                i:SetAttribute("Name", "")
                i:SetAttribute("DisplayName", "")
                i.Render.ImageTransparency = 1
                i.NameLabel.TextTransparency = 1
            end
        end
    end

    ReloadContent()
    for _, i in CommonUtils:GetPlayerEquipped(LocalPlayer, "Emotes", false):GetChildren() do
        i.Changed:Connect(ReloadContent)
    end

    RunService.PreRender:Connect(function()
        local CenterOfScreen = ScreenGui.AbsoluteSize / 2
        local MousePosition = Vector2.new(Mouse.X, Mouse.Y) - CenterOfScreen

        local CurrentRotation = math.deg(math.atan2(MousePosition.Y, MousePosition.X))

        Selector.Rotation = CurrentRotation + 90

        CurrentRotation += 180 --for selecting an emote properly

        SelectedEmote = "Emote"..tostring(math.floor((CurrentRotation) / 45) + 1)
        UI.Selected.Text = EmoteButtonContainer[SelectedEmote]:GetAttribute("DisplayName")
    end)

    UserInputService.InputBegan:Connect(function(Input: InputObject, GPE: boolean)
        if GPE then
            return
        end

        if InputManager.CurrentControlScheme == "Gamepad" then
            if Input.KeyCode == Enum.KeyCode.ButtonR2 then
                CheckEmotePlay()
            end
        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            CheckEmotePlay()
        end
    end)

    InputManager.Miscellaneous.EmotePanel.Pressed:Connect(function()
        self:Toggle()
    end)
end

function EmotePanel:Toggle()
    if not self.Open then
        self:_Open()
    else
        self:_Close()
    end
end

local Info = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

function EmotePanel:_Open()
    TweenService:Create(UI, Info, {Size = UISize}):Play()
    self.Open = true
end

function EmotePanel:_Close()
    self.Open = false
    TweenService:Create(UI, Info, {Size = CommonUtils.UDim.Zero}):Play()
end

return EmotePanel
