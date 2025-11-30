--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Emote = require(ReplicatedStorage.Classes.Emote)

return Emote.CreateEmote({
    Config = {
        Name = "T-Pose",
        Quote = "be not afraid.",
    },
    AnimationIds = "rbxassetid://87300475457340",
    SoundIds = "rbxassetid://1839549655",
    SpeedMultiplier = 0.1,
})
