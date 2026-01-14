local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Types = require(script.Parent.Types)

local Item = {}
Item.__index = Item

function Item.GetDefaultSettings(): Types.Item
    return setmetatable({
        Name = "Item",

        OnEquip = nil,
        OnUnequip = nil,

        Behaviour = nil :: any,

        AnimationIDs = {},
        SoundIDs = {},

        AnimationTracks = {},

        UseConnections = {},

        Owner = nil,
        OwnerProperties = {} :: any,
        Janitor = nil,
    }, Item)
end

function Item.New(Props: Types.Item?): Types.Item
    Props = Props or {} :: any
    local Final = Item.GetDefaultSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props :: any)

    return Final
end

function Item:Init(Owner: Player, ExistingTool: Tool?)
    self.Owner = Owner

    if not self.Owner.Character then
        return
    end

    if not self.ToolPrefab then
        warn(`[Item:Init()] No tool prefab provided for tool {self.Name}!`, debug.traceback())

        return
    end

    self.Owner = Owner
    local Character = self.Owner.Character :: Model

    task.defer(function()
        Utils.Misc.PreloadAssets(self.SoundIDs)
    end)

    local Tool = ExistingTool
    if not Tool then
        Tool = self.ToolPrefab:Clone()
        Tool.Parent = self.Owner.Backpack
    end
    self.ToolInstance = Tool

    self.Janitor = Janitor.new()
    self.Janitor:LinkToInstances(Character, Tool)

    self:AddConnection(Tool.Equipped:Connect(function()
        self:Equip()
    end))
    self:AddConnection(Tool.Unequipped:Connect(function()
        self:Unequip()
    end))

    if RunService:IsServer() then
        self.OwnerProperties = {
            Character = Character,
            Humanoid = Character:FindFirstChildWhichIsA("Humanoid"),
            HRP = Utils.Character.GetRootPart(Character),
            InputManager = require(self.Owner.PlayerScripts.InputManager),
        }

        self:AddConnection(Tool.Activated:Connect(function()
            local UseSound = self.SoundIDs.Use
            if UseSound then
                Sounds.PlaySound(UseSound, {
                    Parent = self.OwnerProperties.HRP,
                })
            end

            if self.Behaviour then
                self:Behaviour()
            end
        end))

        return
    end

    task.defer(function()
        Utils.Misc.PreloadAssets(self.AnimationIDs)
    end)

    self.OwnerProperties = {
        Character = Character,
        Humanoid = Character:FindFirstChildWhichIsA("Humanoid"),
        HRP = Utils.Character.GetRootPart(Character),
        InputManager = require(self.Owner.PlayerScripts.InputManager),
        FOVManager = require(Character.PlayerAttributeScripts.FOVManager),
        EffectManager = require(Character.PlayerAttributeScripts.EffectManager),
        EmoteManager = require(Character.Miscellaneous.EmoteManager),
        TurnToMoveDirection = require(self.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
        AnimationManager = require(Character.AnimationManager),
    }

    for Name, ID in self.AnimationIDs do
        self.OwnerProperties.AnimationManager:LoadAnimation(`{self.Name}.{Name}`, ID)
    end

    self:AddConnection(Tool.Activated:Connect(function()
        if self.Behaviour then
            self:Behaviour()
        end
    end))
end

function Item:Equip()
    if not RunService:IsServer() then
        --playing equip & idle tracks if existent
        local EquipTrack = self.OwnerProperties.AnimationManager:GetAnimationTrack(`{self.Name}.Equip`)
        if EquipTrack then
            self.OwnerProperties.AnimationManager:PlayAnimation(`{self.Name}.Equip`)
            self:AddUseConnection(task.delay(EquipTrack.Length - 0.02, function()
                self.OwnerProperties.AnimationManager:PlayAnimation(`{self.Name}.Idle`)
            end))
        end
    else
        local EquipSound = self.SoundIDs.Equip
        if EquipSound then
            Sounds.PlaySound(EquipSound, {
                Parent = self.OwnerProperties.HRP,
            })
        end
    end

    if self.OnEquip then
        self:OnEquip()
    end
end

function Item:Unequip()
    if not RunService:IsServer() then
        for _, Name in {"Idle", "Equip", "Use"} do
            self.OwnerProperties.AnimationManager:StopAnimation(`{self.Name}.{Name}`)
        end
    else
        local UnequipSound = self.SoundIDs.Unequip
        if UnequipSound then
            Sounds.PlaySound(UnequipSound, {
                Parent = self.OwnerProperties.HRP,
            })
        end
    end

    for _, Connection in self.UseConnections do
        if typeof(Connection) == "thread" then
            if coroutine.running() ~= Connection then
                task.cancel(Connection)
            end
        else
            Connection:Disconnect()
        end
    end

    if self.OnUnequip then
        self:OnUnequip()
    end
end

function Item:AddConnection<T>(Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
    self.Janitor:Add(Connection,
        if typeof(Connection) == "thread" then
            true
        else
            "Disconnect"
    )

    return Connection
end

function Item:AddUseConnection<T>(Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
    self:AddConnection(Connection)
    table.insert(self.UseConnections, Connection)

    return Connection
end

return Item
