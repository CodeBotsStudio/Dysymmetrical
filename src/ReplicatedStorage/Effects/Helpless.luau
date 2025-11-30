--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effect = require(ReplicatedStorage.Classes.Effect)

return Effect.CreateEffect({
    Name = "Helpless",
    Description = "Disables a character's abilities during its presence.",
    Duration = 1,
})
