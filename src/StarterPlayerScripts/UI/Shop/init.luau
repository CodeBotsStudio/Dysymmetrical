local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SideBar = require(script.Parent.SideBar)
local Types = require(ReplicatedStorage.Classes.Character)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
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
        Card = nil,
    },
    UIInstance = nil,
    BuyWindow = nil,
}

local LocalPlayer = Players.LocalPlayer

local UIParent = CommonUtils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

local Buttons = {
    Purchase = nil,
    Info = nil,
    Skins = nil,
}

local Sizes = {
    SideBar = UDim2.fromScale(0.3, 1),
    ClosedSideBar = CommonUtils.UDim.FullY,
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

local UI
local ShopContainer
local KillerContainer
local SurvivorContainer

local SideContainer
local SkinContainer
local PreviewContainer
local ButtonsContainer

local Sections = {}

--TODO: order by alphabetical order when multiple items have the same price

function Shop:ReorderSkins()
    local Ordered = {
        Owned = {},
        Unowned = {},
    }
    local LO = 0

    for n, i in self.LoadedItems.Skins do
        if CommonUtils:GetPlayerOwned(LocalPlayer, "Skins."..self.SelectedItem.Name.."."..n) then
            table.insert(Ordered.Owned, i)
        else
            table.insert(Ordered.Unowned, i)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        return
            require(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)).Config.Price <
            require(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)).Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        return
            require(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, a.Name)).Config.Price <
            require(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, b.Name)).Config.Price
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
                if CommonUtils:GetPlayerOwned(LocalPlayer, "Skins."..self.SelectedItem.Name.."."..n) then
                    i.Container.Owned.BackgroundTransparency = 0.55
                    i.Container.Owned.TextLabel.TextTransparency = 0
                end
            end
        end

        for _, i in Skins:GetChildren() do
            local Module = CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name, i.Name)

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

        TweenService:Create(ShopContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()

        self.SkinMenu.Open = true
    else
        TweenService:Create(ShopContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.7, 1)}):Play()
        TweenService:Create(SkinContainer.Parent, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()

        self.SkinMenu.Open = false
    end
end

local function SwitchSection(sectionName: string)
    if not Shop.Opened or Shop.SelectedSection == sectionName then return end

    TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 1)}):Play()

    for _, i in Sections do
        i.Visible = i.Name == sectionName
    end

    Shop.SelectedSection = sectionName
end

function Shop:Init()
    UI = CommonUtils:FindFirstChild(script, "ShopUI"):Clone()
    UI.Size = CommonUtils.UDim.Zero
    UI.Parent = UIParent
    self.UIInstance = UI

    local Container = UI.Container
    ShopContainer = Container.ShopContainer.Content
    KillerContainer = ShopContainer.Killers
    SurvivorContainer = ShopContainer.Survivors
    SkinContainer = Container.SkinsContainer.Content

    Sections = {
        KillerContainer,
        SurvivorContainer,
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

    Buttons.Purchase = ButtonsContainer.Purchase
    Buttons.Skins = ButtonsContainer.Skins

    local Conns = {}

    table.insert(Conns, Buttons.Purchase.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Purchase.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end))
    table.insert(Conns, Buttons.Purchase.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        if not CommonUtils:GetPlayerOwned(LocalPlayer, self.SelectedItem.Type.."s."..self.SelectedItem.Name) then
            self:CreateBuyWindow(CommonUtils:GetCharacterModule(self.SelectedItem.Type, self.SelectedItem.Name), false, UI, self.SelectedItem.Card)
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

    table.insert(Conns, UI.Destroying:Connect(function()
        for _, i in Conns do
            i:Disconnect()
        end
    end))

    self:ReloadContent(true)
end

function Shop:Open(Time: number)
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
    ShopContainer.Parent.Size = UDim2.fromScale(0.7, 1)
    self.SkinMenu.Open = false

    TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = CommonUtils.UDim.Full20Offset}):Play()
    self.Opened = true
