--!nocheck

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SideBar = require(script.Parent.SideBar)
local Types = require(ReplicatedStorage.Classes.Character)
local Emote = require(ReplicatedStorage.Classes.Emote)
local Tooltip = require(ReplicatedStorage.Classes.Tooltip)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local BuyWindow = require(script.BuyWindow)

local CharacterFolder = ReplicatedStorage.Assets.Characters

local Shop = {
    Opened = false,
    Enabled = true,
    SelectedSection = "Survivors",
    SkinMenu = {
        Open = false,
        ShowingCharacter = "",
    },
    InfoMenu = {
        Open = false,
        ShowingCharacter = "",
    },
    LoadedItems = {
        Killers = {},
        Survivors = {},
        Emotes = {},
        Skins = {},
    },
    ItemModules = {},
    SelectedItem = {
        Name = "",
        Type = "",
        Card = nil,
    },
    UIInstance = nil,
    BuyWindow = nil,

    PreviewsEnabled = true,
}

local LocalPlayer = Players.LocalPlayer

local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")

local Buttons = {
    Purchase = nil,
    Info = nil,
    Skins = nil,
}

local Sizes = {
    SideBar = UDim2.fromScale(0.3, 1),
    ClosedSideBar = Utils.UDim.FullY,
}

local PreviewInstances = {
    Render = nil,
    Title = nil,
    EmotePreview = nil,
}

local Templates = {
    CardTemplate = nil,
    Header = nil,
    Text = nil,
    Quote = nil,
    Separator = nil,
    InfoSection = nil,
}

local UI
local ShopContainer
local KillerContainer
local SurvivorContainer
local EmoteContainer

local SideContainer
local SkinContainer
local InfoContainer
local PreviewContainer
local ButtonsContainer

local EmoteRig

local Sections = {}

local LoadedEmoteTracks = {}

function Shop:ReorderSkins()
    local Ordered = {
        Owned = {},
        Unowned = {},
    }
    local LO = 0

    for name, skin in self.LoadedItems.Skins do
        if Utils.PlayerData.GetPlayerOwned(LocalPlayer, "Skins."..self.SelectedItem.Name.."."..name) then
            table.insert(Ordered.Owned, skin)
        else
            table.insert(Ordered.Unowned, skin)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        local Modules = {
            A = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)),
            B = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        local Modules = {
            A = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)),
            B = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    for _, skin in ipairs(Ordered.Unowned) do
        LO += 1
        skin.LayoutOrder = LO
    end
    for _, skin in ipairs(Ordered.Owned) do
        LO += 1
        skin.LayoutOrder = LO
    end
end

