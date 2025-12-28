--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Mouse = LocalPlayer:GetMouse()
local InputManager = require(LocalPlayer.PlayerScripts.InputManager)
local Utils = require(ReplicatedStorage.Modules.Utils)
local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)

local EmotePanel = {
    Open = false,
    TopbarButton = nil,
}

local UI
local UISize = UDim2.fromScale(0.3, 0.533)

function EmotePanel:Init()
    local ScreenGui = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "EmotePanel")

    UI = Utils.Instance.FindFirstChild(script, "EmotePanel")
    UI.Parent = ScreenGui

    local Selector = Utils.Instance.FindFirstChild(UI, "Selector")
    local EmoteButtonContainer = Utils.Instance.FindFirstChild(UI, "EmoteContainer")

    local SelectedEmote = ""

    local function CheckEmotePlay()
        if not self.Open then
            return
        end
        self:_Close()

        local EmoteToPlay = EmoteButtonContainer[SelectedEmote]:GetAttribute("Name")
        if LocalPlayer.Character and EmoteToPlay and #EmoteToPlay > 0 then
            local E = Utils.Instance.FindFirstChild(LocalPlayer.Character, "Miscellaneous.EmoteManager", 0)
            if not E then
                return
            end
            local EmoteManager = require(E)
            if EmoteManager.CurrentlyPlayingEmote and EmoteManager.CurrentlyPlayingEmote.Name == EmoteToPlay then return end
            EmoteManager:PlayEmote(EmoteToPlay)
        end
    end

    local function ReloadContent()
        for _, EmoteSlot in EmoteButtonContainer:GetChildren() do
            local EquippedEmote = Utils.PlayerData.GetPlayerEquipped(LocalPlayer, "Emotes."..EmoteSlot.Name)
            local EmoteModule = EquippedEmote and #EquippedEmote > 0 and Utils.Instance.GetEmoteModule(EquippedEmote)
            if EmoteModule then
                EmoteSlot:SetAttribute("Name", EquippedEmote)
                EmoteModule = require(EmoteModule)
                EmoteSlot:SetAttribute("DisplayName", EmoteModule.Config.Name)

                EmoteSlot.Render.Image = EmoteModule.Config.Render
                EmoteSlot.NameLabel.Text = EmoteModule.Config.Name

                EmoteSlot.Render.ImageTransparency = 0
                EmoteSlot.NameLabel.TextTransparency = 0
            else
                EmoteSlot:SetAttribute("Name", "")
                EmoteSlot:SetAttribute("DisplayName", "")
                EmoteSlot.Render.ImageTransparency = 1
                EmoteSlot.NameLabel.TextTransparency = 1
            end
        end
    end

    ReloadContent()
    for _, Emote in Utils.PlayerData.GetPlayerEquipped(LocalPlayer, "Emotes", false):GetChildren() do
        Emote.Changed:Connect(ReloadContent)
    end

    RunService.PreRender:Connect(function()
        UI.Visible = UI.Size ~= Utils.UDim.Zero
        if not UI.Visible then
            return
        end

        local CenterOfScreen = ScreenGui.AbsoluteSize / 2
        local MousePosition = Vector2.new(Mouse.X, Mouse.Y) - CenterOfScreen

        local CurrentRotation = math.deg(math.atan2(MousePosition.Y, MousePosition.X)) + 180

        Selector.Rotation = CurrentRotation - 90

        SelectedEmote = "Emote"..tostring(math.clamp(math.floor((CurrentRotation) / 45) + 1, 1, 8))
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

    local function CheckMobileButton(ControlScheme: "Keyboard" | "Gamepad" | "Touch")
        if ControlScheme == "Touch" and not self.TopbarButton then
            self.TopbarButton = TopbarPlus.new()
            self.TopbarButton:setOrder(10)
            self.TopbarButton:oneClick(true)
            self.TopbarButton:setLabel("Emote")
            self.TopbarButton:setTextFont(Enum.Font.Bodoni)
            self.TopbarButton:bindEvent("deselected", function()
                if not LocalPlayer.Character then
                    self:Toggle()
                    return
                end

                local E = Utils.Instance.FindFirstChild(LocalPlayer.Character, "Miscellaneous.EmoteManager", 0)
                if not E then
                    return
                end
                local EmoteManager = require(E)
                
                if EmoteManager.CurrentlyPlayingEmote then
                    EmoteManager:StopEmote(EmoteManager.CurrentlyPlayingEmote)
                else
                    self:Toggle()
                end
            end)
        elseif self.TopbarButton then
            self.TopbarButton:Destroy()
        end
    end

    InputManager.SchemeChanged:Connect(CheckMobileButton)
    CheckMobileButton(InputManager.CurrentControlScheme)
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
    TweenService:Create(UI, Info, {Size = Utils.UDim.Zero}):Play()
end

return EmotePanel
