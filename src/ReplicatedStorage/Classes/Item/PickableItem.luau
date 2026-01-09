local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local PickableItem = {}

function PickableItem.GetDefaultSettings(): Types.PickableItem
    return {
        ItemEquivalent = nil,
        Description = "cool item!",
        Model = nil,
        Janitor = nil,

        Init = function(self: Types.PickableItem)

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

function PickableItem.New(Props: Types.PickableItem): Types.PickableItem
    Props = Props or {} :: any
    local Final = PickableItem.GetDefaultSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props :: any)

    return Final
end

return PickableItem
