--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("EquipEmote", "REMOTE_FUNCTION", function(Player: Player, Slot: number, Value: string)
        if #Value <= 0 then
            CommonUtils:GetPlayerEquipped(Player, "Emotes.Emote"..tostring(Slot), false).Value = ""
            return
        end

        if CommonUtils:GetPlayerOwned(Player, "Emotes."..Value) then
            CommonUtils:GetPlayerEquipped(Player, "Emotes.Emote"..tostring(Slot), false).Value = Value
        end
    end)
end