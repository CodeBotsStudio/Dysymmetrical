local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

local LocalPlayer = Players.LocalPlayer

local CreditsMenu = {
    Enabled = true,
    UIInstance = nil,
}

type Credit = {
    Render: string,
    DisplayName: string,
    Username: string,
    Description: string,
}
local Credits: {{ Name: string, Credits: {Credit} }} = {
    {
        Name = "Dysymmetrical",
        Credits = {
            {
                Render = "rbxassetid://74795618506491",
                DisplayName = "Dyscarn",
                Username = "@LrgeAlvaro8882",
                Description = "Made the engine used in this game: Dysymmetrical.",
            },
        },
    },
}

local UIParent = CommonUtils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")
function CreditsMenu:Init()
    if self.UIInstance then
        self.UIInstance.Parent = UIParent
        self.UIInstance.Size = CommonUtils.UDim.Zero
        return
    end

    local UI = CommonUtils:FindFirstChild(script, "CreditsMenu")
    UI.Size = CommonUtils.UDim.Zero
    self.UIInstance = UI
    UI.Parent = UIParent

    local Prefabs = {
        Section = CommonUtils:FindFirstChild(script, "SectionLabel"),
        Credit = CommonUtils:FindFirstChild(script, "Credit"),
    }

    local LO = 0
    --using ipairs instead of nothing to make sure that it's ordered
    for _, CreditsSection: {Name: string, Credits: {Credit}} in ipairs(Credits) do
        LO += 1

        local SectionPrefab = Prefabs.Section:Clone()
        SectionPrefab.Name = CreditsSection.Name.."Section"
        SectionPrefab.SectionName.Text = CreditsSection.Name
        SectionPrefab.LayoutOrder = LO
        SectionPrefab.Parent = UI.Content

        for _, Credit: Credit in ipairs(CreditsSection.Credits) do
            LO += 1

            local CreditPrefab = Prefabs.Credit:Clone()
            CreditPrefab.Name = Credit.Username.."Credit"
            CreditPrefab.DisplayName.Text = Credit.DisplayName
            CreditPrefab.Username.Text = Credit.Username
            CreditPrefab.Portrait.Image = Credit.Render or "rbxasset://textures/ui/GuiImagePlaceholder.png"
            CreditPrefab.Description.Text = Credit.Description

            CreditPrefab.LayoutOrder = LO
            CreditPrefab.Parent = UI.Content
        end
    end
end

function CreditsMenu:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return
    end
    task.spawn(function()
        SideBar:CloseAll(self)
    end)

    TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.475, 0.599)}):Play()
    self.Opened = true
end

function CreditsMenu:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = CommonUtils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = CommonUtils.UDim.Zero
    end
    self.Opened = false
end

function CreditsMenu:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        self.UIInstance.Parent = script
        self.UIInstance.Size = CommonUtils.UDim.Zero
    end
    self.Enabled = toggle
end

return CreditsMenu
