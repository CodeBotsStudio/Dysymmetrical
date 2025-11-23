local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local TimeManager = RunService:IsServer() and require(ServerScriptService.Managers.TimeManager) or nil

return {
    Name = "Freeze Timer",
    DisplayedAttribute = "FreezeTime",
    Type = "Bool",
    Executed = function()
        local Enabled = workspace:GetAttribute("FreezeTime")
        workspace:SetAttribute("FreezeTime", not Enabled)
        TimeManager.FreezeTime = not Enabled

        return workspace:GetAttribute("FreezeTime")
    end,
}