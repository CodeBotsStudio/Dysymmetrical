return {
    Name = "Toggle Ability Charges",
    DisplayedAttribute = "ChargesEnabled",
    Executed = function()
        local Enabled = workspace:GetAttribute("ChargesEnabled")
        workspace:SetAttribute("ChargesEnabled", not Enabled)
    end,
}