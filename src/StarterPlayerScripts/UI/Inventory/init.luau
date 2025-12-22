--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local EmoteEquipWindow = require(script.EmoteEquipWindow)
local SideBar = require(script.Parent.SideBar)
local Network = require(ReplicatedStorage.Modules.Network)
local Types = require(ReplicatedStorage.Classes.Character)
local Tooltip = require(ReplicatedStorage.Classes.Tooltip)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local LocalPlayer = Players.LocalPlayer

local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")

local Inventory = {
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
        Skins = {},
    },
    ItemModules = {},
    SelectedItem = {
        Name = "",
        Type = "",
    },
    UIInstance = nil,
    EmoteWindow = nil,
}

local Sizes = {
    SideBar = UDim2.fromScale(0.3, 1),
    ClosedSideBar = Utils.UDim.FullY,
}

local UI
local InventoryContainer
local KillerContainer
local SurvivorContainer
local EmoteContainer

local SideContainer
local SkinContainer
local InfoContainer
local PreviewContainer
local ButtonsContainer

local Buttons = {
    Equip = nil,
    Info = nil,
    Skins = nil,
}

local Equipped = {
    EquippedKiller = nil,
    EquippedSurvivor = nil,
}

local PreviewInstances = {
    Render = nil,
    Title = nil,
}

local Templates = {
    CardTemplate = nil,
    Header = nil,
    Text = nil,
    Quote = nil,
    Separator = nil,
    InfoSection = nil,
}

local Sections = {}

