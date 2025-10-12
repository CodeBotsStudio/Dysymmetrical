local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

local Resistance: Effect.Effect = Effect:GetDefaultEffect()
Resistance.Name = "Resistance"
Resistance.Description = "Reduces the damage inflicted to the player (produced by the killer, not by the environment or himself)."
Resistance.Duration = 15

return Resistance