function Shop:ToggleSkinsMenu(Open: boolean?)
    if Open == nil then
        Open = not self.SkinMenu.Open
    end
    
    if Open then
        self:ToggleInfoMenu(false)

        local Skins = ReplicatedStorage.Characters.Skins[self.SelectedItem.Type.."s"]:FindFirstChild(self.SelectedItem.Name)
        if not Skins then
            return
        end

        --if there are no visible skins, return
        local VisibleSkins = Skins:GetChildren()
        for skinIndex = #VisibleSkins, 1, -1 do
            local skin = VisibleSkins[skinIndex]
            if not (skin:HasTag("Dev") or skin:HasTag("Milestone")) then
                continue
            end

            table.remove(VisibleSkins[skinIndex])
        end

        if #VisibleSkins <= 0 then
            return
        end

        for _, skin in self.LoadedItems.Skins do
            if SkinContainer.SkinPreviewCache:FindFirstChild(skin.Name) then
                SkinContainer.SkinPreviewCache[skin.Name]:Destroy()
            end

            skin:Destroy()
        end

        table.clear(self.LoadedItems.Skins)
        self.ItemModules.Skins = self.ItemModules.Skins or {}
        table.clear(self.ItemModules.Skins)

        local function CheckSkinOwnLabels()
            for name, skin in self.LoadedItems.Skins do
                if Utils.PlayerData.GetPlayerOwned(LocalPlayer, "Skins."..self.SelectedItem.Name.."."..name) then
                    skin.Container.Owned.BackgroundTransparency = 0.55
                    skin.Container.Owned.TextLabel.TextTransparency = 0
                end
            end
        end

        SkinContainer.Parent.Label.TextLabel.Text = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name)).Config.Name.." Skins"

        local CanMakePreviews = self.PreviewsEnabled and Utils.PlayerData.GetPlayerSetting(LocalPlayer, "Performance.SkinPreviews")
        for _, Skin in VisibleSkins do
            local Module = Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, Skin.Name)

            if Module:HasTag("Dev") or Module:HasTag("Milestone") then
                continue
            end

            local Info = require(Module)
            local name = Module.Name

            local Card = Templates.CardTemplate:Clone()
            Card.Name = name
            local Container = Card.Container
            Card.Parent = SkinContainer.ScrollingFrame
            Container.Title.Text = Info.Config.Name
            Container.CharacterRender.Image = Info.Config.Render
            Container.Price.Text = Info.Config.Price > 0 and tostring(Info.Config.Price).."$" or "FREE"

            if Info.Config.CardFrame then
                Container.Outline.Image = Info.Config.CardFrame.Image or Container.Outline.Image
                Container.Outline.Size = Info.Config.CardFrame.Size or Container.Outline.Size
            end

            local SkinPreview = Container.Preview.ViewportFrame
            if CanMakePreviews then
                task.defer(function()
                    local SkinModel = Utils.Instance.FindFirstChild(CharacterFolder, "Skins."..self.SelectedItem.Type.."."..self.SelectedItem.Name.."."..name, 0)
                    if not SkinModel then
                        warn("[Shop:ToggleSkinsMenu]: Item preview model can't be found! Make sure it's located in ReplicatedStorage/Characters/Skins/"..self.SelectedItem.Type.."/"..self.SelectedItem.Name.."s! ("..name..")")
                        return
                    end

                    -- i'm going fucking insane. -dys
                    local Camera = Instance.new("Camera")
                    Camera.FieldOfView = 10
                    Camera.Parent = SkinPreview
                    local WorldModel = Instance.new("WorldModel")
                    WorldModel.Parent = Camera
                    SkinPreview.CurrentCamera = Camera

                    SkinModel = SkinModel:Clone()
                    if not SkinModel.Humanoid:FindFirstChildOfClass("Animator") then
                        Instance.new("Animator").Parent = SkinModel.Humanoid
                    end
                    Utils.Character.GetRootPart(SkinModel).Anchored = true
                    SkinModel:PivotTo(CFrame.new(0, 10000, 0) * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0))

                    Camera.CFrame = CFrame.new(0, 10000, 6 * SkinModel:GetExtentsSize().Y)

                    SkinModel.Parent = SkinContainer.SkinPreviewCache

                    Utils.Character.LoadAnimationFromID(SkinModel, Info.Config.AnimationIDs.PreviewAnimation or Info.Config.AnimationIDs.IdleAnimation, false):Play(0)

                    Utils.Instance.ObserveProperty(SkinPreview, "ImageTransparency", function(value: number)
                        if value < 1 then
                            if SkinModel.Parent ~= WorldModel then
                                SkinModel.Parent = WorldModel
                            end
                        elseif SkinModel.Parent ~= SkinContainer.SkinPreviewCache then
                            SkinModel.Parent = SkinContainer.SkinPreviewCache
                        end
                    end)
                end)
            end

            --create tables if not there
            self.ItemModules.Skins = self.ItemModules.Skins or {}
            self.ItemModules.Skins[self.SelectedItem.Name] = self.ItemModules.Skins[self.SelectedItem.Name] or {}

            self.LoadedItems.Skins[name] = Card
            self.ItemModules.Skins[self.SelectedItem.Name][name] = Info

            -- reminder that these connections disconnect automatically when the parent is destroyed! -dys
            Container.Interact.MouseEnter:Connect(function()
                if CanMakePreviews then
                    TweenService:Create(SkinPreview, TweenInfo.new(0.25), {
                        ImageTransparency = 0
                    }):Play()
                    TweenService:Create(SkinPreview.Parent, TweenInfo.new(0.25), {
                        BackgroundTransparency = 0
                    }):Play()
                end
                TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = UDim2.fromScale(1.065, 1.065)
                }):Play()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            end)
            Container.Interact.MouseLeave:Connect(function()
                if CanMakePreviews then
                    TweenService:Create(SkinPreview, TweenInfo.new(0.25), {
                        ImageTransparency = 1
                    }):Play()
                    TweenService:Create(SkinPreview.Parent, TweenInfo.new(0.25), {
                        BackgroundTransparency = 1
                    }):Play()
                end
                TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = Utils.UDim.Full
                }):Play()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            end)
            Container.Interact.MouseButton1Click:Connect(function()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
                if Container.Owned.BackgroundTransparency >= 1 then
                    self:CreateBuyWindow(Skin, true, UI, Card)
                end

                CheckSkinOwnLabels()
            end)

            if Info.Config.Origin and Info.Config.Origin.Icon then
                Container.Origin.Visible = true
                Container.Origin.Image = Info.Config.Origin.Icon
                Container.Origin.MouseEnter:Connect(function()
                    Tooltip.New(Info.Config.Origin.TooltipText)
                    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
                end)
                Container.Origin.MouseLeave:Connect(function()
                    Tooltip.New()
                    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
                end)
            else
                Container.Origin.Visible = false
            end
        end

        CheckSkinOwnLabels()

        self:ReorderSkins()

        TweenService:Create(ShopContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()

        self.SkinMenu.Open = true
    else
        TweenService:Create(ShopContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()

        self.SkinMenu.Open = false
    end

    TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
end

function Shop:ToggleInfoMenu(Open: boolean?)
    if Open == nil then
        Open = not self.InfoMenu.Open
    end

    if Open then
        self:ToggleSkinsMenu(false)
    end

    if Open then
        for _, Child in InfoContainer:GetChildren() do
            if not Child:IsA("UIComponent") then
                Child:Destroy()
            end
        end

        local CharacterInfo = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name))

        if not CharacterInfo.Config.Description then
            return
        end

        self.InfoMenu.Open = true

        local TextsToCheck = {}

        for SectionIndex: number, Section: {
            Type: "Text" | "Header" | "Separator" | "Quote",
            Text: string | {string},
            Image: string?,
        } in CharacterInfo.Config.Description do
            local SectionContainer = Templates.InfoSection:Clone()
            SectionContainer.LayoutOrder = SectionIndex
            SectionContainer.Parent = InfoContainer

            local Text = ""
            if typeof(Section.Text) == "table" then
                for index, paragraph in ipairs(Section.Text) do
                    if index > 1 then
                        Text = Text.."\n"
                    end
                    Text = Text..paragraph
                end
            else
                Text = Section.Text
            end

            local Pref = Templates[Section.Type]:Clone()
            if Section.Type ~= "Text" then
                (Section.Type == "Separator" and Pref.Title or Pref).Text = Section.Text
            else
                Pref.Title.Text = Text
                Pref.Title.MaxVisibleGraphemes = 0
                if Section.Image then
                    Pref.Image.Image = Section.Image
                    Pref.Image.Visible = true
                end
                table.insert(TextsToCheck, Pref)
                TweenService:Create(Pref.Title, TweenInfo.new(0.03 * #Text, Enum.EasingStyle.Linear), {MaxVisibleGraphemes = #Text}):Play()
            end
            Pref.Parent = SectionContainer
        end

        task.spawn(function()
            local PossibleEffects = {}

            local function AddEffectToList(Inst: ModuleScript | Folder)
                for _, Effect in Inst:GetChildren() do
                    if Effect:IsA("Folder") then
                        AddEffectToList(Effect)
                        continue
                    end

                    if not Effect:IsA("ModuleScript") then
                        continue
                    end

                    PossibleEffects[Effect.Name] = require(Effect).Description or "UNKNOWN"
                end
            end
        
            AddEffectToList(ReplicatedStorage.Effects)
        
            local LocalPlayer = Players.LocalPlayer
            local CurrentTooltip
        
            local function GetSpaceWidth(font, textSize, maxX)
                return TextService:GetTextSize(" ", textSize, font, Vector2.new(maxX, 1e5)).X
            end
        
            while task.wait() and self.InfoMenu.Open do
                local ui = self.UIInstance
                local char = LocalPlayer.Character
                local role = char and char:FindFirstChild("Role")
            
                if not (ui and ui.Visible and role and role.Value == "Spectator") then
                    if CurrentTooltip then
                        CurrentTooltip = Tooltip.New()
                    end
                    continue
                end
            
                local mousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
                local foundEffect = false
            
                for _, textLabel in TextsToCheck do
                    if foundEffect then break end
                
                    local text = textLabel.Title
                    local absPos, absSize = text.AbsolutePosition, text.AbsoluteSize
                    local font, textSize = text.Font, text.TextSize
                    local maxWidth = absSize.X
                    local spaceWidth = GetSpaceWidth(font, textSize, maxWidth)
                
                    -- bound check
                    if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                            mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                        continue
                    end
                
                    local lineHeight = TextService:GetTextSize("A", textSize, font, Vector2.new(maxWidth, 1e5)).Y
                    local totalY = 0
                
                    for _, rawLine in ipairs(text.Text:gsub("<.->", ""):split("\n")) do
                        local currentLine = {}
                        local currentWidth = 0
                    
                        local wrappedLines = {}
                        for _, word in ipairs(rawLine:split(" ")) do
                            local wordSize = TextService:GetTextSize(word, textSize, font, Vector2.new(maxWidth, 1e5)).X
                            if currentWidth + wordSize > maxWidth then
                                table.insert(wrappedLines, currentLine)
                                currentLine = {}
                                currentWidth = 0
                            end
                            table.insert(currentLine, word)
                            currentWidth += wordSize + spaceWidth
                        end
                        if #currentLine > 0 then
                            table.insert(wrappedLines, currentLine)
                        end
                    
                        for _, lineWords in ipairs(wrappedLines) do
                            if foundEffect then break end
                        
                            local minY = absPos.Y + totalY
                            local maxY = minY + lineHeight
                            if mousePos.Y >= minY and mousePos.Y <= maxY then
                                local lineX = absPos.X
                            
                                for _, word in ipairs(lineWords) do
                                    local wSize = TextService:GetTextSize(word, textSize, font, Vector2.new(maxWidth, 1e5)).X
                                    local minX, maxX = lineX, lineX + wSize
                                
                                    if mousePos.X >= minX and mousePos.X <= maxX then
                                        local desc = PossibleEffects[word]
                                        if desc then
                                            CurrentTooltip = Tooltip.New(desc)
                                            foundEffect = true
                                            break
                                        end
                                    end
                                    lineX += wSize + spaceWidth
                                end
                            end
                            totalY += lineHeight
                        end
                    end
                end
            
                if not foundEffect then
                    CurrentTooltip = Tooltip.New()
                end
            end
        end)

        TweenService:Create(ShopContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
        TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
    else
        TweenService:Create(ShopContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()

        self.InfoMenu.Open = false
    end
end

local function SwitchSection(sectionName: string)
    if not Shop.Opened or Shop.SelectedSection == sectionName then return end

    TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()

    if workspace.Sounds:FindFirstChild("EmotePreview") then
        workspace.Sounds.EmotePreview:Destroy()
    end

    for _, section in Sections do
        section.Visible = section.Name == sectionName
    end

    Shop.SelectedSection = sectionName
end

function Shop:Init()
    UI = Utils.Instance.FindFirstChild(script, "ShopUI"):Clone()
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    UI.Parent = UIParent
    self.UIInstance = UI

    local Container = UI.Container
    ShopContainer = Container.ShopContainer.Content
    KillerContainer = ShopContainer.Killers
    SurvivorContainer = ShopContainer.Survivors
    EmoteContainer = ShopContainer.Emotes
    SkinContainer = Container.SkinsContainer.Content
    InfoContainer = Container.InfoContainer.Contents

    Sections = {
        KillerContainer,
        SurvivorContainer,
        EmoteContainer,
    }

    for _, button in Container.ShopContainer.Topbar:GetChildren() do
        if button:IsA("ImageButton") and button.Visible then
            button.MouseEnter:Connect(function()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            end)
            button.MouseLeave:Connect(function()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            end)
            button.MouseButton1Click:Connect(function()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
                SwitchSection(button.Name)
            end)
        end
    end

    local templates = Utils.Instance.FindFirstChild(script, "Templates")
    Templates.CardTemplate = Templates.CardTemplate or templates.CardTemplate
    Templates.Header = Templates.Header or templates.Header
    Templates.Text = Templates.Text or templates.TextContainer
    Templates.Quote = Templates.Quote or templates.Quote
    Templates.Separator = Templates.Separator or templates.Separator
    Templates.InfoSection = Templates.InfoSection or templates.InfoSection

    SideContainer = Container.SideContainer
    PreviewContainer = SideContainer.PreviewContainer

    PreviewInstances.Render = PreviewContainer.Render
    PreviewInstances.Render.Image = ""
    PreviewInstances.Title = PreviewContainer.Title
    PreviewInstances.EmotePreview = PreviewContainer.Emote
    EmoteRig = PreviewContainer.Emote.EmotePreview.Rig

    ButtonsContainer = SideContainer.ButtonsContainer

    Buttons.Purchase = ButtonsContainer.Purchase
    Buttons.Skins = ButtonsContainer.Skins
    Buttons.Info = ButtonsContainer.MoreInfo

    local JanitorInstance = Janitor.new()
    JanitorInstance:LinkToInstance(UI)

    JanitorInstance:Add(Buttons.Purchase.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Purchase.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Purchase.MouseButton1Click:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        if not Utils.PlayerData.GetPlayerOwned(LocalPlayer, self.SelectedItem.Type.."s."..self.SelectedItem.Name) then
            if self.SelectedItem.Type == "Emote" then
                self:CreateBuyWindow(Utils.Instance.GetEmoteModule(self.SelectedItem.Name), false, UI, self.SelectedItem.Card)
                return
            end

            self:CreateBuyWindow(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name), false, UI, self.SelectedItem.Card)
        end
    end))

    JanitorInstance:Add(Buttons.Skins.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Skins.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Skins.MouseButton1Click:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

        TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play() --assuring the sidebar is open

        self:ToggleSkinsMenu()
    end))

    JanitorInstance:Add(Buttons.Info.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Info.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Info.MouseButton1Click:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

        TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play() --assuring the sidebar is open

        self:ToggleInfoMenu()
    end))

    Utils.Instance.ObserveProperty(self.UIInstance, "Size", function(value: UDim2)
        self.UIInstance.Visible = value ~= Utils.UDim.Zero
    end)

    Utils.Instance.ObserveProperty(InfoContainer.Parent, "Size", function(value: UDim2)
        if not self.InfoMenu.Open and value.X.Scale < 0.05 and #InfoContainer:GetChildren() > 0 then
            for _, Child in InfoContainer:GetChildren() do
                if not Child:IsA("UIComponent") then
                    Child:Destroy()
                end
            end
        end
    end)
    
    Utils.Instance.ObserveProperty(SkinContainer.Parent, "Size", function(value: UDim2)
        SkinContainer.Parent.Label.TextLabel.Visible = value.X.Scale >= 0.05
    end)

    self:ReloadContent(true)
