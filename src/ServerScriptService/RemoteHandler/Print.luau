local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Modules.Network)

return function()
    LogService.MessageOut:Connect(function(message, messageType)
        if workspace:GetAttribute("DebugAllowed") ~= true or RunService:IsStudio() then
            return
        end
        if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
            Network:FireAllClientConnection("Print", "UREMOTE_EVENT", messageType, message)
        end
    end)
end