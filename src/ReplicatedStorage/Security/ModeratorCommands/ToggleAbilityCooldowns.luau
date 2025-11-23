return {
    Name = "Toggle Ability Cooldowns",
    DisplayedAttribute = "CooldownsEnabled",
    Type = "Bool",
    Executed = function()
        local Enabled = workspace:GetAttribute("CooldownsEnabled")
        workspace:SetAttribute("CooldownsEnabled", not Enabled)

        return workspace:GetAttribute("CooldownsEnabled")
    end,
}