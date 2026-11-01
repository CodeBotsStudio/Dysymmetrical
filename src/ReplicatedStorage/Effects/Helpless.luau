local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effect = require(ReplicatedStorage.Classes.Effect)

return Effect.New({
    Name = "Helpless",
    Description = "Desactiva las habilidades del personaje mientras dura.",
    Duration = 1,
})
