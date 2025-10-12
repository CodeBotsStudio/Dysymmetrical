local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
return function()
    Network:SetConnection("SetupMapBehaviour", "REMOTE_EVENT", function()
        require(workspace:FindFirstChild("Map"):FindFirstChild("Behaviour")):Init()
    end)
end