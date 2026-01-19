local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)
local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)

local LocalPlayer = Players.LocalPlayer

local ModPanel = {
    Rank = 9999,
    Enabled = true,
    CloseOnOtherOpen = true,
    CloseOthersOnOpen = true,
    UIInstance = nil,
    Opened = false,
    Initted = false,
}

local CommandOrder = {
    "ToggleFreezeTime",
    "ToggleAbilityCooldowns",
    "ToggleAbilityCharges",
}

local Prefabs = {
    Bool = require(Utils.Instance.FindFirstChild(script, "Bool")),
}

function ModPanel:Init()
    if ModPanel.Initted then
        return
    end

    local HasRank, Rank = Network:FireServerConnection("HasPermRank", "REMOTE_FUNCTION", "ServerOwner")
    if not HasRank then
        return
    end

    ModPanel.Rank = Rank

    ModPanel.Start()
    ModPanel.Initted = true
end

function ModPanel.Start()
    local UI = Utils.Instance.FindFirstChild(script, "ModPanel")
    UI.Parent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    ModPanel.UIInstance = UI

    local TopbarButton = TopbarPlus.new()
    TopbarButton:setOrder(0)
    TopbarButton:oneClick(true)
    TopbarButton:setLabel("Command Panel")
    TopbarButton:setTextFont(Enum.Font.Bodoni)
    TopbarButton:bindEvent("deselected", function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        if ModPanel.Opened then
            ModPanel.Close(SideBar.ToggleDuration)
        else
            ModPanel.Open(SideBar.ToggleDuration)
        end
    end)

    SideBar.MenuModules["ModPanel"] = ModPanel

    Utils.Instance.ObserveProperty(UI, "Size", function(value: UDim2)
        UI.Visible = value ~= Utils.UDim.Zero
    end)

    local LO = 0
    local function SetupCmd(Cmd)
        if not Cmd or not Cmd:IsA("ModuleScript") then
            return
        end

        local Command = require(Cmd)
        Command.RankRequired = Command.RankRequired or Utils.Ranks.ServerOwner

        if ModPanel.Rank > Command.RankRequired or not Command.Type or not Prefabs[Command.Type] then
            return
        end

        LO += 1

        local Content = Prefabs[Command.Type].New(Cmd, UI)
        Content.LayoutOrder = LO
    end

    for _, Command in CommandOrder do
        SetupCmd(ReplicatedStorage.Security.ModeratorCommands:FindFirstChild(Command))
    end

    for _, Command in ReplicatedStorage.Security.ModeratorCommands:GetChildren() do
        if table.find(CommandOrder, Command.Name) then
            continue
        end

        SetupCmd(Command)
    end
end

function ModPanel.Open(Time: number)
    if not ModPanel.Enabled then
        return "Prevented"
    end

    SideBar.CloseAll(ModPanel)

    if Time > 0 then
        TweenService:Create(ModPanel.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.542, 0.741)}):Play()
    else
        ModPanel.UIInstance.Size = UDim2.fromScale(0.4, 0.7)
    end
    ModPanel.Opened = true

    return
end

function ModPanel.Close(Time: number)
    if Time > 0 then
        TweenService:Create(ModPanel.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        ModPanel.UIInstance.Size = Utils.UDim.Zero
    end
    ModPanel.Opened = false
end

function ModPanel:Toggle()
end

return ModPanel
