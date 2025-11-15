--!nocheck

local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect:CreateEffect({
    Name = "Resistance",
    Description = "Reduces the damage inflicted to the player (produced by the killer, not by the environment or himself).",
    Duration = 15,
})
