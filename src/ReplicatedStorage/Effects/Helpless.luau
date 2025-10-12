local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effect = require(ReplicatedStorage.Classes.Effect)

local Helpless: Effect.Effect = Effect:GetDefaultEffect()
Helpless.Name = "Helpless"
Helpless.Description = "Disables a character's abilities during its presence."
Helpless.Duration = 1

return Helpless
