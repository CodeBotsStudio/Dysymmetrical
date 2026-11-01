local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

return Effect.New({
    Name = "Resistance",
    Description = "Reduce el daño que recibe el jugador del asesino (no el del entorno ni el propio).",
    Duration = 15,
})
