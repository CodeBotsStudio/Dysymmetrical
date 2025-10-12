local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("EquipItem", "REMOTE_EVENT", function(plr: Player, name: string, Type: string, SkinPath: string?)
        if Type == "Skin" and SkinPath then
            CommonUtils:GetPlayerEquipped(plr, SkinPath, false).Value = name
            return
        end

        CommonUtils:GetPlayerEquipped(plr, Type, false).Value = name
    end)
end