end

function Shop:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    self:ToggleSkinsMenu(false)
    self:ToggleInfoMenu(false)
    PreviewInstances.Render.Image = ""
    PreviewInstances.Render.ImageTransparency = 0
    PreviewInstances.EmotePreview.Visible = false
    ButtonsContainer.Skins.Visible = true
    ButtonsContainer.MoreInfo.Visible = true
    for _, emoteTrack in LoadedEmoteTracks do
        if emoteTrack.Animation ~= nil then
            emoteTrack.Animation:Stop(0)
        else
            for _, EmoteTrack in emoteTrack do
                EmoteTrack.Animation:Stop(0)
            end
        end
    end
    if workspace.Sounds:FindFirstChild("EmotePreview") then
        workspace.Sounds.EmotePreview:Destroy()
    end
    SkinContainer.Parent.Size = Utils.UDim.FullY
    InfoContainer.Parent.Size = Utils.UDim.FullY
    SideContainer.Size = Utils.UDim.FullY
    ShopContainer.Parent.Size = UDim2.fromScale(0.7, 1)
    self.SkinMenu.Open = false

    TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Full20Offset}):Play()
    self.Opened = true

    return
end

function Shop:Close(Time: number)
    if self.BuyWindow then
        self.BuyWindow:Hide(Time <= 0)
    end
    if workspace.Sounds:FindFirstChild("EmotePreview") then
        workspace.Sounds.EmotePreview:Destroy()
    end
    if Time > 0 then
        TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        UI.Size = Utils.UDim.Zero
        UI.Visible = false
    end
    self.Opened = false
