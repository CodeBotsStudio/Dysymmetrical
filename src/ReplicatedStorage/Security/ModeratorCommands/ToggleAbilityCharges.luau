return {
    Name = "Toggle Ability Charges",
    DisplayedAttribute = "ChargesEnabled",
    Type = "Bool",
    Executed = function()
        local Enabled = workspace:GetAttribute("ChargesEnabled")
        workspace:SetAttribute("ChargesEnabled", not Enabled)

        return workspace:GetAttribute("ChargesEnabled")
    end,
}