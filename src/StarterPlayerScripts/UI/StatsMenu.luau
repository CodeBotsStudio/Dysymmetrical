local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local StatsMenu = {
    Opened = false,
    Enabled = true,
    UIInstance = nil,
}

local Prefabs = {
    Section = script.Prefabs.Section,
    Stat = script.Prefabs.Stat,
}

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

function StatsMenu:Init()
    if self.UIInstance then
        self.UIInstance.Parent = UIParent
        self.UIInstance.Size = Utils.UDim.Zero
        self.UIInstance.Visible = false
        return
    end

    local UI = script.StatsMenu
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    UI.Parent = UIParent
    self.UIInstance = UI
    local Content = UI.StatsContainer.Content

    local CurrentLayoutOrder = 0
    
    local Folders = Utils:FindFirstChild(LocalPlayer, "PlayerData.Stats"):GetChildren()

    table.sort(Folders, function(a, b)
        return a:GetAttribute("LayoutOrder") < b:GetAttribute("LayoutOrder")
    end)

    for _, StatFolder in ipairs(Folders) do
        CurrentLayoutOrder += 1

        local Section = Prefabs.Section:Clone()
        Section.Name = StatFolder.Name
        Section.TextLabel.Text = StatFolder:GetAttribute("DisplayTitle")
        Section.LayoutOrder = CurrentLayoutOrder

        local StatsInSection = StatFolder:GetChildren()

        table.sort(StatsInSection, function(a, b)
            return a:GetAttribute("LayoutOrder") < b:GetAttribute("LayoutOrder")
        end)

        for _, StatValue in StatsInSection do
            CurrentLayoutOrder += 1
            
            local Stat = Prefabs.Stat:Clone()
            Stat.Name = StatValue.Name

            local DisplayTitle = StatValue:GetAttribute("DisplayTitle")

            if StatValue:GetAttribute("PostDisplayTitle") ~= nil then
                DisplayTitle = DisplayTitle.." ("..StatValue:GetAttribute("PostDisplayTitle")..")"
            end

            Stat.Text = DisplayTitle..": "

            if StatValue:GetAttribute("FormatTime") == true then
                Stat.Text = Stat.Text..Utils:ConvertToDHMS(StatValue.Value)
            else
                Stat.Text = Stat.Text..tostring(StatValue.Value)
            end

            Stat.LayoutOrder = CurrentLayoutOrder

            StatValue.Changed:Connect(function(value)
                Stat.Text = DisplayTitle..": "

                local RealValue = StatValue:GetAttribute("FormatTime") == true and Utils:ConvertToDHMS(value) or tostring(value)
                Stat.Text = Stat.Text..RealValue
            end)

            Stat.Parent = Content
        end
        
        Section.Parent = Content
    end

    self.UIInstance:GetPropertyChangedSignal("Size"):Connect(function()
        self.UIInstance.Visible = self.UIInstance.Size ~= Utils.UDim.Zero
    end)
end

function StatsMenu:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Full20Offset}):Play()
    self.Opened = true
    return
end

function StatsMenu:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Opened = false
end

function StatsMenu:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        self.UIInstance.Parent = script
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Enabled = toggle
end

return StatsMenu
