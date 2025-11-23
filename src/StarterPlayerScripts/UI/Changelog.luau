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

local PrefabFolder = Utils:FindFirstChild(script, "Prefabs")
local Prefabs = {
    Separator = Utils:FindFirstChild(PrefabFolder, "Separator"),
    SectionEntry = Utils:FindFirstChild(PrefabFolder, "SectionEntry"),
    Text = Utils:FindFirstChild(PrefabFolder, "PlainText"),
}

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")
function Changelog:Init()
    if self.UIInstance then
        self.UIInstance.Parent = UIParent
        self.UIInstance.Size = Utils.UDim.Zero
        self.UIInstance.Visible = false
        return
    end

    local UI = Utils:FindFirstChild(script, "Changelog")
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    self.UIInstance = UI
    UI.Parent = UIParent

    local Content = UI.Content
    local Top = Content.Top
    Top.Title.Text = CurrentChangelog.UpdateTitle
    Top.Thumbnail.Image = CurrentChangelog.UpdateThumbnailID
    Top.Date.Text = CurrentChangelog.UpdateDate

    UI.Label.TextLabel.Text = CurrentChangelog.MenuTitle

    self.UIInstance:GetPropertyChangedSignal("Size"):Connect(function()
        self.UIInstance.Visible = self.UIInstance.Size ~= Utils.UDim.Zero
    end)

    for order, entry in CurrentChangelog.Entries do
        local Inst = Prefabs[entry.Type]:Clone()
        Inst.Title.Text = entry.Text
        Inst.LayoutOrder = order
        Inst.Parent = Content
    end

    local Log = Utils:FindFirstChild(LocalPlayer, "PlayerData.Misc.LastSeenLog")
    if Log.Value < CurrentChangelog.PlaceVersion and Log.Value < ReplicatedStorage.PlaceVersion.Value and CurrentChangelog.PlaceVersion <= ReplicatedStorage.PlaceVersion.Value then
        SideBar:OpenMenu(self)
    end
end

function Changelog:Open(Time: number)
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

function Changelog:Close(Time: number)
    if Time > 0 then
        TweenService:Create(self.UIInstance, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Opened = false
end

function Changelog:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        self.UIInstance.Parent = script
        self.UIInstance.Size = Utils.UDim.Zero
    end
    self.Enabled = toggle
end

return Changelog
