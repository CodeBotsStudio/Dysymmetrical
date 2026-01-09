local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil

local PickableItem = {}

function PickableItem.GetDefaultSettings(): Types.PickableItem
    return {
        ItemEquivalent = nil,
        Description = "cool item!",
        Model = nil,
        Janitor = nil,

        Init = function(self: Types.PickableItem)
            print("initting uhhh ig")

            if not RunService:IsServer() or not self.Model then
                warn(`Can't initialize item {self.ItemEquivalent and self.ItemEquivalent.Name or self.DisplayName or "UNKNOWN"}!`, debug.traceback())
                return
            end

            local ModelInstance = self.Model:Clone()

            self.Janitor = Janitor.new()
            self.Janitor:LinkToInstance(ModelInstance)

            do
                local Prompt = ModelInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not Prompt then
                    Prompt = Instance.new("ProximityPrompt")
                    Prompt.Parent = ModelInstance.PrimaryPart or ModelInstance
                end

                self:AddConnection(Prompt.Triggered:Connect(function(Player: Player)
                    local Role = Player.Character:FindFirstChild("Role")
                    if not Role or Role.Value ~= "Survivor" then
                        return
                    end

                    task.spawn(CommonFunctions.GivePhysicalItemToPlayer, Player, self.ItemEquivalent)

                    ModelInstance:Destroy()
                end))
            end

            ModelInstance.Parent = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Items") or workspace.TempObjectFolders
        end,

        AddConnection = function<T>(self: Types.PickableItem, Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
            self.Janitor:Add(Connection,
                if typeof(Connection) == "thread" then
                    true
                else
                    "Disconnect"
            )

            return Connection
        end,
    }
end

function PickableItem.New(Props: Types.PickableItem?): Types.PickableItem
    Props = Props or {} :: any
    local Final = PickableItem.GetDefaultSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props :: any)

    return Final
end

return PickableItem
