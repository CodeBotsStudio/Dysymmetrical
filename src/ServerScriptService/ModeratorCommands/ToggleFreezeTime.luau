local ServerScriptService = game:GetService("ServerScriptService")

local TimeManager = require(ServerScriptService.Managers.TimeManager)

return {
    Name = "Freeze Timer",
    DisplayedAttribute = "FreezeTime",
    Executed = function()
        local Enabled = workspace:GetAttribute("FreezeTime")
        workspace:SetAttribute("FreezeTime", not Enabled)
        TimeManager.FreezeTime = not Enabled
    end,
}