return {
    Name = "Toggle Ability Cooldowns",
    DisplayedAttribute = "CooldownsEnabled",
    Executed = function()
        local Enabled = workspace:GetAttribute("CooldownsEnabled")
        workspace:SetAttribute("CooldownsEnabled", not Enabled)
    end,
}