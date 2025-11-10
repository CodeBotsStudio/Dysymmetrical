local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = game:GetService("Players").LocalPlayer

local Settings = {
    Opened = false,
    Enabled = true,
    UIInstance = nil,
}

local Classes = {
    Bool = require(Utils:FindFirstChild(script, "Bool")),
    Number = require(Utils:FindFirstChild(script, "Number")),
    String = require(Utils:FindFirstChild(script, "String")),
}
local Prefabs = {
    UIPrefab = Utils:FindFirstChild(script, "SettingsScreen"),
    Section = Utils:FindFirstChild(script, "Section"),
}

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

function Settings:Init()
    if self.UIInstance then
        self.UIInstance.Parent = UIParent
        self.UIInstance.Size = Utils.UDim.Zero
        self.UIInstance.Visible = false
        return
    end

    local UI = Prefabs.UIPrefab
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    UI.Parent = UIParent
    self.UIInstance = UI
    local Content = UI.SettingsContainer.Contents

    local CurrentLayoutOrder = 0
    
    local Folders = Players.LocalPlayer.PlayerData.Settings:GetChildren()

    table.sort(Folders, function(a, b)
        return a:GetAttribute("LayoutOrder") < b:GetAttribute("LayoutOrder")
    end)

    for _, SettingFolder in Folders do
        CurrentLayoutOrder += 1
        local SettingSection = Prefabs.Section:Clone()
        SettingSection.Name = SettingFolder.Name.."Section"
        SettingSection.TextLabel.Text = SettingFolder.Name
        SettingSection.LayoutOrder = CurrentLayoutOrder

        local SettingsInSection = {}
        for _, Setting in SettingFolder:GetChildren() do
            local Type = nil --gets type of setting
            if Setting:IsA("BoolValue") then
                Type = "Bool"
            elseif Setting:IsA("NumberValue") then
                Type = "Number"
            elseif Setting:IsA("StringValue") then
                Type = "String"
            else
                warn("what setting even is this?")
            end

            --indexes it to a table in order to sort it later
            table.insert(SettingsInSection, {
                Instance = Setting,
                LayoutOrder = Setting:GetAttribute("LayoutOrder"),
                Type = Type,
            })
        end
        --sorts by LayoutOrder
        table.sort(SettingsInSection, function(a, b)
            return a.LayoutOrder < b.LayoutOrder
        end)

        for _, Setting in ipairs(SettingsInSection) do
            CurrentLayoutOrder += 1

            local Callback = nil
            if script.Connections:FindFirstChild(Setting.Instance.Name) then
                Callback = require(script.Connections:FindFirstChild(Setting.Instance.Name))
            end

            local Inst = Classes[Setting.Type]:New(Setting.Instance, nil, Callback)
            local ActualInst = Inst.Instance
            ActualInst.LayoutOrder = CurrentLayoutOrder
            ActualInst.Name = Setting.Instance.Name

            ActualInst.SettingName.Text = Setting.Instance:GetAttribute("DisplayTitle") or ActualInst.SettingName.Text
            ActualInst.SettingDesc.Text = Setting.Instance:GetAttribute("DisplayDescription") or ActualInst.SettingDesc.Text

            if Callback then
                task.spawn(Callback, Inst.SettingValue.Value)
            end

            ActualInst.Parent = Content
        end

        SettingSection.Parent = Content
    end

    self.UIInstance:GetPropertyChangedSignal("Size"):Connect(function()
        self.UIInstance.Visible = self.UIInstance.Size ~= Utils.UDim.Zero
    end)
end

function Settings:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Full20Offset}):Play()
    self.Opened = true

    return
end

function Settings:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = Utils.UDim.Zero
        self.UIInstance.Visible = false
    end
    self.Opened = false
end

function Settings:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        self.UIInstance.Parent = script
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Enabled = toggle
end

return Settings
