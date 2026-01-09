local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local ItemGUI = {}

local PrefabFolder = script:FindFirstChild("Prefabs")
local Prefabs = {
    Container = PrefabFolder:FindFirstChild("ItemIconContainer"),
    Item = PrefabFolder:FindFirstChild("ItemContainer"),
}

local PossibleKeys = {
	Zero = 10,
	One = 1,
	Two = 2,
	Three = 3,
	Four = 4,
	Five = 5,
	Six = 6,
	Seven = 7,
	Eight = 8, 
	Nine = 9
}

function ItemGUI.InitGUI()
    local Character = Players.LocalPlayer.Character
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

    local Container = Prefabs.Container:Clone()
    Container.Name = "Backpack"
    Container.Parent = Players.LocalPlayer.PlayerGui.CharacterGUI

    local JanitorInstance = Janitor.new()
    JanitorInstance:LinkToInstances(Container, Character)

    local Tools: {Tool} = {}

    JanitorInstance:Add(Players.LocalPlayer.Backpack.ChildAdded:Connect(function(newChild: Instance)
        if not newChild:IsA("Tool") then
            return
        end

        ItemGUI._InitTool(Container, newChild, Humanoid)
    end))
    JanitorInstance:Add(Character.ChildAdded:Connect(function(newChild: Instance)
        if not newChild:IsA("Tool") then
            return
        end

        ItemGUI._InitTool(Container, newChild, Humanoid)
    end))
    JanitorInstance:Add(Players.LocalPlayer.Backpack.ChildRemoved:Connect(function(child: Instance)
        if not child:IsA("Tool") or child.Parent then
            return
        end

        local Index = table.find(Tools, child)
        if Index then
            table.remove(Tools, Index)
        end
    end))
    JanitorInstance:Add(Character.ChildRemoved:Connect(function(child: Instance)
        if not child:IsA("Tool") or child.Parent then
            return
        end

        local Index = table.find(Tools, child)
        if Index then
            table.remove(Tools, Index)
        end
    end))

    JanitorInstance:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
        if gameProcessedEvent then
            return
        end
        
        local Index = PossibleKeys[input.KeyCode.Name]
        if not Index then
            return
        end

        local Tool = Tools[Index]
        if not Tool then
            return
        end

        if Tool.Parent == Character then
            Humanoid:UnequipTools()

            return
        end

        Humanoid:EquipTool(Tool)
    end))

    do
        local ExistingTools: {Tool} = {}
        local ToolInCharacter: Tool = Character:FindFirstChildWhichIsA("Tool")
        if ToolInCharacter then
            table.insert(ExistingTools, ToolInCharacter)
        end

        for _, Item: Instance in ipairs(Players.LocalPlayer.Backpack:GetChildren()) do
            if not Item:IsA("Tool") then
                continue
            end

            table.insert(ExistingTools, Item)
        end

        for _, Item: Tool in ipairs(ExistingTools) do
            ItemGUI._InitTool(Container, Item)
        end
    end

    JanitorInstance:Add(function()
        table.clear(Tools)
    end, true)
end

function ItemGUI._InitTool(Container: Frame, Tool: Tool, Humanoid: Humanoid)
    local FrameJanitor = Janitor.new()
    FrameJanitor:LinkToInstance(Tool)

    local ItemContainer: Frame = Prefabs.Item:Clone()
    ItemContainer.Name = Tool.Name
    ItemContainer.Parent = Container
    local Image = ItemContainer:FindFirstChildWhichIsA("ImageLabel")

    local function ReloadEquipped(Instant: boolean?)
        if Instant == nil then
            Instant = false
        end
        
        local Values = {
            Equipped =  {
                Color = Color3.fromRGB(255, 255, 100),
                Size = UDim2.fromScale(0.6, 0.6),
            },
            Unequipped = {
                Color = Color3.fromRGB(255, 255, 255),
                Size = UDim2.fromScale(0.55, 0.55),
            },
        }
        
        local Group = Tool.Parent == Humanoid.Parent and "Equipped" or "Unequipped"

        if Instant then
            Image.ImageColor3 = Values[Group].Color
            ItemContainer.Size = Values[Group].Size

            return
        end

        local Info = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
        TweenService:Create(Image, Info, {ImageColor3 = Values[Group].Color}):Play()
        TweenService:Create(ItemContainer, Info, {Size = Values[Group].Size}):Play()
    end

    FrameJanitor:Add(Tool.Equipped:Connect(function()
        ReloadEquipped()
    end))
    FrameJanitor:Add(Tool.Unequipped:Connect(function()
        ReloadEquipped()
    end))

    FrameJanitor:Add((Tool:FindFirstChild("Interactor") :: ImageButton).MouseButton1Click:Connect(function()
        if Tool.Parent == Humanoid.Parent then
            Humanoid:UnequipTools()

            return
        end

        Humanoid:EquipTool(Tool)
    end))

    ReloadEquipped(true)
end

return ItemGUI
