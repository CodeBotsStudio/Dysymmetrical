--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local rand = Random.new()

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Network = require(game:GetService("ReplicatedStorage").Modules.Network)

local EmoteClass = {}

export type Emote = {
    Config: {
        Name: string,
        Quote: string,
        Author: string,
        Render: string,
        Price: number,
    },

    AnimationIds: {string} | string,
    SoundIds: {[string]: string}? | string?,
    SpeedMultiplier: number,
    BaseBehaviourAllowed: boolean,

    AnimationTracks: { [string]: {AnimationTrack} },
    Init: (own: Emote, owner: Player, animator: Animator) -> (),
    BaseBehaviour: (own: Emote) -> (),
    Behaviour: (own: Emote) -> (),

    Animator: Animator,
    HumanoidRootPart: BasePart,
    SpeedManager: {any},
    TurnToMoveDirection: {any},

    TrackPlaying: AnimationTrack,
    Connections: {RBXScriptConnection},

    Owner: Player,
}

local function dictLength(dict: {[string]: any}): number
    local length = 0

    for _, _ in dict do
        length += 1
    end

    return length
end

--- Emote preset for customization.
function EmoteClass:GetDefaultEmoteSettings(): Emote
    return {
        Config = {
            Name = "Emote",
            Quote = "\"hey guys what's up dys here\"",
            Author = "idk lol",
            Render = "rbxasset://textures/ui/GuiImagePlaceholder.png",
            Price = 300,
        },

        AnimationIds = {},
        SoundIds = {},
        SpeedMultiplier = 0,
        BaseBehaviourAllowed = true,

        Connections = {},

        AnimationTracks = {},
        --NOTE: remember to pass the player on init
        Init = function(own: Emote, player: Player, animator: Animator)
            own.Owner = player
            own.Animator = animator

            if RunService:IsServer() then
                --NOTE: i just noticed that forsaken uses a whole data array to store everything from a player and get the index of it instead of checking it for everyone.
                --it makes more sense.
                table.insert(own.Connections, Network:SetConnection("PlayEmote", "REMOTE_EVENT", function(plr: Player, emoteName: string, soundId: string)
                    if plr == own.Owner and emoteName == own.Config.Name and not own.Owner.Character:GetAttribute("Emoting") then
                        if soundId and #soundId > 0 then
                            Sounds:PlaySound(soundId, {Name = "Emote", Parent = own.Owner.Character:FindFirstChild("HumanoidRootPart"), Looped = true})
                        end
                        own.Owner.Character:SetAttribute("Emoting", true)

                        Network:FireClientConnection(plr, "PlayEmote", "REMOTE_EVENT", emoteName)
                    end
                end))
                table.insert(own.Connections, Network:SetConnection("StopEmote", "REMOTE_EVENT", function(plr: Player, emoteName: string)
					if plr == own.Owner and emoteName == own.Config.Name then
                        if own.Owner.Character:FindFirstChild("HumanoidRootPart") and own.Owner.Character.HumanoidRootPart:FindFirstChild("Emote") then
                            own.Owner.Character.HumanoidRootPart.Emote:Destroy()
                        end
                        own.Owner.Character:SetAttribute("Emoting", false)

                        Network:FireClientConnection(plr, "StopEmote", "REMOTE_EVENT", emoteName)
                    end
                end))

                table.insert(own.Connections, own.Owner.CharacterAdded:Connect(function()
                    for _, i in own.Connections do
                        i:Disconnect()
                    end
                end))

                return
            end

            Utils:PreloadAssets({own.Config.Render, own.AnimationIds, own.SoundIds})

            if typeof(own.AnimationIds) == "string" then
                own.AnimationTracks[own.AnimationIds] = {
                    Animation = Utils:LoadAnimationFromID(own.Owner.Character, own.AnimationIds),
                    Sound = nil,
                }
            else
                for _, id: string in own.AnimationIds do
                    own.AnimationTracks[id] = {
                        Animation = Utils:LoadAnimationFromID(own.Owner.Character, id),
                        Sound = nil,
                    }
                end
            end

            local char = own.Owner.Character
            own.HumanoidRootPart = char.HumanoidRootPart
            own.SpeedManager = require(char.PlayerAttributeScripts.SpeedManager)
            own.TurnToMoveDirection = require(Players.LocalPlayer.PlayerScripts.Miscellaneous.TurnToMoveDirection)

            if own.SoundIds then
                if typeof(own.SoundIds) == "string" then
                    if typeof(own.AnimationIds) == "string" then
                        own.AnimationTracks[own.AnimationIds].Sound = own.SoundIds
                    else
                        for _, id in own.AnimationIds do
                            own.AnimationTracks[id].Sound = own.SoundIds
                        end
                    end
                else
                    for animId, id in own.SoundIds do
                        own.AnimationTracks[animId].Sound = id
                    end
                end
            end

            table.insert(own.Connections, Network:SetConnection("PlayEmote", "REMOTE_EVENT", function(emoteName: string)
                if own.Config.Name == emoteName then
                    if own.TrackPlaying and own.TrackPlaying.Animation.IsPlaying then
                        return
                    end

                    own.TrackPlaying.Animation:Play(0)
                    own.SpeedManager:AddSpeedFactor("Emoting", own.SpeedMultiplier)
                    if own.TurnToMoveDirection.AddHeadPreventionFactor then
                        own.TurnToMoveDirection:AddHeadPreventionFactor("Emoting")
                    end

                    own:Behaviour()
                end
            end))

            table.insert(own.Connections, Network:SetConnection("StopEmote", "REMOTE_EVENT", function(emoteName: string)
                if emoteName == own.Config.Name and own.TrackPlaying and own.TrackPlaying.Animation then
                    own.TrackPlaying.Animation:Stop(0)
                    own.SpeedManager:RemoveSpeedFactor("Emoting")
                    if own.TurnToMoveDirection.RemoveHeadPreventionFactor then
                        own.TurnToMoveDirection:RemoveHeadPreventionFactor("Emoting")
                    end
                    own.TrackPlaying = nil
                end
            end))

            table.insert(own.Connections, own.Owner.CharacterAdded:Connect(function()
                for _, i in own.Connections do
                    i:Disconnect()
                end
            end))
        end,
        BaseBehaviour = function(own: Emote)
            if RunService:IsServer() then return end

            if own.BaseBehaviourAllowed then
                if own.TrackPlaying and own.TrackPlaying.Animation.IsPlaying then
                    return
                end

                if typeof(own.AnimationIds) == "string" then
                    own.TrackPlaying = own.AnimationTracks[own.AnimationIds]
                else
                    own.TrackPlaying = own.AnimationTracks[rand:NextInteger(1, dictLength(own.AnimationTracks))]
                end

                Network:FireServerConnection("PlayEmote", "REMOTE_EVENT", own.Config.Name, own.TrackPlaying.Sound)
            end
        end,
        Behaviour = function() end,

        Animator = nil,
        HumanoidRootPart = nil,
        SpeedManager = nil,
        TurnToMoveDirection = nil,

        TrackPlaying = nil,
    }
end

return EmoteClass
