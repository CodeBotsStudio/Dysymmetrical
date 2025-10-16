local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
--TODO: do this
--TODO: replace all ui (cuz it's from forsaken and i don't want stolen stuff >:( )

local ModPanel = {}

function ModPanel:Init()
    Network:SetConnection("InitModPanel", "REMOTE_EVENT", function()

    end)
end

function ModPanel:Start()
    
end

return ModPanel
