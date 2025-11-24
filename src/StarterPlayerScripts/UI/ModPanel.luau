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

local PrefabFolder = Utils.Instance.FindFirstChild(script, "Prefabs")
local Prefabs = {
    Bool = Utils.Instance.FindFirstChild(PrefabFolder, "BoolToggle"),
}

function ModPanel:Init()
    if self.Initted then
        return
    end

    local HasRank, Rank = Network:FireServerConnection("HasPermRank", "REMOTE_FUNCTION", "ServerOwner")
    if not HasRank then
        return
    end

    self.Rank = Rank

    self:Start()
    self.Initted = true
end

function ModPanel:Start()
    local UI = Utils.Instance.FindFirstChild(script, "ModPanel")
    UI.Parent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    self.UIInstance = UI

    local TopbarButton = TopbarPlus.new()
    TopbarButton:setOrder(0)
    TopbarButton:oneClick(true)
    TopbarButton:setLabel("Command Panel")
    TopbarButton:setTextFont(Enum.Font.Bodoni)
    TopbarButton:bindEvent("deselected", function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        if self.Opened then
            self:Close(SideBar.ToggleDuration)
        else
            self:Open(SideBar.ToggleDuration)
        end
    end)

    SideBar.MenuModules["ModPanel"] = self

    UI:GetPropertyChangedSignal("Size"):Connect(function()
        UI.Visible = UI.Size ~= Utils.UDim.Zero
    end)

    for _, i in ReplicatedStorage.Security.ModeratorCommands:GetChildren() do
        if not i:IsA("ModuleScript") then
            continue
        end

        local Command = require(i)
        Command.RankRequired = Command.RankRequired or Utils.Ranks.ServerOwner

        if self.Rank > Command.RankRequired or not Command.Type or not Prefabs[Command.Type] then
            continue
        end

        local CommandFrame = Prefabs[Command.Type]:Clone()
        CommandFrame.Parent = UI.Content

        CommandFrame.Label.Text = Command.Name
        CommandFrame.Value.Text = "Current value: "..tostring(workspace:GetAttribute(Command.DisplayedAttribute))
        CommandFrame.Execute.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end)
        CommandFrame.Execute.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end)
        CommandFrame.Execute.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            local Value = Network:FireServerConnection("ExecuteCommand", "REMOTE_FUNCTION", i.Name)
            CommandFrame.Value.Text = "Current value: "..tostring(Value or workspace:GetAttribute(Command.DisplayedAttribute))
        end)
    end
end

function ModPanel:Open(Time: number)
    if not self.Enabled then
        return "Prevented"
    end

    SideBar:CloseAll(self)

    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.542, 0.741)}):Play()
    else
        self.UIInstance.Size = UDim2.fromScale(0.4, 0.7)
    end
    self.Opened = true

    return
end

function ModPanel:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Opened = false
end

function ModPanel:Toggle()
end

return ModPanel
