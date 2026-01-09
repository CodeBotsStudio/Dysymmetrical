local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Types = require(script.Parent.Types)

local Item = {}

function Item.GetDefaultSettings(): Types.Item
    return {
        Name = "Item",

        Init = function(self: Types.Item, Owner: Player)
            --TODO: make this a bit more verbose later
            if not self.ToolPrefab or not self.Owner.Character then
                return
            end

            self.Owner = Owner
            local Character = self.Owner.Character :: Model

            task.defer(function()
                Utils.Misc.PreloadAssets(self.SoundIDs)
            end)

            local Tool = self.ToolPrefab:Clone()

            self.Janitor = Janitor.new()
            self.Janitor:LinkToInstances(Character, Tool)

            if RunService:IsServer() then
                self.OwnerProperties = {
                    Character = Character,
                    Humanoid = Character:FindFirstChildWhichIsA("Humanoid"),
                    HRP = Utils.Character.GetRootPart(Character),
                }

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
                SpeedManager = require(Character.PlayerAttributeScripts.SpeedManager),
                FOVManager = require(Character.PlayerAttributeScripts.FOVManager),
                EffectManager = require(Character.PlayerAttributeScripts.EffectManager),
                EmoteManager = require(Character.Miscellaneous.EmoteManager),
                TurnToMoveDirection = require(self.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
                Sprinting = require(Character.PlayerAbilities.Default.Sprinting),
                AnimationManager = require(Character.AnimationManager),
            }

            for Name, ID in self.AnimationIDs do
                self.OwnerProperties.AnimationManager:LoadAnimation(`{self.Name}.{Name}`, ID)
            end

            self:AddConnection(Tool.Equipped:Connect(function()
                self:Equip()
            end))
            self:AddConnection(Tool.Unequipped:Connect(function()
                self:Unequip()
            end))
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
        end,

        Equip = function(self: Types.Item)
            --playing equip & idle tracks if existent
            local EquipTrack = self.OwnerProperties.AnimationManager:GetAnimationTrack(`{self.Name}.Equip`)
            if EquipTrack then
                self.OwnerProperties.AnimationManager:PlayAnimation(`{self.Name}.Equip`)
                self:AddUseConnection(task.delay(EquipTrack.Length - 0.02, function()
                    self.OwnerProperties.AnimationManager:PlayAnimation(`{self.Name}.Idle`)
                end))
            end

            local EquipSound = self.SoundIDs.Equip
            if EquipSound then
                Sounds.PlaySound(EquipSound, {
                    Parent = self.OwnerProperties.HRP,
                })
            end

            if self.OnEquip then
                self:OnEquip()
            end
        end,

        Unequip = function(self: Types.Item)
            for _, Name in {"Idle", "Equip", "Use"} do
                self.OwnerProperties.AnimationManager:StopAnimation(`{self.Name}.{Name}`)
            end

            local UnequipSound = self.SoundIDs.Unequip
            if UnequipSound then
                Sounds.PlaySound(UnequipSound, {
                    Parent = self.OwnerProperties.HRP,
                })
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
        end,

        OnEquip = nil,
        OnUnequip = nil,

        Behaviour = nil :: any,

        AnimationIDs = {},
        SoundIDs = {},

        AnimationTracks = {},

        AddConnection = function<T>(self: Types.Item, Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
            self.Janitor:Add(Connection,
                if typeof(Connection) == "thread" then
                    true
                else
                    "Disconnect"
            )

            return Connection
        end,
        AddUseConnection = function<T>(self: Types.Item, Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
            self:AddConnection(Connection)
            table.insert(self.UseConnections, Connection)

            return Connection
        end,
        UseConnections = {},

        Owner = nil,
        OwnerProperties = {} :: any,
        Janitor = nil,
    }
end

function Item.New(Props: Types.Item?): Types.Item
    Props = Props or {} :: any
    local Final = Item.GetDefaultSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props :: any)

    return Final
end

return Item
