local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
return function()
    Network:SetConnection("Print", "UREMOTE_EVENT", function(messageType: Enum.MessageType, ...)
        if workspace:GetAttribute("DebugAllowed") ~= true then
            return
        end
        if messageType == Enum.MessageType.MessageError then
            error(...)
        elseif messageType == Enum.MessageType.MessageWarning then
            warn(...)
        else
            print(...)
        end
    end)
end