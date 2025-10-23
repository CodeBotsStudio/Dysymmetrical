--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("EquipItem", "REMOTE_EVENT", function(plr: Player, name: string, Type: string, SkinPath: string?)
        if Type == "Skin" and SkinPath then
            Utils:GetPlayerEquipped(plr, SkinPath, false).Value = name
            return
        end

        if not Utils:GetPlayerOwned(plr, Type.."s."..name, false) then
            return
        end

        Utils:GetPlayerEquipped(plr, Type, false).Value = name
    end)
end