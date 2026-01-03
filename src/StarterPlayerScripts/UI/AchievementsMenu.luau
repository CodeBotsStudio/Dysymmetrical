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
    Defaults = {
        Shown = {
            Title = "Achievement Name",
            Description = "Achievement Description",
            Icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        },
        Hidden = {
            Title = "?????",
            Description = "????????????????????",
            Icon = "rbxassetid://15117261700",
        },
    },
}

local AchievementPrefab = Utils.Instance.FindFirstChild(script, "Achievement") :: Frame
local CategoryPrefab = Utils.Instance.FindFirstChild(script, "Category") :: Frame

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
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.5, 0.7)}):Play()
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

--TODO: implement section buttons on the left to only show certain sections
function AchievementsMenu:_SetupAchievements()
    local Content = self.UIInstance.Content

    local AchievementGroupLayoutOrder = 0

    local AchievementGroups = Utils.Instance.FindFirstChild(LocalPlayer, "PlayerData.Achievements", 5):GetChildren()
    table.sort(AchievementGroups, function(a: Folder, b: Folder)
        local aEquivalent = Achievements[a.Name]
        local bEquivalent = Achievements[b.Name]

        return aEquivalent.LayoutOrder < bEquivalent.LayoutOrder
    end)

    for _, AchievementGroup in AchievementGroups do
        AchievementGroup = AchievementGroup :: Folder --remove later
        local AchievementGroupEquivalent = Achievements[AchievementGroup.Name]

        AchievementGroupLayoutOrder += 1

        local Category = CategoryPrefab:Clone()
        Category.Name = AchievementGroup.Name
        Category.CategoryLabel.Label.Text = AchievementGroupEquivalent.Title
        Category.LayoutOrder = AchievementGroupLayoutOrder
        Category.Parent = Content

        local AchievementsInThisGroup = AchievementGroup:GetChildren()
        table.sort(AchievementsInThisGroup, function(a: NumberValue | BoolValue, b: NumberValue | BoolValue)
            local aEquivalent = AchievementGroupEquivalent.Achievements[a.Name]
            local bEquivalent = AchievementGroupEquivalent.Achievements[b.Name]

            return aEquivalent.LayoutOrder < bEquivalent.LayoutOrder
        end)

        local AchievementLayoutOrder = 0

        for _, AchievementValue in AchievementGroup:GetChildren() do
            AchievementValue = AchievementValue :: NumberValue | BoolValue --remove later
            local AchievementEquivalent: Types.Achievement = AchievementGroupEquivalent.Achievements[AchievementValue.Name]

            AchievementLayoutOrder += 1

            local Achievement = AchievementPrefab:Clone()
            Achievement.Name = AchievementValue.Name
            Achievement.Reward.Visible = false
            Achievement.LayoutOrder = AchievementLayoutOrder

            --making this a function to let it update
            local function Unlocked(): boolean
                return if AchievementEquivalent.Requirement ~= nil then AchievementValue.Value >= AchievementEquivalent.Requirement else AchievementValue.Value
            end

            if not Unlocked() then
                Achievement.LockedOverlay.Visible = true

                if AchievementEquivalent.HideTitleIfLocked then
                    Achievement.Content.DisplayName.Text = AchievementEquivalent.HiddenTitle or self.Defaults.Hidden.Title
                end
                if AchievementEquivalent.HideDescriptionIfLocked then
                    Achievement.Content.Description.Text = AchievementEquivalent.HiddenDescription or self.Defaults.Hidden.Description
                end
                if AchievementEquivalent.HideIconIfLocked then
                    Achievement.Icon.Image = AchievementEquivalent.LockIcon or self.Defaults.Hidden.Icon
                end

                if AchievementEquivalent.Hide then
                    Achievement.Visible = false
                end
            else
                Achievement.LockedOverlay.Visible = false
                Achievement.Visible = true
                
                Achievement.Content.DisplayName.Text = AchievementEquivalent.Title or self.Defaults.Shown.Title
                Achievement.Content.Description.Text = AchievementEquivalent.Description or self.Defaults.Shown.Description
                Achievement.Icon.Image = AchievementEquivalent.Icon or self.Defaults.Shown.Icon
            end

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
                    if AchievementEquivalent.HideRewardIfLocked and not Unlocked() then
                        return
                    end

                    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
                    Achievement.Reward.Visible = true
                end)
                Achievement.MouseLeave:Connect(function()
                    if AchievementEquivalent.HideRewardIfLocked and not Unlocked() then
                        return
                    end

                    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
                    Achievement.Reward.Visible = false
                end)
            end

            Achievement.Parent = Category
        end
    end
end

return AchievementsMenu
