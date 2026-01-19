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

local PrefabFolder = Utils.Instance.FindFirstChild(script, "Prefabs")
local Prefabs = {
    Separator = Utils.Instance.FindFirstChild(PrefabFolder, "Separator"),
    SectionEntry = Utils.Instance.FindFirstChild(PrefabFolder, "SectionEntry"),
    Text = Utils.Instance.FindFirstChild(PrefabFolder, "PlainText"),
}

local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")
function Rules:Init()
    if Rules.UIInstance then
        Rules.UIInstance.Parent = UIParent
        Rules.UIInstance.Size = Utils.UDim.Zero
        Rules.UIInstance.Visible = false
        return
    end

    local UI = Utils.Instance.FindFirstChild(script, "Rules")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    Rules.UIInstance = UI
    UI.Parent = UIParent

    local Content = UI.Content

    Utils.Instance.ObserveProperty(Rules.UIInstance, "Size", function(value: UDim2)
        Rules.UIInstance.Visible = value ~= Utils.UDim.Zero
    end)

    for order, entry in Ruleset do
        local Inst = Prefabs[entry.Type]:Clone()
        Inst.Title.Text = entry.Text
        Inst.LayoutOrder = order
        Inst.Parent = Content
    end
end

function Rules.Open(Time: number)
    if not Rules.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    if Time > 0 then
        TweenService:Create(Rules.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.4, 0.7)}):Play()
    else
        Rules.UIInstance.Size = UDim2.fromScale(0.4, 0.7)
    end
    Rules.Opened = true

    return
end

function Rules.Close(Time: number)
    if Time > 0 then
        TweenService:Create(Rules.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        Rules.UIInstance.Size = Utils.UDim.Zero
    end
    Rules.Opened = false
end

function Rules.Toggle(toggle: boolean)
    if not Rules.Enabled and toggle then
        Rules:Init()
    end
    if not toggle and Rules.Enabled then
        Rules.UIInstance.Parent = script
        Rules.UIInstance.Size = Utils.UDim.Zero
    end
    Rules.Enabled = toggle
end

return Rules
