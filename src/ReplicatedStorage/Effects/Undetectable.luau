--!nocheck

local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect.CreateEffect({
    Name = "Undetectable",
    Description = "Makes the player's aura invisible for the duration of the effect.",
    Duration = 15,
})
