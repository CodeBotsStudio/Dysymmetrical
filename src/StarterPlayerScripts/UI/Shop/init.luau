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

local BuyWindow = require(script.BuyWindow)

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
}

local LocalPlayer = Players.LocalPlayer

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

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

    for n, i in self.LoadedItems.Skins do
        if Utils:GetPlayerOwned(LocalPlayer, "Skins."..self.SelectedItem.Name.."."..n) then
            table.insert(Ordered.Owned, i)
        else
            table.insert(Ordered.Unowned, i)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        local Modules = {
            A = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)),
            B = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        local Modules = {
            A = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)),
            B = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    for _, i in Ordered.Unowned do
        LO += 1
        i.LayoutOrder = LO
    end
    for _, i in Ordered.Owned do
        LO += 1
        i.LayoutOrder = LO
    end
end

function Shop:ToggleSkinsMenu(Open: boolean?)
    if Open == nil then
        Open = not self.SkinMenu.Open
    end

    if Open then
        self:ToggleInfoMenu(false)
    end
    
    if Open then
        local Skins = ReplicatedStorage.Characters.Skins[self.SelectedItem.Type.."s"]:FindFirstChild(self.SelectedItem.Name)
        if not Skins then return end

        for _, i in self.LoadedItems.Skins do
            i:Destroy()
        end
        table.clear(self.LoadedItems.Skins)
        self.ItemModules.Skins = self.ItemModules.Skins or {}
        table.clear(self.ItemModules.Skins)

        local function CheckSkinOwnLabels()
            for n, i in self.LoadedItems.Skins do
                if Utils:GetPlayerOwned(LocalPlayer, "Skins."..self.SelectedItem.Name.."."..n) then
                    i.Container.Owned.BackgroundTransparency = 0.55
                    i.Container.Owned.TextLabel.TextTransparency = 0
                end
            end
        end

        for _, i in Skins:GetChildren() do
            local Module = Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, i.Name)

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

            self.LoadedItems.Skins[name] = Card
            self.ItemModules.Skins[name] = Info

            Container.Interact.MouseEnter:Connect(function()
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            end)
            Container.Interact.MouseLeave:Connect(function()
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            end)
            Container.Interact.MouseButton1Click:Connect(function()
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
                if Container.Owned.BackgroundTransparency >= 1 then
                    self:CreateBuyWindow(i, true, UI, Card)
                end

                CheckSkinOwnLabels()
            end)
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
        for _, i in InfoContainer:GetChildren() do
            if not i:IsA("UIComponent") then
                i:Destroy()
            end
        end

        local CharacterInfo = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name))

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
                for i, v in ipairs(Section.Text) do
                    if i > 1 then
                        Text = Text.."\n"
                    end
                    Text = Text..v
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
                for _, i in Inst:GetChildren() do
                    if i:IsA("Folder") then
                        AddEffectToList(i)
                        continue
                    end

                    if not i:IsA("ModuleScript") then
                        continue
                    end

                    PossibleEffects[i.Name] = require(i).Description or "UNKNOWN"
                end
            end
        
            AddEffectToList(ReplicatedStorage.Effects)
        
            local LocalPlayer = Players.LocalPlayer
            local CurrentTooltip
        
            local function GetSpaceWidth(font, textSize, maxX)
                return TextService:GetTextSize(" ", textSize, font, Vector2.new(maxX, 1e9)).X
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
                
                    local lineHeight = TextService:GetTextSize("A", textSize, font, Vector2.new(maxWidth, 1e9)).Y
                    local totalY = 0
                
                    for _, rawLine in ipairs(text.Text:gsub("<.->", ""):split("\n")) do
                        local currentLine = {}
                        local currentWidth = 0
                    
                        local wrappedLines = {}
                        for _, word in ipairs(rawLine:split(" ")) do
                            local wordSize = TextService:GetTextSize(word, textSize, font, Vector2.new(maxWidth, 1e9)).X
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
                                    local wSize = TextService:GetTextSize(word, textSize, font, Vector2.new(maxWidth, 1e9)).X
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

    for _, i in Sections do
        i.Visible = i.Name == sectionName
    end

    Shop.SelectedSection = sectionName
end