end

function Shop:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        if self.BuyWindow then
            self.BuyWindow:Hide(true)
        end
        if workspace.Sounds:FindFirstChild("EmotePreview") then
            workspace.Sounds.EmotePreview:Destroy()
        end
        table.clear(self.ItemModules)
        self.LoadedItems = {
            Killers = {},
            Survivors = {},
            Emotes = {},
            Skins = {},
        }
        self.SelectedItem = {
            Name = "",
            Type = "",
            Card = nil,
        }
        self.SelectedSection = "Survivors"
        self.UIInstance:Destroy()
        self.SkinMenu = {
            Open = false,
        }
    end
    self.Enabled = toggle
end

function Shop:OnCharButtonPress(codeName: string, info: Types.Killer | Types.Survivor | Emote.Emote, Module: ModuleScript, Type: string, Card: Frame)
    if not self.Opened then
        return
    end

    PreviewInstances.Render.Image = info.Config.Render
    PreviewInstances.Title.Text = info.Config.Name

    if Utils.PlayerData.GetPlayerOwned(LocalPlayer, Type.."s."..codeName) then
        Buttons.Purchase.Title.Text = "Purchased"
    else
        Buttons.Purchase.Title.Text = "Purchase"
    end

    ButtonsContainer.CurrentItemPrice.Text = info.Config.Price > 0 and tostring(info.Config.Price).."$" or "FREE"

    self.SelectedItem.Name = codeName
    self.SelectedItem.Type = Type
    self.SelectedItem.Card = Card

    TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play()

    if Type == "Emote" then
        PreviewInstances.EmotePreview.Visible = true
        PreviewInstances.Render.ImageTransparency = 1
        ButtonsContainer.Skins.Visible = false
        ButtonsContainer.MoreInfo.Visible = false
        
        if workspace.Sounds:FindFirstChild("EmotePreview") then
            workspace.Sounds.EmotePreview:Destroy()
        end
        for _, emoteTrack in LoadedEmoteTracks do
            if emoteTrack.Animation ~= nil then
                emoteTrack.Animation:Stop(0)
            else
                for _, EmoteTrack in emoteTrack do
                    EmoteTrack.Animation:Stop(0)
                end
            end
        end

        local AnimTrack = LoadedEmoteTracks[Module.Name]
        if not AnimTrack then
            local AnimIDs = info.AnimationIds
            if typeof(AnimIDs) == "string" then
                LoadedEmoteTracks[Module.Name] = {
                    Animation = Utils.Character.LoadAnimationFromID(EmoteRig, AnimIDs),
                    Sound = nil,
                }
            else
                LoadedEmoteTracks[Module.Name] = {}

                for _, ID: string in AnimIDs do
                    LoadedEmoteTracks[Module.Name][ID] = {
                        Animation = Utils.Character.LoadAnimationFromID(EmoteRig, ID),
                        Sound = nil,
                    }
                end
            end

            if info.SoundIds then
                if typeof(info.SoundIds) == "string" then
                    if typeof(AnimIDs) == "string" then
                        LoadedEmoteTracks[Module.Name].Sound = info.SoundIds
                    else
                        for _, id in AnimIDs do
                            LoadedEmoteTracks[Module.Name][id].Sound = info.SoundIds
                        end
                    end
                else
                    for animId, id in info.SoundIds do
                        LoadedEmoteTracks[Module.Name][animId].Sound = id
                    end
                end
            end

            AnimTrack = LoadedEmoteTracks[Module.Name]
        end

        if not AnimTrack.Animation then
            local Selected = AnimTrack[math.random(1, #AnimTrack)]
            Selected.Animation:Play(0)
            Sounds.PlaySound(Selected.Sound, {Name = "EmotePreview"})
        else
            AnimTrack.Animation:Play(0)
            Sounds.PlaySound(AnimTrack.Sound, {Name = "EmotePreview"})
        end
    else
        PreviewInstances.EmotePreview.Visible = false
        PreviewInstances.Render.ImageTransparency = 0
        ButtonsContainer.Skins.Visible = true
        ButtonsContainer.MoreInfo.Visible = true
    end
end

function Shop:ReloadContent(CreateCards: boolean?)
    if CreateCards == nil then
        CreateCards = false
    end

    local Ordered = {
        Owned = {},
        Unowned = {},
    }
    local LO = 0

    local CanMakePreviews = self.PreviewsEnabled and Utils.PlayerData.GetPlayerSetting(LocalPlayer, "Performance.SkinPreviews")

    local function SetupCard(module, Type: "Survivor" | "Killer" | "Emote")
        if module:HasTag("Dev") then
            return
        end

        LO += 1

        local Parent = if Type == "Killer" then KillerContainer elseif Type == "Survivor" then SurvivorContainer else EmoteContainer

        if not CreateCards then
            Parent:FindFirstChild(module.Name).LayoutOrder = LO
            return
        end

        local name = module.Name

        if self.LoadedItems[Type.."s"][name] then
            return
        end

        local Module = Type == "Emote" and Utils.Instance.GetEmoteModule(name) or Utils.Instance.GetCharacterModule(Type, name)
        local Info = require(Module)

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = Parent
        Container.Title.Text = Info.Config.Name
        Container.CharacterRender.Image = Info.Config.Render
        Container.Price.Text = Info.Config.Price > 0 and tostring(Info.Config.Price).."$" or "FREE"

        if Info.Config.CardFrame then
            Container.Outline.Image = Info.Config.CardFrame.Image or Container.Outline.Image
            Container.Outline.Size = Info.Config.CardFrame.Size or Container.Outline.Size
        end

        local Preview = Container.Preview.ViewportFrame
        if CanMakePreviews and Type ~= "Emote" then
            task.defer(function()
                local Model = Utils.Instance.FindFirstChild(CharacterFolder, Type.."."..name, 0)
                if not Model then
                    warn("[Shop:ReloadContent]: Item preview model can't be found! Make sure it's located in ReplicatedStorage/Characters/"..Type.."! ("..name..")")
                    return
                end

                -- i'm going fucking insane. -dys
                local Camera = Instance.new("Camera")
                Camera.FieldOfView = 10
                Camera.Parent = Preview
                local WorldModel = Instance.new("WorldModel")
                WorldModel.Parent = Camera
                Preview.CurrentCamera = Camera

                Model = Model:Clone()
                if not Model.Humanoid:FindFirstChildOfClass("Animator") then
                    Instance.new("Animator").Parent = Model.Humanoid
                end
                Utils.Character.GetRootPart(Model).Anchored = true
                Model:PivotTo(CFrame.new(0, 10000, 0) * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0))

                Camera.CFrame = CFrame.new(0, 10000, 6 * Model:GetExtentsSize().Y)

                Model.Parent = ShopContainer.PreviewCache

                Utils.Character.LoadAnimationFromID(Model, Info.Config.AnimationIDs.PreviewAnimation or Info.Config.AnimationIDs.IdleAnimation, false):Play(0)

                Utils.Instance.ObserveProperty(Preview, "ImageTransparency", function(value: number)
                    if value < 1 then
                        if Model.Parent ~= WorldModel then
                            Model.Parent = WorldModel
                        end
                    elseif Model.Parent ~= ShopContainer.PreviewCache then
                        Model.Parent = ShopContainer.PreviewCache
                    end
                end)
            end)
        end

        if Utils.PlayerData.GetPlayerOwned(LocalPlayer, Type.."s."..name) then
            Container.Owned.BackgroundTransparency = 0.55
            Container.Owned.TextLabel.TextTransparency = 0
        end

        --create table if not there
        self.ItemModules[Type.."s"] = self.ItemModules[Type.."s"] or {}

        self.LoadedItems[Type.."s"][name] = Card
        self.ItemModules[Type.."s"][name] = Info
        Container.Interact.MouseEnter:Connect(function()
            if CanMakePreviews and Type ~= "Emote" then
                TweenService:Create(Preview, TweenInfo.new(0.25), {
                    ImageTransparency = 0
                }):Play()
                TweenService:Create(Preview.Parent, TweenInfo.new(0.25), {
                    BackgroundTransparency = 0
                }):Play()
            end
            TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(1.065, 1.065)
            }):Play()
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end)
        Container.Interact.MouseLeave:Connect(function()
            if CanMakePreviews and Type ~= "Emote" then
                TweenService:Create(Preview, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play()
                TweenService:Create(Preview.Parent, TweenInfo.new(0.25), {
                    BackgroundTransparency = 1
                }):Play()
            end
            TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = Utils.UDim.Full
            }):Play()
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end)
        Container.Interact.MouseButton1Click:Connect(function()
            if self.SkinMenu.Open then
                return
            end
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            self:OnCharButtonPress(name, Info, Module, Type, Card)
        end)

        if Info.Config.Origin and Info.Config.Origin.Icon then
            Container.Origin.Visible = true
            Container.Origin.Image = Info.Config.Origin.Icon

            local TooltipAvailable = Info.Config.Origin.TooltipText ~= nil

            Container.Origin.MouseEnter:Connect(function()
                if TooltipAvailable then
                    Tooltip.New(Info.Config.Origin.TooltipText)
                end

                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            end)
            Container.Origin.MouseLeave:Connect(function()
                if TooltipAvailable then
                    Tooltip.New()
                end

                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            end)
        else
            Container.Origin.Visible = false
        end
    end

    local function SortTableByPriceAndName(TableToSort)
        table.sort(TableToSort, function(a, b)
            local Modules = {
                A = require(a),
                B = require(b),
            }

            return
                Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
                or Modules.A.Config.Price < Modules.B.Config.Price
        end)
    end

    local function SetupBatch(Type: "Killer" | "Survivor" | "Emote")
        Ordered = {
            Owned = {},
            Unowned = {},
        }
        LO = 0

        for _, module in ReplicatedStorage[Type == "Emote" and "Assets" or "Characters"][Type.."s"]:GetChildren() do
            table.insert(Ordered[Utils.PlayerData.GetPlayerOwned(LocalPlayer, Type.."s."..module.Name) and "Owned" or "Unowned"], module)
        end

        SortTableByPriceAndName(Ordered.Owned)
        SortTableByPriceAndName(Ordered.Unowned)

        for _, module in ipairs(Ordered.Unowned) do
            SetupCard(module, Type)
        end
        for _, module in ipairs(Ordered.Owned) do
            SetupCard(module, Type)
        end
    end

    SetupBatch("Killer")
    SetupBatch("Survivor")
    SetupBatch("Emote")
end

function Shop:CreateBuyWindow(Module: ModuleScript, skin: boolean?, Parent: Frame, Card: Frame)
    if self.BuyWindow then
        return
    end

    local Window = BuyWindow.New(self, Module, skin, Parent, Card)
    Window.Purchased:Connect(function()
        if Utils.PlayerData.GetPlayerOwned(LocalPlayer, self.SelectedItem.Type.."s."..self.SelectedItem.Name) then
            Buttons.Purchase.Title.Text = "Purchased"
        else
            Buttons.Purchase.Title.Text = "Purchase"
        end
        self:ReloadContent()
        self:ReorderSkins()
    end)
    Window.Removed:Connect(function()
        self.BuyWindow = nil
    end)

    self.BuyWindow = Window
end

return Shop
