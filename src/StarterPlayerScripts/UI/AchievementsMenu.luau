local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Types = require(ReplicatedStorage.Classes.Types)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local SideBar = require(script.Parent.SideBar)

local LocalPlayer = Players.LocalPlayer

local AchievementsMenu = {
    Enabled = true,
    UIInstance = nil,
    Opened = false,
    Janitor = nil,
}

local AchievementPrefab = Utils.Instance.FindFirstChild(script, "Achievement") :: Frame

local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")
function AchievementsMenu:Init()
    if self.UIInstance then
        self.UIInstance.Parent = UIParent
        self.UIInstance.Size = Utils.UDim.Zero
        self.UIInstance.Visible = false
        return
    end

    self.Janitor = Janitor.new()

    local UI = Utils.Instance.FindFirstChild(script, "Achievements")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    self.UIInstance = UI
    UI.Parent = UIParent

    self.Janitor:LinkToInstance(UI)

    Utils.Instance.ObserveProperty(self.UIInstance, "Size", function(value: UDim2)
        self.UIInstance.Visible = value ~= Utils.UDim.Zero
    end)

    self:_SetupAchievements()
end

function AchievementsMenu:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.4, 0.7)}):Play()
    else
        self.UIInstance.Size = UDim2.fromScale(0.4, 0.7)
    end
    self.Opened = true

    return
end

function AchievementsMenu:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Opened = false
end

function AchievementsMenu:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        self.UIInstance.Parent = script
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Enabled = toggle
end

function AchievementsMenu:_SetupAchievements()
    local Content = self.UIInstance.Content

    for _, AchievementGroup in Utils.Instance.FindFirstChild(LocalPlayer, "PlayerData.Achievements", 5):GetChildren() do
        AchievementGroup = AchievementGroup :: Folder --remove later

        for _, AchievementValue in AchievementGroup:GetChildren() do
            AchievementValue = AchievementValue :: NumberValue | BoolValue --remove later
            local AchievementEquivalent: Types.Achievement = Achievements[AchievementGroup.Name].Achievements[AchievementValue.Name]

            --TODO: implement non-unlocked achievements and headers per group
            local Achievement = AchievementPrefab:Clone()
            Achievement.Name = AchievementValue.Name
            Achievement.Reward.Visible = false

            Achievement.Icon.Image = AchievementEquivalent.Icon or "rbxasset://textures/ui/GuiImagePlaceholder.png"
            Achievement.Content.DisplayName.Text = AchievementEquivalent.Title
            Achievement.Content.Description.Text = AchievementEquivalent.Description

            if not AchievementValue:IsA("NumberValue") then
                Achievement.Content.Requirement:Destroy()
            end

            if AchievementEquivalent.RewardType then
                local Reward = AchievementEquivalent.RewardType == "Currency" and
                    AchievementEquivalent.Amount or
                    (AchievementEquivalent.RewardType == "Skin" and
                        AchievementEquivalent.Skin or
                        AchievementEquivalent.Item
                        )

                local RewardText = AchievementEquivalent.RewardType == "Currency" and "$"..Reward or Reward
                if AchievementEquivalent.RewardType ~= "Currency" then
                    local Suffix = " ("..(AchievementEquivalent.RewardType == "Skin" and tostring(AchievementEquivalent.Item).." Skin" or AchievementEquivalent.RewardType)..")"
                    RewardText = RewardText..Suffix
                end

                Achievement.Reward.Text = "Reward: "..RewardText

                Achievement.MouseEnter:Connect(function()
                    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
                    Achievement.Reward.Visible = true
                end)
                Achievement.MouseLeave:Connect(function()
                    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
                    Achievement.Reward.Visible = false
                end)
            end

            Achievement.Parent = Content
        end
    end
end

return AchievementsMenu
