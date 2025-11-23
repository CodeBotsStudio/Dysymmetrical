local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local Rules = {
    Enabled = true,
    UIInstance = nil,
    Opened = false,
}

local Ruleset: {{
        Type: "Separator" | "SectionEntry" | "Text",
        Text: string,
    }} = {
    {
        Type = "Separator",
        Text = "Rule section N.º 1",
    },
    {
        Type = "SectionEntry",
        Text = "Pretty cool rule N.º 1!",
    },
    {
        Type = "SectionEntry",
        Text = "Pretty cool feature N.º 2!",
    },
    {
        Type = "Text",
        Text = "Quick note N.º 1!",
    },
    {
        Type = "SectionEntry",
        Text = "Pretty cool rule N.º 3!",
    },
    {
        Type = "Text",
        Text = "Quick note N.º 2!",
    },
    {
        Type = "Separator",
        Text = "Rule section N.º 2",
    },
    {
        Type = "SectionEntry",
        Text = "Pretty cool rule N.º 1!",
    },
    {
        Type = "Text",
        Text = "Quick note N.º 1!",
    },
    {
        Type = "SectionEntry",
        Text = "Pretty cool rule N.º 2!",
    },
    {
        Type = "SectionEntry",
        Text = "Pretty cool rule N.º 3!",
    },
    {
        Type = "Text",
        Text = "Quick note N.º 2!",
    },
}

local PrefabFolder = Utils:FindFirstChild(script, "Prefabs")
local Prefabs = {
    Separator = Utils:FindFirstChild(PrefabFolder, "Separator"),
    SectionEntry = Utils:FindFirstChild(PrefabFolder, "SectionEntry"),
    Text = Utils:FindFirstChild(PrefabFolder, "PlainText"),
}

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")
function Rules:Init()
    if self.UIInstance then
        self.UIInstance.Parent = UIParent
        self.UIInstance.Size = Utils.UDim.Zero
        self.UIInstance.Visible = false
        return
    end

    local UI = Utils:FindFirstChild(script, "Rules")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    self.UIInstance = UI
    UI.Parent = UIParent

    local Content = UI.Content

    self.UIInstance:GetPropertyChangedSignal("Size"):Connect(function()
        self.UIInstance.Visible = self.UIInstance.Size ~= Utils.UDim.Zero
    end)

    for order, entry in Ruleset do
        local Inst = Prefabs[entry.Type]:Clone()
        Inst.Title.Text = entry.Text
        Inst.LayoutOrder = order
        Inst.Parent = Content
    end
end

function Rules:Open(Time: number)
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

function Rules:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Opened = false
end

function Rules:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        self.UIInstance.Parent = script
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Enabled = toggle
end

return Rules
