--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("InitModPanel", "REMOTE_EVENT", function()
        local ModPanel = script.Parent.Parent.UI:FindFirstChild("ModPanel")
        if not ModPanel then
            return
        end

        require(ModPanel):Start()
    end)
end