local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Network = require(ReplicatedStorage.Modules.Network)
local Types = require(ReplicatedStorage.Classes.Character)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local LocalPlayer = Players.LocalPlayer

local UIParent = CommonUtils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

local Inventory = {
    Opened = false,
    Enabled = true,
    SelectedSection = "Survivors",
    SkinMenu = {
        Open = false,
        ShowingCharacter = "",
    },
    LoadedItems = {
        Killers = {},
        Survivors = {},
        --Emotes = {},
        Skins = {},
    },
    ItemModules = {},
    SelectedItem = {
        Name = "",
        Type = "",
    },
    UIInstance = nil,
}

local Sizes = {
    SideBar = UDim2.fromScale(0.3, 1),
    ClosedSideBar = CommonUtils.UDim.FullY,
}

local UI
local InventoryContainer
local KillerContainer
local SurvivorContainer

local SideContainer
local SkinContainer
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
}

local Sections = {}

--TODO: order by alphabetical order when multiple items have the same price

function Inventory:ReorderSkins()
    local Ordered = {}
    local LO = 0

    for _, i in self.LoadedItems.Skins do
        table.insert(Ordered, i)
    end

    table.sort(Ordered, function(a, b)
        return
            require(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)).Config.Price <
            require(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)).Config.Price
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

    for _, i in Sections do
        i.Visible = i.Name == sectionName
    end

    Inventory.SelectedSection = sectionName
end

function Inventory:ToggleSkinsMenu(Open: boolean?)
    if Open == nil then
        Open = not self.SkinMenu.Open
    end
    
    if Open then
        for _, i in self.LoadedItems.Skins do
            i:Destroy()
        end
        table.clear(self.LoadedItems.Skins)
        self.ItemModules.Skins = self.ItemModules.Skins or {}
        table.clear(self.ItemModules.Skins)

        local charName = self.SelectedItem.Name
        local EquippedSkin = CommonUtils:GetPlayerEquipped(LocalPlayer, "Skins."..charName, false)

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
            local Module = CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, i.Name)
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

        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()

        self.SkinMenu.Open = true
    else
        TweenService:Create(InventoryContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()

        self.SkinMenu.Open = false
    end
end

function Inventory:Init()
    UI = CommonUtils:FindFirstChild(script, "InventoryUI"):Clone()
    UI.Size = CommonUtils.UDim.Zero
    UI.Parent = UIParent
    self.UIInstance = UI

    local Container = UI.Container
    InventoryContainer = Container.InventoryContainer.Content
    KillerContainer = InventoryContainer.Killers
    SurvivorContainer = InventoryContainer.Survivors
    SkinContainer = Container.SkinsContainer.Content

    Sections = {
        KillerContainer,
        SurvivorContainer,
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

    local templates = CommonUtils:FindFirstChild(script, "Templates")
    Templates.CardTemplate = Templates.CardTemplate or templates.CardTemplate
    Templates.Header = Templates.Header or templates.Header
    Templates.Text = Templates.Text or templates.TextContainer
    Templates.Quote = Templates.Quote or templates.Quote

    SideContainer = Container.SideContainer
    PreviewContainer = SideContainer.PreviewContainer

    PreviewInstances.Render = PreviewContainer.Render
    PreviewInstances.Render.Image = ""
    PreviewInstances.Title = PreviewContainer.Title

    ButtonsContainer = SideContainer.ButtonsContainer

    Buttons.Equip = ButtonsContainer.Equip
    Buttons.Skins = ButtonsContainer.Skins

    Equipped.EquippedKiller = CommonUtils:GetPlayerEquipped(LocalPlayer, "Killer", false)
    Equipped.EquippedSurvivor = CommonUtils:GetPlayerEquipped(LocalPlayer, "Survivor", false)

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

    table.insert(Conns, UI.Destroying:Connect(function()
        for _, i in Conns do
            i:Disconnect()
        end
    end))

    self:ReloadContent()
end

function Inventory:Open(Time: number)
    if not self.Enabled or not LocalPlayer.Character.Role or LocalPlayer.Character.Role.Value ~= "Spectator" or not SideBar.Enabled then
        return
    end
    task.spawn(function()
        SideBar:CloseAll(self)
    end)

    self:ToggleSkinsMenu(false)
    PreviewInstances.Render.Image = ""
    SkinContainer.Parent.Size = CommonUtils.UDim.FullY
    SideContainer.Size = CommonUtils.UDim.FullY
    InventoryContainer.Parent.Size = UDim2.fromScale(0.7, 1)
    self.SkinMenu.Open = false

    TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = CommonUtils.UDim.Full20Offset}):Play()
    self.Opened = true
end

function Inventory:Close(Time: number)
    if Time > 0 then
        TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = CommonUtils.UDim.Zero}):Play()
    else
        UI.Size = CommonUtils.UDim.Zero
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
            --Emotes = {},
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
        return require(CommonUtils:GetCharacterModule("Killer", a.Name)).Config.Price < require(CommonUtils:GetCharacterModule("Killer", b.Name)).Config.Price
    end)

    local function SetupKillerCard(module)
        local name = module.Name

        if self.LoadedItems.Killers[name] then
            self.LoadedItems.Killers[name].LayoutOrder = LO
            return
        end

        local KillerInfo: Types.Killer = require(CommonUtils:GetCharacterModule("Killer", name))

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
        return require(CommonUtils:GetCharacterModule("Survivor", a.Name)).Config.Price < require(CommonUtils:GetCharacterModule("Survivor", b.Name)).Config.Price
    end)

    local function SetupSurvivorCard(module)
        local name = module.Name
        LO += 1

        if self.LoadedItems.Survivors[name] then
            self.LoadedItems.Survivors[name].LayoutOrder = LO
            return
        end

        local SurvivorInfo: Types.Survivor = require(CommonUtils:GetCharacterModule("Survivor", name))

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
