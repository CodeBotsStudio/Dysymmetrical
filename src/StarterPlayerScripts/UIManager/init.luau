local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)
type GuiItem = {
    Name: string,
    Enabled: boolean?,
    IgnoreGuiInset: boolean?,
    ResetOnSpawn: boolean?,
    DisplayOrder: number?,
    Callback: ((Gui: ScreenGui) -> ())?,
}

local UIManager = {
    ManagedScreenGuis = {},
}
UIManager.DefaultGuiInfo = {
    {
        Name = "TemporaryUI",
        IgnoreGuiInset = true,
    },
    {
        Name = "EmotePanel",
        ResetOnSpawn = false,
    },
    {
        Name = "Time",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    },
    {
        Name = "PlayerVitals",
    },
    {
        Name = "Effects",
    },
    {
        Name = "RoundPlayerList",
        ResetOnSpawn = false,
    },
    {
        Name = "CharacterGUI",
    },
    {
        Name = "VideoPlayer",
        ResetOnSpawn = false,
    },
    {
        Name = "PlayerList",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    },
    {
        Name = "Menus",
        ResetOnSpawn = false,
    },
    {
        Name = "SideBar",
        ResetOnSpawn = false,
    },
    {
        Name = "KillerIntros",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    },
    {
        Name = "MoneyXPRewards",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    },
    {
        Name = "RewardNotifications",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    },
    {
        Name = "AFKLabel",
        Enabled = false,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        Callback = function(ScreenGui: ScreenGui)
            local AFK = Instance.new("TextLabel")

            AFK.AnchorPoint = Vector2.new(0.5, 1)

            AFK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            AFK.BackgroundTransparency = 1

            AFK.Position = UDim2.fromScale(0.5, 1)
            AFK.Size = UDim2.fromScale(0.5, 0.13)

            AFK.Text = "AFK mode is on. You won't be put in new matches while it's on. It can be turned off from the top of the settings menu."

            AFK.TextColor3 = Color3.fromRGB(255, 255, 255)
            AFK.TextTransparency = 0.6

            AFK.TextScaled = true
            AFK.TextWrapped = true

            AFK.Font = Enum.Font.Fantasy

            AFK.Parent = ScreenGui
        end,
    },
} :: {GuiItem}

function UIManager:Init()
    --disables default roblox ui
    do
        local StarterGui = game:GetService("StarterGui")

        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end

    --creates all screenguis that aren't there yet with their own display order correspondingly
    for DisplayOrder, Gui in ipairs(UIManager.DefaultGuiInfo) do
        if UIManager.ManagedScreenGuis[Gui.Name] ~= nil then
            continue
        end

        Gui.DisplayOrder = DisplayOrder

        UIManager.ManagedScreenGuis[Gui.Name] = UIManager.CreateScreenGui(Gui)
    end
end

--- Directly creates a `ScreenGui` instance.
--- 
--- If it already exists, the existent one is returned.
--- 
--- Similar to `UIManager.FetchScreenGui` but takes `GuiItem` as a parameter, letting you create a `ScreenGui` from scratch with custom properties already set.
function UIManager.CreateScreenGui(Info: GuiItem): ScreenGui
    local ScreenGui = UIManager.ManagedScreenGuis[Info.Name]
    if ScreenGui then
        return ScreenGui
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = Info.Name
    if Info.Enabled ~= nil then
        ScreenGui.Enabled = Info.Enabled
    end
    if Info.IgnoreGuiInset ~= nil then
        ScreenGui.IgnoreGuiInset = Info.IgnoreGuiInset
    end
    if Info.ResetOnSpawn ~= nil then
        ScreenGui.ResetOnSpawn = Info.ResetOnSpawn
    end
    if ScreenGui.ResetOnSpawn then
        ScreenGui.ResetOnSpawn = false
        --why am I doing this instead of `ScreenGui:ClearAllChildren()`
        --it's been proved that just redoing the ScrenGui is more performant than clearing its children because it doesn't have to reparent every single child individually
        --cool sauce i love reading random stuff like this in devforum out of nowhere
        local JanitorInstance = Utils.Character.ObserveCharacter(Players.LocalPlayer, function(_Character: Model)
            ScreenGui:Destroy()
            UIManager.ManagedScreenGuis[Info.Name] = UIManager.CreateScreenGui(Info)
        end)
        JanitorInstance:LinkToInstance(ScreenGui)
    end
    -- override -> order in default table -> default to last in default table
    ScreenGui.DisplayOrder = Info.DisplayOrder or table.find(UIManager.DefaultGuiInfo, Info) or Utils.Type.GetCountOfDict(UIManager.ManagedScreenGuis)
    ScreenGui.Parent = Players.LocalPlayer.PlayerGui
    if Info.Callback then
        Info.Callback(ScreenGui)
    end

    return ScreenGui
end

--- Will try to get an existing `ScreenGui` and, if it doesn't exist, it creates it with default values.
function UIManager.FetchScreenGui(Name: string): ScreenGui
    local Result = UIManager.ManagedScreenGuis[Name]
    if Result then
        return Result
    end

    --removed this due to remaking ResetOnSpawn behaviour
    -- Result = Players.LocalPlayer.PlayerGui:FindFirstChild(Name)
    -- if Result then
    --     UIManager.ManagedScreenGuis[Name] = Result
    --     return Result
    -- end

    return UIManager.CreateScreenGUI(UIManager._GetDefaultInfoByName(Name) or {Name = Name})
end

function UIManager._GetDefaultInfoByName(Name: string): GuiItem
    for _, Info: GuiItem in UIManager.DefaultGuiInfo do
        if Info.Name == Name then
            return Info
        end
    end

    return
end

return UIManager
