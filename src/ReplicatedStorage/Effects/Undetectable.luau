local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

local Undetectable: Effect.Effect = Effect:GetDefaultEffect()
Undetectable.Name = "Undetectable"
Undetectable.Description = "Makes the player's aura invisible for the duration of the effect."
Undetectable.Duration = 15

return Undetectable
