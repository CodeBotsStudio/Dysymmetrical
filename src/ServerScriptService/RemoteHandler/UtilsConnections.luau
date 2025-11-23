local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)

return function()
    Network:SetConnection("CreateMissingSkinValue", "REMOTE_FUNCTION", function(SourcePlayer: Player, name: string)
        return Utils:CreateMissingSkinValue(SourcePlayer, name)
    end)
    Network:SetConnection("CreateMissingPurchasedSkinValue", "REMOTE_FUNCTION", function(SourcePlayer: Player, name: string)
        return Utils:CreateMissingPurchasedSkinValue(SourcePlayer, name)
    end)
    Network:SetConnection("GetMousePosition", "REMOTE_FUNCTION", function(v)
        return Utils:_GetMousePosition(v)
    end)
end