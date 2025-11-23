--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("EquipEmote", "REMOTE_FUNCTION", function(Player: Player, Slot: number, Value: string)
        if #Value <= 0 then
            Utils:GetPlayerEquipped(Player, "Emotes.Emote"..tostring(Slot), false).Value = ""
            return
        end

        if Utils:GetPlayerOwned(Player, "Emotes."..Value) then
            Utils:GetPlayerEquipped(Player, "Emotes.Emote"..tostring(Slot), false).Value = Value
        end
    end)
end