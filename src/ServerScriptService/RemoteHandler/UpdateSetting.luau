local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("UpdateSetting", "REMOTE_EVENT", function(sourcePlayer, ValueObj, Value)
        if not ValueObj:IsDescendantOf(sourcePlayer.PlayerData.Settings) then --forgot to do this to not let people fucking cheat everything
            return
        end

        ValueObj.Value = Value
    end)
end