end

function Shop:Close(Time: number)
    if self.BuyWindow then
        self.BuyWindow:Hide(Time <= 0)
    end
    if Time > 0 then
        TweenService:Create(UI, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = CommonUtils.UDim.Zero}):Play()
    else
        UI.Size = CommonUtils.UDim.Zero
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

function Shop:OnCharButtonPress(codeName: string, info: Types.Killer | Types.Survivor, Module: ModuleScript, Type: string, Card: Frame, skin: boolean?)
    if not self.Opened then
        return
    end

    if skin == nil then
        skin = false
    end

    if not skin then
        PreviewInstances.Render.Image = info.Config.Render
        PreviewInstances.Title.Text = info.Config.Name

        if CommonUtils:GetPlayerOwned(LocalPlayer, Type.."s."..codeName) then
            Buttons.Purchase.Title.Text = "Purchased"
        else
            Buttons.Purchase.Title.Text = "Purchase"
        end

        ButtonsContainer.CurrentItemPrice.Text = info.Config.Price > 0 and tostring(info.Config.Price).."$" or "FREE"

        self.SelectedItem.Name = codeName
        self.SelectedItem.Type = Type
        self.SelectedItem.Card = Card

        TweenService:Create(SideContainer, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Sizes.SideBar}):Play()
    elseif not CommonUtils:GetPlayerOwned(LocalPlayer, Type.."s."..codeName) then
        self:CreateBuyWindow(Module, true, UI, Card)
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
        if CommonUtils:GetPlayerOwned(LocalPlayer, "Killers."..module.Name) then
            table.insert(Ordered.Owned, module)
        else
            table.insert(Ordered.Unowned, module)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        return require(a).Config.Price < require(b).Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        return require(a).Config.Price < require(b).Config.Price
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

        local Module = CommonUtils:GetCharacterModule("Killer", name)
        local KillerInfo: Types.Killer = require(Module)

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = KillerContainer
        Container.Title.Text = KillerInfo.Config.Name
        Container.CharacterRender.Image = KillerInfo.Config.Render
        Container.Price.Text = KillerInfo.Config.Price > 0 and tostring(KillerInfo.Config.Price).."$" or "FREE"

        if CommonUtils:GetPlayerOwned(LocalPlayer, "Killers."..name) then
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
        if CommonUtils:GetPlayerOwned(LocalPlayer, "Survivors."..module.Name) then
            table.insert(Ordered.Owned, module)
        else
            table.insert(Ordered.Unowned, module)
        end
    end

    table.sort(Ordered.Owned, function(a, b)
        return require(a).Config.Price < require(b).Config.Price
    end)
    table.sort(Ordered.Unowned, function(a, b)
        return require(a).Config.Price < require(b).Config.Price
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

        local Module = CommonUtils:GetCharacterModule("Survivor", name)
        local SurvivorInfo: Types.Killer = require(Module)

        local Card = Templates.CardTemplate:Clone()
        local Container = Card.Container
        Card.Name = name
        Card.LayoutOrder = LO
        Card.Parent = SurvivorContainer
        Container.Title.Text = SurvivorInfo.Config.Name
        Container.CharacterRender.Image = SurvivorInfo.Config.Render
        Container.Price.Text = SurvivorInfo.Config.Price > 0 and tostring(SurvivorInfo.Config.Price).."$" or "FREE"

        if CommonUtils:GetPlayerOwned(LocalPlayer, "Survivors."..name) then
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
end

function Shop:CreateBuyWindow(Module: ModuleScript, skin: boolean?, Parent: Frame, Card: Frame)
    if self.BuyWindow then
        return
    end

    local Window = BuyWindow.New(self, Module, skin, Parent, Card)
    Window.Purchased:Connect(function()
        if CommonUtils:GetPlayerOwned(LocalPlayer, self.SelectedItem.Type.."s."..self.SelectedItem.Name) then
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