function Inventory:ReorderSkins()
    local Ordered = {}
    local LO = 0

    for _, Skin in self.LoadedItems.Skins do
        table.insert(Ordered, Skin)
    end

    table.sort(Ordered, function(a, b)
        local Modules = {
            A = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)),
            B = require(Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    for _, Skin in Ordered do
        LO += 1
        Skin.LayoutOrder = LO
    end
end


function Inventory:CheckEquipLabels()
    local function RemoveEquippedLabel(card)
        if card.Container.Equipped.ImageTransparency ~= 1 then
            TweenService:Create(card.Container.Equipped, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
        end
    end

    local function ShowEquippedLabel(card)
        if card.Container.Equipped.ImageTransparency ~= 0 then
            TweenService:Create(card.Container.Equipped, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
        end
    end

    for name, Type in self.LoadedItems do
        if name == "Skins" then
            continue
        end
        for _, Item in Type do
            if Item.Name == Equipped["Equipped"..name:sub(1, #name - 1)].Value then
                ShowEquippedLabel(Item)
            else
                RemoveEquippedLabel(Item)
            end
        end
    end
end

function Inventory:EquipItem()
    Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
    if not Inventory.Opened or Equipped["Equipped"..Inventory.SelectedItem.Type].Value == Inventory.SelectedItem.Name then
        return
    end

    local lastEquipped = Equipped["Equipped"..Inventory.SelectedItem.Type].Value
    Buttons.Equip.Title.Text = "Equipped"
    Network:FireServerConnection("EquipItem", "REMOTE_EVENT", Inventory.SelectedItem.Name, Inventory.SelectedItem.Type)
    if Equipped["Equipped"..Inventory.SelectedItem.Type].Value == lastEquipped then
        Equipped["Equipped"..Inventory.SelectedItem.Type].Changed:Wait()
    end
    self:CheckEquipLabels()
end

local function SwitchSection(sectionName: string)
    if not Inventory.Opened or Inventory.SelectedSection == sectionName then return end

    TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()
    if Inventory.EmoteWindow then
        Inventory.EmoteWindow:Hide()
        Inventory.EmoteWindow = nil
    end

    for _, Section in Sections do
        Section.Visible = Section.Name == sectionName
    end

    Inventory.SelectedSection = sectionName
end

function Inventory:ReloadEquippedEmotes()
    for _, EmoteSlot in EmoteContainer.EmoteContainer:GetChildren() do
        local Value = Utils.PlayerData.GetPlayerEquipped(LocalPlayer, "Emotes."..EmoteSlot.Name)
        if #Value <= 0 then
            EmoteSlot.Render.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            EmoteSlot.NameLabel.Text = ""
            continue
        end

        local EmoteInfo = require(Utils.Instance.GetEmoteModule(Value))
        EmoteSlot.Render.Image = EmoteInfo.Config.Render
        EmoteSlot.NameLabel.Text = EmoteInfo.Config.Name
    end
end

function Inventory:ToggleSkinsMenu(Open: boolean?)
    if Open == nil then
        Open = not self.SkinMenu.Open
    end

    if Open then
        self:ToggleInfoMenu(false)
    end
    
    if Open then
        for _, Skin in self.LoadedItems.Skins do
            Skin:Destroy()
        end
        table.clear(self.LoadedItems.Skins)
        self.ItemModules.Skins = self.ItemModules.Skins or {}
        table.clear(self.ItemModules.Skins)

        local charName = self.SelectedItem.Name
        local EquippedSkin = Utils.PlayerData.GetPlayerEquipped(LocalPlayer, "Skins."..charName, false)

        local function CheckSkinEquipLabels()
            for _, Skin in self.LoadedItems.Skins do
                if #EquippedSkin.Value < 0 or EquippedSkin.Value ~= Skin.Name then
                    if Skin.Container.Equipped.ImageTransparency ~= 1 then
                        TweenService:Create(Skin.Container.Equipped, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
                    end
                else
                    if Skin.Container.Equipped.ImageTransparency ~= 0 then
                        TweenService:Create(Skin.Container.Equipped, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
                    end
                end
            end
        end

        for _, Skin in (LocalPlayer.PlayerData.Purchased.Skins:FindFirstChild(self.SelectedItem.Name) or Network:FireServerConnection("CreateMissingPurchasedSkinValue", "REMOTE_FUNCTION", self.SelectedItem.Name)):GetChildren() do
            local Module = Utils.Instance.GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, Skin.Name)
            local Info = require(Module)
            local name = Module.Name

            local Card = Templates.CardTemplate:Clone()
            Card.Name = name
            local Container = Card.Container
            Card.Parent = SkinContainer.ScrollingFrame
            Container.Title.Text = Info.Config.Name
            Container.CharacterRender.Image = Info.Config.Render

            if Info.Config.CardFrame then
                Container.Outline.Image = Info.Config.CardFrame.Image or Container.Outline.Image
                Container.Outline.Size = Info.Config.CardFrame.Size or Container.Outline.Size
            end

            self.LoadedItems.Skins[name] = Card
            self.ItemModules.Skins[name] = Info

            Container.Interact.MouseEnter:Connect(function()
                TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = UDim2.fromScale(1.065, 1.065)
                }):Play()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
            end)
            Container.Interact.MouseLeave:Connect(function()
                TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = Utils.UDim.Full
                }):Play()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
            end)
            Container.Interact.MouseButton1Click:Connect(function()
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
                
                local valueBefore = EquippedSkin.Value
                if EquippedSkin.Value ~= name then
                    Network:FireServerConnection("EquipItem", "REMOTE_EVENT", name, "Skin", "Skins."..charName)
                else
                    Network:FireServerConnection("EquipItem", "REMOTE_EVENT", "", "Skin", "Skins."..charName)
                end

                if EquippedSkin.Value == valueBefore then
                    EquippedSkin.Changed:Wait()
                end

                CheckSkinEquipLabels()
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

        CheckSkinEquipLabels()

        self:ReorderSkins()

        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()

        self.SkinMenu.Open = true
    else
        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()

        self.SkinMenu.Open = false
    end

    TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
end

function Inventory:ToggleInfoMenu(Open: boolean?)
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

        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
        TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
    else
        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()

        self.InfoMenu.Open = false
    end
end

function Inventory:Init()
    UI = Utils.Instance.FindFirstChild(script, "InventoryUI"):Clone()
    UI.Size = Utils.UDim.Zero
    UI.Visible = false
    UI.Parent = UIParent
    self.UIInstance = UI

    local Container = UI.Container
    InventoryContainer = Container.InventoryContainer.Content
    KillerContainer = InventoryContainer.Killers
    SurvivorContainer = InventoryContainer.Survivors
    SkinContainer = Container.SkinsContainer.Content
    EmoteContainer = InventoryContainer.Emotes
    InfoContainer = Container.InfoContainer.Contents

    Sections = {
        KillerContainer,
        SurvivorContainer,
        EmoteContainer,
    }

    for _, button in Container.InventoryContainer.Topbar:GetChildren() do
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

    ButtonsContainer = SideContainer.ButtonsContainer

    Buttons.Equip = ButtonsContainer.Equip
    Buttons.Skins = ButtonsContainer.Skins
    Buttons.Info = ButtonsContainer.MoreInfo

    Equipped.EquippedKiller = Utils.PlayerData.GetPlayerEquipped(LocalPlayer, "Killer", false)
    Equipped.EquippedSurvivor = Utils.PlayerData.GetPlayerEquipped(LocalPlayer, "Survivor", false)

    local JanitorInstance = Janitor.new()
    JanitorInstance:LinkToInstance(UI)

    local BoughtItems: Folder = LocalPlayer.PlayerData.Purchased
    JanitorInstance:Add(BoughtItems.DescendantAdded:Connect(function(_descendant: Instance)
        self:ReloadContent()
    end))
    JanitorInstance:Add(BoughtItems.DescendantRemoving:Connect(function(_descendant: Instance)
        self:ReloadContent()
    end))

    JanitorInstance:Add(Buttons.Equip.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Equip.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    JanitorInstance:Add(Buttons.Equip.MouseButton1Click:Connect(function()
        self:EquipItem()
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

    for _, EmoteSlot: Frame in EmoteContainer.EmoteContainer:GetChildren() do
        JanitorInstance:Add(EmoteSlot.Button.MouseEnter:Connect(function()
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end))
        JanitorInstance:Add(EmoteSlot.Button.MouseLeave:Connect(function()
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end))
        JanitorInstance:Add(EmoteSlot.Button.MouseButton1Click:Connect(function()
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

            if self.EmoteWindow then
                return
            end

            local Slot = EmoteSlot.Name:gsub("Emote", "")
            self.EmoteWindow = EmoteEquipWindow.New(tonumber(Slot), InventoryContainer)
            self.EmoteWindow.Equipped:Connect(function()
                self:ReloadEquippedEmotes()
            end)
            self.EmoteWindow.Removed:Connect(function()
                self:ReloadEquippedEmotes()
                self.EmoteWindow = nil
            end)
        end))
    end

    self:ReloadEquippedEmotes()
    self:ReloadContent()
end

function Inventory:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return "Prevented"
    end

    self:ToggleSkinsMenu(false)
    self:ToggleInfoMenu(false)
    PreviewInstances.Render.Image = ""
    SkinContainer.Parent.Size = Utils.UDim.FullY
    SideContainer.Size = Utils.UDim.FullY
    InfoContainer.Parent.Size = Utils.UDim.FullY
    InventoryContainer.Parent.Size = UDim2.fromScale(0.7, 1)
    self.SkinMenu.Open = false
    if self.EmoteWindow then
        self.EmoteWindow:Hide(true)
        self.EmoteWindow = nil
    end

    TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Full20Offset}):Play()
    self.Opened = true

    return
end

function Inventory:Close(Time: number)
    if self.EmoteWindow then
        self.EmoteWindow:Hide()
    end
    if Time > 0 then
        TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
    else
        UI.Size = Utils.UDim.Zero
        UI.Visible = false
    end
    self.Opened = false
end

function Inventory:Toggle(toggle: boolean)
    if not self.Enabled and toggle then
        self:Init()
    end
    if not toggle and self.Enabled then
        table.clear(self.ItemModules)
        self.LoadedItems = {
            Killers = {},
            Survivors = {},
            Skins = {},
        }
        self.SelectedItem = {
            Name = "",
            Type = "",
        }
        self.SelectedSection = "Survivors"
        self.UIInstance:Destroy()
        self.SkinMenu = {
            Open = false,
        }
        if self.EmoteWindow then
            self.EmoteWindow:Hide(true)
            self.EmoteWindow = nil
        end
    end
    self.Enabled = toggle
end

function Inventory:OnCharButtonPress(codeName: string, info: Types.Killer | Types.Survivor, Type: string)
    if not self.Opened then return end

    PreviewInstances.Render.Image = info.Config.Render
    PreviewInstances.Title.Text = info.Config.Name

    if Equipped["Equipped"..Type].Value == codeName then
        Buttons.Equip.Title.Text = "Equipped"
    else
        Buttons.Equip.Title.Text = "Equip"
    end

    self.SelectedItem.Name = codeName
    self.SelectedItem.Type = Type

    TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play()
end

function Inventory:ReloadContent()
    local BoughtItems = LocalPlayer.PlayerData.Purchased

    --Killer frame reloading

    local Ordered = {}
    local LO = 0

    local function SetupCard(module, Type: "Killer" | "Survivor")
        local name = module.Name

        if self.LoadedItems[Type.."s"][name] then
            self.LoadedItems[Type.."s"][name].LayoutOrder = LO
            return
        end
        
        local Module = Utils.Instance.GetCharacterModule(Type, name)
        if not Module then
            warn(`[Inventory:ReloadContent()]: Couldn't display card for {Type:lower()} "{name}", as their module doesn't exist! Ignoring for now...`)
            return
        end

        local Info = require(Module)

		local Card = Templates.CardTemplate:Clone()
		local Container = Card.Container
		Card.Name = name
		Card.LayoutOrder = LO
		Card.Parent = Type == "Killer" and KillerContainer or SurvivorContainer
		Container.Title.Text = Info.Config.Name
		Container.CharacterRender.Image = Info.Config.Render

        if Info.Config.CardFrame then
            Container.Outline.Image = Info.Config.CardFrame.Image or Container.Outline.Image
            Container.Outline.Size = Info.Config.CardFrame.Size or Container.Outline.Size
        end

        self.ItemModules[Type.."s"] = self.ItemModules[Type.."s"] or {}

		self.LoadedItems[Type.."s"][name] = Card
		self.ItemModules[Type.."s"][name] = Info

		Container.Interact.MouseEnter:Connect(function()
            TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(1.065, 1.065)
            }):Play()
			Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, { Volume = 0.2 })
		end)

		Container.Interact.MouseLeave:Connect(function()
            TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = Utils.UDim.Full
            }):Play()
			Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, { Volume = 0.2 })
		end)

        Container.Interact.MouseButton1Click:Connect(function()
			if self.SkinMenu.Open then
				return
			end
			Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, { Volume = 0.8 })
			self:OnCharButtonPress(name, Info, Type)
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

    local function SetupBatch(Type: "Killer" | "Survivor")
        Ordered = {}
        LO = 0

        for _, module in BoughtItems[Type.."s"]:GetChildren() do
            table.insert(Ordered, Utils.Instance.GetCharacterModule(Type, module.Name))
        end

        SortTableByPriceAndName(Ordered)

        for _, module in ipairs(Ordered) do
            SetupCard(module, Type)
        end
    end

    SetupBatch("Survivor")
    SetupBatch("Killer")

    self:CheckEquipLabels()
end

return Inventory
