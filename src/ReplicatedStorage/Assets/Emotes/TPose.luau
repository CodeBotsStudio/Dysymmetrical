local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Emote = require(ReplicatedStorage.Classes.Emote)

local TPose: Emote.Emote = Emote:GetDefaultEmoteSettings()
TPose.Config.Name = "T-Pose"
TPose.Config.Quote = "be not afraid."
TPose.AnimationIds = "rbxassetid://87300475457340"
TPose.SoundIds = "rbxassetid://1839549655"
TPose.SpeedMultiplier = 0.1

return TPose
