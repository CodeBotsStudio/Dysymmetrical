local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Emote = require(ReplicatedStorage.Classes.Emote)

return Emote.New({
    Config = {
        Name = "T-Pose",
        Render = "rbxassetid://134166673644911",
        Quote = "no temas.",
    },
    AnimationIds = "rbxassetid://87300475457340",
    SoundIds = "rbxassetid://1839549655",
    SpeedMultiplier = 0.1,
})