function Shop:Init()
    UI = Utils:FindFirstChild(script, "ShopUI"):Clone()
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
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            end)
            button.MouseLeave:Connect(function()
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            end)
            button.MouseButton1Click:Connect(function()
                Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
                SwitchSection(button.Name)
            end)
        end
    end

    local templates = Utils:FindFirstChild(script, "Templates")
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

    local Conns = {}

    table.insert(Conns, Buttons.Purchase.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Purchase.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Purchase.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        if not Utils:GetPlayerOwned(LocalPlayer, self.SelectedItem.Type.."s."..self.SelectedItem.Name) then
            if self.SelectedItem.Type == "Emote" then
                self:CreateBuyWindow(Utils:GetEmoteModule(self.SelectedItem.Name), false, UI, self.SelectedItem.Card)
                return
            end

            self:CreateBuyWindow(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name), false, UI, self.SelectedItem.Card)
        end
    end))

    table.insert(Conns, Buttons.Skins.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Skins.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Skins.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

        TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play() --assuring the sidebar is open

        self:ToggleSkinsMenu()
    end))

    table.insert(Conns, Buttons.Info.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Info.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Info.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

        TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play() --assuring the sidebar is open

        self:ToggleInfoMenu()
    end))

    table.insert(Conns, self.UIInstance:GetPropertyChangedSignal("Size"):Connect(function()
        self.UIInstance.Visible = self.UIInstance.Size ~= Utils.UDim.Zero
    end))

    table.insert(Conns, UI.Destroying:Connect(function()
        for _, i in Conns do
            i:Disconnect()
        end
    end))

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
    for _, v in LoadedEmoteTracks do
        if v.Animation ~= nil then
            v.Animation:Stop(0)
        else
            for _, i in v do
                i.Animation:Stop(0)
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

    if Utils:GetPlayerOwned(LocalPlayer, Type.."s."..codeName) then
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
        for _, v in LoadedEmoteTracks do
            if v.Animation ~= nil then
                v.Animation:Stop(0)
            else
                for _, i in v do
                    i.Animation:Stop(0)
                end
            end
        end

        local AnimTrack = LoadedEmoteTracks[Module.Name]
        if not AnimTrack then
            local AnimIDs = info.AnimationIds
            if typeof(AnimIDs) == "string" then
                LoadedEmoteTracks[Module.Name] = {
                    Animation = Utils:LoadAnimationFromID(EmoteRig, AnimIDs),
                    Sound = nil,
                }
            else
                LoadedEmoteTracks[Module.Name] = {}

                for _, ID: string in AnimIDs do
                    LoadedEmoteTracks[Module.Name][ID] = {
                        Animation = Utils:LoadAnimationFromID(EmoteRig, ID),
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
            Sounds:PlaySound(Selected.Sound, {Name = "EmotePreview"})
        else
            AnimTrack.Animation:Play(0)
            Sounds:PlaySound(AnimTrack.Sound, {Name = "EmotePreview"})
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

    for _, module in ReplicatedStorage.Characters.Killers:GetChildren() do
        if Utils:GetPlayerOwned(LocalPlayer, "Killers."..module.Name) then
            table.insert(Ordered.Owned, module)
        else
            table.insert(Ordered.Unowned, module)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        local Modules = {
            A = require(a),
            B = require(b),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        local Modules = {
            A = require(a),
            B = require(b),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    local function SetupKillerCard(module)
        if module:HasTag("Dev") then
            return
        end

        LO += 1

        if not CreateCards then
            KillerContainer:FindFirstChild(module.Name).LayoutOrder = LO
            return
        end

        local name = module.Name

        if self.LoadedItems.Killers[name] then
            return
        end

        local Module = Utils:GetCharacterModule("Killer", name)
        local KillerInfo: Types.Killer = require(Module)

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = KillerContainer
        Container.Title.Text = KillerInfo.Config.Name
        Container.CharacterRender.Image = KillerInfo.Config.Render
        Container.Price.Text = KillerInfo.Config.Price > 0 and tostring(KillerInfo.Config.Price).."$" or "FREE"

        if Utils:GetPlayerOwned(LocalPlayer, "Killers."..name) then
            Container.Owned.BackgroundTransparency = 0.55
            Container.Owned.TextLabel.TextTransparency = 0
        end

        self.LoadedItems.Killers[name] = Card
        self.ItemModules[name] = KillerInfo
        Container.Interact.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end)
        Container.Interact.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end)
        Container.Interact.MouseButton1Click:Connect(function()
            if self.SkinMenu.Open then
                return
            end
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            self:OnCharButtonPress(name, KillerInfo, Module, "Killer", Card)
        end)
    end

    for _, module in Ordered.Unowned do
        SetupKillerCard(module)
    end
    for _, module in Ordered.Owned do
        SetupKillerCard(module)
    end

    Ordered = {
        Owned = {},
        Unowned = {},
    }
    LO = 0

    for _, module in ReplicatedStorage.Characters.Survivors:GetChildren() do
        if Utils:GetPlayerOwned(LocalPlayer, "Survivors."..module.Name) then
            table.insert(Ordered.Owned, module)
        else
            table.insert(Ordered.Unowned, module)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        local Modules = {
            A = require(a),
            B = require(b),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        local Modules = {
            A = require(a),
            B = require(b),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    local function SetupSurvivorCard(module)
        if module:HasTag("Dev") then
            return
        end
        
        local name = module.Name
        LO += 1

        if not CreateCards then
            SurvivorContainer:FindFirstChild(name).LayoutOrder = LO
            return
        end

        if self.LoadedItems.Survivors[name] then
            return
        end

        local Module = Utils:GetCharacterModule("Survivor", name)
        local SurvivorInfo: Types.Killer = require(Module)

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = SurvivorContainer
        Container.Title.Text = SurvivorInfo.Config.Name
        Container.CharacterRender.Image = SurvivorInfo.Config.Render
        Container.Price.Text = SurvivorInfo.Config.Price > 0 and tostring(SurvivorInfo.Config.Price).."$" or "FREE"

        if Utils:GetPlayerOwned(LocalPlayer, "Survivors."..name) then
            Container.Owned.BackgroundTransparency = 0.55
            Container.Owned.TextLabel.TextTransparency = 0
        end

        self.LoadedItems.Survivors[name] = Card
        self.ItemModules[name] = SurvivorInfo
        Container.Interact.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end)
        Container.Interact.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end)
        Container.Interact.MouseButton1Click:Connect(function()
            if self.SkinMenu.Open then
                return
            end
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            self:OnCharButtonPress(name, SurvivorInfo, Module, "Survivor", Card)
        end)
    end
    
    for _, module in Ordered.Unowned do
        SetupSurvivorCard(module)
    end
    for _, module in Ordered.Owned do
        SetupSurvivorCard(module)
    end

    Ordered = {
        Owned = {},
        Unowned = {},
    }
    LO = 0

    for _, module in ReplicatedStorage.Assets.Emotes:GetChildren() do
        if Utils:GetPlayerOwned(LocalPlayer, "Emotes."..module.Name) then
            table.insert(Ordered.Owned, module)
        else
            table.insert(Ordered.Unowned, module)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        local Modules = {
            A = require(a),
            B = require(b),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        local Modules = {
            A = require(a),
            B = require(b),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    local function SetupEmoteCard(module)
        if module:HasTag("Dev") then
            return
        end
        
        local name = module.Name
        LO += 1

        if not CreateCards then
            EmoteContainer:FindFirstChild(name).LayoutOrder = LO
            return
        end

        if self.LoadedItems.Emotes[name] then
            return
        end

        local Module = Utils:GetEmoteModule(name)
        local EmoteInfo: Emote.Emote = require(Module)

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = EmoteContainer
        Container.Title.Text = EmoteInfo.Config.Name
        Container.CharacterRender.Image = EmoteInfo.Config.Render
        Container.Price.Text = EmoteInfo.Config.Price > 0 and tostring(EmoteInfo.Config.Price).."$" or "FREE"

        if Utils:GetPlayerOwned(LocalPlayer, "Emotes."..name) then
            Container.Owned.BackgroundTransparency = 0.55
            Container.Owned.TextLabel.TextTransparency = 0
        end

        self.LoadedItems.Emotes[name] = Card
        self.ItemModules[name] = EmoteInfo
        Container.Interact.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end)
        Container.Interact.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end)
        Container.Interact.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            self:OnCharButtonPress(name, EmoteInfo, Module, "Emote", Card)
        end)
    end
    
    for _, module in Ordered.Unowned do
        SetupEmoteCard(module)
    end
    for _, module in Ordered.Owned do
        SetupEmoteCard(module)
    end
end

function Shop:CreateBuyWindow(Module: ModuleScript, skin: boolean?, Parent: Frame, Card: Frame)
    if self.BuyWindow then
        return
    end

    local Window = BuyWindow.New(self, Module, skin, Parent, Card)
    Window.Purchased:Connect(function()
        if Utils:GetPlayerOwned(LocalPlayer, self.SelectedItem.Type.."s."..self.SelectedItem.Name) then
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
