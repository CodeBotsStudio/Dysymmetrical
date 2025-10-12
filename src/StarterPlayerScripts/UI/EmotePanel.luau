--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local EmotePanel = {
    EmoteContainers = {},

    Open = false,
    Debounce = false,
}

local LocalPlayer = game:GetService("Players").LocalPlayer
local EquippedEmotes: Folder

local UI: Frame
local EmotePrefab: Frame

local UISize = UDim2.fromScale(0.75, 0.347)
local UDim2Zero = UDim2.new(0, 0, 0, 0)

function EmotePanel:Init()
    EquippedEmotes = CommonUtils:FindFirstChild(LocalPlayer, "PlayerData.Equipped.Emotes")

    UI = CommonUtils:FindFirstChild(script, "EmotePanel")
    UI.Parent = CommonUtils:FindFirstChild(LocalPlayer.PlayerGui, "EmotePanel")

    EmotePrefab = CommonUtils:FindFirstChild(script, "EmoteContainer")

    self:Reload()

    require(LocalPlayer.PlayerScripts.InputManager).Miscellaneous.EmotePanel.Pressed:Connect(function()
        if not workspace:GetAttribute("ClientLoaded") then return end
        self:_Toggle()
    end)

    EquippedEmotes.DescendantAdded:Connect(function(_descendant: Instance)
        self:Reload()
    end)
    EquippedEmotes.DescendantRemoving:Connect(function(_descendant: Instance)
        self:Reload()
    end)
end

function EmotePanel:_Toggle()
    if self.Debounce then return end
    -- EmotePanel.Debounce = true
    if self.Open then
        self:_Close()
    else
        self:_Open()
    end
end

local Info = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

function EmotePanel:_Open()
    TweenService:Create(UI, Info, {Size = UISize}):Play()
    -- task.wait(Info.Time + 0.2)
    -- EmotePanel.Debounce = false
    self.Open = true
end

function EmotePanel:_Close()
    self.Open = false
    TweenService:Create(UI, Info, {Size = UDim2Zero}):Play()
    -- task.wait(Info.Time + 0.2)
    -- EmotePanel.Debounce = false
end

function EmotePanel:Reload()
    for _, emote in self.EmoteContainers do
        if emote:IsA("Frame") then
            emote:Destroy()
        end
    end

    table.clear(self.EmoteContainers)

    for _, emote in EquippedEmotes:GetChildren() do
        if emote:IsA("IntValue") then
            local index = emote.Value
            if not index or self.EmoteContainers[index] then continue end

            local EmoteInfo = require(CommonUtils:GetEmoteModule(emote.Name))
            
            local NewEmote = EmotePrefab:Clone()
            NewEmote.Name = emote.Name
            NewEmote.Render.Image = EmoteInfo.Config.Render
            NewEmote.EmoteName.Text = EmoteInfo.Config.Name
            self.EmoteContainers[index] = NewEmote
            --NewEmote.Parent = UI

            NewEmote.Interaction.MouseButton1Click:Connect(function()
                if not self.Open then return end
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
                task.defer(function()
                    self:_Close()
                end)

                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Miscellaneous") or not LocalPlayer.Character.Miscellaneous:FindFirstChild("EmoteManager") then
                    return
                end
                
                local EmoteManager = require(LocalPlayer.Character.Miscellaneous.EmoteManager)
                
                if EmoteManager.CurrentlyPlayingEmote and EmoteManager.CurrentlyPlayingEmote.Name == EmoteInfo.Config.Name then return end
                EmoteManager:PlayEmote(emote.Name)
            end)
        end
    end

    for _, emote in self.EmoteContainers do
        emote.Parent = UI
    end
end

return EmotePanel
