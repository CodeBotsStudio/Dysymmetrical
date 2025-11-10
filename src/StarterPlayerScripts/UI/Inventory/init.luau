--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EmoteEquipWindow = require(script.EmoteEquipWindow)
local SideBar = require(script.Parent.SideBar)
local Network = require(ReplicatedStorage.Modules.Network)
local Types = require(ReplicatedStorage.Classes.Character)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local LocalPlayer = Players.LocalPlayer

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

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

    for _, i in self.LoadedItems.Skins do
        table.insert(Ordered, i)
    end

    table.sort(Ordered, function(a, b)
        local Modules = {
            A = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)),
            B = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    for _, i in Ordered do
        LO += 1
        i.LayoutOrder = LO
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

    for n, f in self.LoadedItems do
        if n == "Skins" then
            continue
        end
        for _, i in f do
            if i.Name == Equipped["Equipped"..n:sub(1, #n - 1)].Value then
                ShowEquippedLabel(i)
            else
                RemoveEquippedLabel(i)
            end
        end
    end
end

function Inventory:EquipItem()
    Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
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

    for _, i in Sections do
        i.Visible = i.Name == sectionName
    end

    Inventory.SelectedSection = sectionName
end

function Inventory:ReloadEquippedEmotes()
    for _, i in EmoteContainer.EmoteContainer:GetChildren() do
        local Value = Utils:GetPlayerEquipped(LocalPlayer, "Emotes."..i.Name)
        if #Value <= 0 then
            i.Render.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            i.NameLabel.Text = ""
            continue
        end

        local EmoteInfo = require(Utils:GetEmoteModule(Value))
        i.Render.Image = EmoteInfo.Config.Render
        i.NameLabel.Text = EmoteInfo.Config.Name
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
        for _, i in self.LoadedItems.Skins do
            i:Destroy()
        end
        table.clear(self.LoadedItems.Skins)
        self.ItemModules.Skins = self.ItemModules.Skins or {}
        table.clear(self.ItemModules.Skins)

        local charName = self.SelectedItem.Name
        local EquippedSkin = Utils:GetPlayerEquipped(LocalPlayer, "Skins."..charName, false)

        local function CheckSkinEquipLabels()
            for _, i in self.LoadedItems.Skins do
                if #EquippedSkin.Value < 0 or EquippedSkin.Value ~= i.Name then
                    if i.Container.Equipped.ImageTransparency ~= 1 then
                        TweenService:Create(i.Container.Equipped, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
                    end
                else
                    if i.Container.Equipped.ImageTransparency ~= 0 then
                        TweenService:Create(i.Container.Equipped, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
                    end
                end
            end
        end

        for _, i in (LocalPlayer.PlayerData.Purchased.Skins:FindFirstChild(self.SelectedItem.Name) or Network:FireServerConnection("CreateMissingPurchasedSkinValue", "REMOTE_FUNCTION", self.SelectedItem.Name)):GetChildren() do
            local Module = Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, i.Name)
            local Info = require(Module)
            local name = Module.Name

            local Card = Templates.CardTemplate:Clone()
            Card.Name = name
            local Container = Card.Container
            Card.Parent = SkinContainer.ScrollingFrame
            Container.Title.Text = Info.Config.Name
            Container.CharacterRender.Image = Info.Config.Render

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
        for _, i in InfoContainer:GetChildren() do
            if not i:IsA("UIComponent") then
                i:Destroy()
            end
        end

        local CharacterInfo = require(Utils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name))

        if not CharacterInfo.Config.Description then
            return
        end

        --TODO: effect descriptions on mouse hover
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

            if Section.Type ~= "Text" then
                local Pref = Templates[Section.Type]:Clone(); --using semicolon because selene is bullshit
                (Section.Type == "Separator" and Pref.Title or Pref).Text = Section.Text
                Pref.Parent = SectionContainer
            else
                local Pref = Templates.Text:Clone()
                Pref.Title.Text = Text
                Pref.Title.MaxVisibleGraphemes = 0
                if Section.Image then
                    Pref.Image.Image = Section.Image
                    Pref.Image.Visible = true
                end
                Pref.Parent = SectionContainer
                TweenService:Create(Pref.Title, TweenInfo.new(0.03 * #Text, Enum.EasingStyle.Linear), {MaxVisibleGraphemes = #Text}):Play()
            end
        end

        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()
        TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()

        self.InfoMenu.Open = true
    else
        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(InfoContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.FullY}):Play()

        self.InfoMenu.Open = false
    end
end

function Inventory:Init()
    UI = Utils:FindFirstChild(script, "InventoryUI"):Clone()
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

    ButtonsContainer = SideContainer.ButtonsContainer

    Buttons.Equip = ButtonsContainer.Equip
    Buttons.Skins = ButtonsContainer.Skins
    Buttons.Info = ButtonsContainer.MoreInfo

    Equipped.EquippedKiller = Utils:GetPlayerEquipped(LocalPlayer, "Killer", false)
    Equipped.EquippedSurvivor = Utils:GetPlayerEquipped(LocalPlayer, "Survivor", false)

    local Conns = {}

    local BoughtItems: Folder = LocalPlayer.PlayerData.Purchased
    table.insert(Conns, BoughtItems.DescendantAdded:Connect(function(_descendant: Instance)
        self:ReloadContent()
    end))
    table.insert(Conns, BoughtItems.DescendantRemoving:Connect(function(_descendant: Instance)
        self:ReloadContent()
    end))

    table.insert(Conns, Buttons.Equip.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Equip.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Equip.MouseButton1Click:Connect(function()
        self:EquipItem()
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

    for _, i: Frame in EmoteContainer.EmoteContainer:GetChildren() do
        table.insert(Conns, i.Button.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end))
        table.insert(Conns, i.Button.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end))
        table.insert(Conns, i.Button.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})

            if self.EmoteWindow then
                return
            end

            local Slot = i.Name:gsub("Emote", "")
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

    local Ordered = BoughtItems.Killers:GetChildren()
    local LO = 0

    table.sort(Ordered, function(a, b)
        local Modules = {
            A = require(Utils:GetCharacterModule("Killer", a.Name)),
            B = require(Utils:GetCharacterModule("Killer", b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    local function SetupKillerCard(module)
        local name = module.Name

        if self.LoadedItems.Killers[name] then
            self.LoadedItems.Killers[name].LayoutOrder = LO
            return
        end

        local KillerInfo: Types.Killer = require(Utils:GetCharacterModule("Killer", name))

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = KillerContainer
        Container.Title.Text = KillerInfo.Config.Name
        Container.CharacterRender.Image = KillerInfo.Config.Render

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
            self:OnCharButtonPress(name, KillerInfo, "Killer")
        end)
    end

    for _, module in Ordered do
        SetupKillerCard(module)
    end
    
    --Survivor frame reloading

    Ordered = BoughtItems.Survivors:GetChildren()
    LO = 0

    table.sort(Ordered, function(a, b)
        local Modules = {
            A = require(Utils:GetCharacterModule("Survivor", a.Name)),
            B = require(Utils:GetCharacterModule("Survivor", b.Name)),
        }

        return
            Modules.A.Config.Price == Modules.B.Config.Price and a.Name < b.Name
            or Modules.A.Config.Price < Modules.B.Config.Price
    end)

    local function SetupSurvivorCard(module)
        local name = module.Name
        LO += 1

        if self.LoadedItems.Survivors[name] then
            self.LoadedItems.Survivors[name].LayoutOrder = LO
            return
        end

        local SurvivorInfo: Types.Survivor = require(Utils:GetCharacterModule("Survivor", name))

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = SurvivorContainer
        Container.Title.Text = SurvivorInfo.Config.Name
        Container.CharacterRender.Image = SurvivorInfo.Config.Render

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
            self:OnCharButtonPress(name, SurvivorInfo, "Survivor")
        end)
    end
    
    for _, module in Ordered do
        SetupSurvivorCard(module)
    end

    self:CheckEquipLabels()
end

return Inventory
