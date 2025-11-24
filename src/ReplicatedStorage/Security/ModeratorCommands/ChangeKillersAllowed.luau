return {
    Name = "Maximum Killer Count",
    DisplayedAttribute = "KillersAllowed",
    Executed = function(value: number)
        workspace:SetAttribute("KillersAllowed", value)
    end,
}