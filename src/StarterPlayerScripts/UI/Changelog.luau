local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local Changelog = {
    Enabled = true,
    UIInstance = nil,
    Opened = false,
}

--- The format to follow in `CurrentChangelog`'s 
type ChangelogFormat = {
    --- The version of the place containing the update.
    --- Can be found by printing `game.PlaceVersion`.
    PlaceVersion: number,
    --- The text that'll be shown in the menu's title.
    MenuTitle: string,
    --- The title of the update for the beginning of the changelog.
    UpdateTitle: string,
    --- The ID of the update's thumbnail's image.
    --- May also be a banner if you modify the UI yourself.
    UpdateThumbnailID: string,
    --- The date of the update.
    --- Can be anything, but preferably the date.
    --- Will show under the thumbnail.
    UpdateDate: string,
    --- The entries of the changelog.
    Entries: {{
        Type: "Separator" | "SectionEntry" | "Text",
        Text: string,
    }},
}
local CurrentChangelog: ChangelogFormat = {
    PlaceVersion = 0,
    MenuTitle = "Changelog",
    UpdateTitle = "GAME RELEASE",
    UpdateThumbnailID = "rbxasset://textures/ui/GuiImagePlaceholder.png",
    UpdateDate = "01/01/2099",
    Entries = {
        {
            Type = "Separator",
            Text = "Section N.º 1",
        },
        {
            Type = "SectionEntry",
            Text = "Pretty cool feature N.º 1!",
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
            Text = "Pretty cool feature N.º 3!",
        },
        {
            Type = "Text",
            Text = "Quick note N.º 2!",
        },
        {
            Type = "Separator",
            Text = "Section N.º 2",
        },
        {
            Type = "SectionEntry",
            Text = "Pretty cool feature N.º 1!",
        },
        {
            Type = "Text",
            Text = "Quick note N.º 1!",
        },
        {
            Type = "SectionEntry",
            Text = "Pretty cool feature N.º 2!",
        },
        {
            Type = "SectionEntry",
            Text = "Pretty cool feature N.º 3!",
        },
        {
            Type = "Text",
            Text = "Quick note N.º 2!",
        },
    },
}

local PrefabFolder = Utils.Instance.FindFirstChild(script, "Prefabs")
local Prefabs = {
    Separator = Utils.Instance.FindFirstChild(PrefabFolder, "Separator"),
    SectionEntry = Utils.Instance.FindFirstChild(PrefabFolder, "SectionEntry"),
    Text = Utils.Instance.FindFirstChild(PrefabFolder, "PlainText"),
}

local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")
function Changelog:Init()
    if Changelog.UIInstance then
        Changelog.UIInstance.Parent = UIParent
        Changelog.UIInstance.Size = Utils.UDim.Zero
        Changelog.UIInstance.Visible = false
        return
    end

    local UI = Utils.Instance.FindFirstChild(script, "Changelog")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    Changelog.UIInstance = UI
    UI.Parent = UIParent

    local Content = UI.Content
    local Top = Content.Top
    Top.Title.Text = CurrentChangelog.UpdateTitle
    Top.Thumbnail.Image = CurrentChangelog.UpdateThumbnailID
    Top.Date.Text = CurrentChangelog.UpdateDate

    UI.Label.TextLabel.Text = CurrentChangelog.MenuTitle

    Utils.Instance.ObserveProperty(Changelog.UIInstance, "Size", function(value: UDim2)
        Changelog.UIInstance.Visible = value ~= Utils.UDim.Zero
    end)

    for order, entry in CurrentChangelog.Entries do
        local Inst = Prefabs[entry.Type]:Clone()
        Inst.Title.Text = entry.Text
        Inst.LayoutOrder = order
        Inst.Parent = Content
    end

    local Log = Utils.Instance.FindFirstChild(LocalPlayer, "PlayerData.Misc.LastSeenLog")
    if Log.Value < CurrentChangelog.PlaceVersion and Log.Value < ReplicatedStorage.PlaceVersion.Value and CurrentChangelog.PlaceVersion <= ReplicatedStorage.PlaceVersion.Value then
        SideBar.OpenMenu(Changelog)
    end
end

function Changelog.Open(Time: number)
    if not Changelog.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    if Time > 0 then
        TweenService:Create(Changelog.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.4, 0.7)}):Play()
    else
        Changelog.UIInstance.Size = UDim2.fromScale(0.4, 0.7)
    end
    Changelog.Opened = true

    return
end

function Changelog.Close(Time: number)
    if Time > 0 then
        TweenService:Create(Changelog.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        Changelog.UIInstance.Size = Utils.UDim.Zero
    end
    Changelog.Opened = false
end

function Changelog.Toggle(toggle: boolean)
    if not Changelog.Enabled and toggle then
        Changelog:Init()
    end
    if not toggle and Changelog.Enabled then
        Changelog.UIInstance.Parent = script
        Changelog.UIInstance.Size = Utils.UDim.Zero
    end
    Changelog.Enabled = toggle
end

return Changelog
