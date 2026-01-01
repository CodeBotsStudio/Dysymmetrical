--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local rand = Random.new()

local Types = require(script.Parent.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Network = require(game:GetService("ReplicatedStorage").Modules.Network)

local EmoteClass = {}

--- Emote preset for customization.
function EmoteClass.GetDefaultEmoteSettings(): Types.Emote
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

        AddConnection = function<T>(self: Types.Emote, Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
            self.Janitor:Add(Connection,
                if typeof(Connection) == "thread" then
                    true
                else
                    nil
            )
        end,

        AnimationTracks = {},
        --NOTE: remember to pass the player on init
        Init = function(self: Types.Emote, player: Player)
            self.Owner = player
            self.Janitor = Janitor.new()
            self.Janitor:LinkToInstance(self.Owner.Character)

            if RunService:IsServer() then
                --NOTE: i just noticed that forsaken uses a whole data array to store everything from a player and get the index of it instead of checking it for everyone.
                --it makes more sense.
                self:AddConnection(Network:SetConnection("PlayEmote", "REMOTE_EVENT", function(plr: Player, emoteName: string, soundId: string)
                    if plr == self.Owner and emoteName == self.Config.Name and not self.Owner.Character:GetAttribute("Emoting") then
                        if soundId and #soundId > 0 then
                            Sounds.PlaySound(soundId, {Name = "Emote", Parent = Utils.Character.GetRootPart(self.Owner), Looped = true})
                        end
                        self.Owner.Character:SetAttribute("Emoting", true)

                        Network:FireClientConnection(plr, "PlayEmote", "REMOTE_EVENT", emoteName)

                        if self.Behaviour then
                            self:Behaviour(self.Owner.Character)
                        end
                    end
                end))
                self:AddConnection(Network:SetConnection("StopEmote", "REMOTE_EVENT", function(plr: Player, emoteName: string)
					if plr == self.Owner and emoteName == self.Config.Name then
                        --removing existing emote using `do ... end` to limit the scope of the variables used here
                        do
                            local HRP = Utils.Character.GetRootPart(self.Owner)
                            local ExistingEmote = HRP and HRP:FindFirstChild("Emote")
                            
                            if ExistingEmote then
                                ExistingEmote:Destroy()
                            end
                        end
                        self.Owner.Character:SetAttribute("Emoting", false)

                        Network:FireClientConnection(plr, "StopEmote", "REMOTE_EVENT", emoteName)
                        
                        if self.OnStop then
                            self:OnStop(self.Owner.Character)
                        end
                    end
                end))

                return
            end

            Utils.Misc.PreloadAssets({self.Config.Render, self.AnimationIds, self.SoundIds})

            if typeof(self.AnimationIds) == "string" then
                self.AnimationTracks[self.AnimationIds] = {
                    Animation = Utils.Character.LoadAnimationFromID(self.Owner.Character, self.AnimationIds),
                    Sound = nil,
                }
            else
                for _, id: string in self.AnimationIds do
                    self.AnimationTracks[id] = {
                        Animation = Utils.Character.LoadAnimationFromID(self.Owner.Character, id),
                        Sound = nil,
                    }
                end
            end

            local char = self.Owner.Character
            self.HumanoidRootPart = Utils.Character.GetRootPart(self.Owner)
            self.SpeedManager = require(char.PlayerAttributeScripts.SpeedManager)
            self.TurnToMoveDirection = require(Players.LocalPlayer.PlayerScripts.Miscellaneous.TurnToMoveDirection)

            if self.SoundIds then
                if typeof(self.SoundIds) == "string" then
                    if typeof(self.AnimationIds) == "string" then
                        self.AnimationTracks[self.AnimationIds].Sound = self.SoundIds
                    else
                        for _, id in self.AnimationIds do
                            self.AnimationTracks[id].Sound = self.SoundIds
                        end
                    end
                else
                    for animId, id in self.SoundIds do
                        self.AnimationTracks[animId].Sound = id
                    end
                end
            end

            self:AddConnection(Network:SetConnection("PlayEmote", "REMOTE_EVENT", function(emoteName: string)
                if self.Config.Name == emoteName then
                    if self.TrackPlaying and self.TrackPlaying.Animation.IsPlaying then
                        return
                    end

                    self.TrackPlaying.Animation:Play(0)
                    self.SpeedManager:AddSpeedFactor("Emoting", self.SpeedMultiplier)
                    if self.TurnToMoveDirection.AddHeadPreventionFactor then
                        self.TurnToMoveDirection:AddHeadPreventionFactor("Emoting")
                    end

                    if self.Behaviour then
                        self:Behaviour(self.Owner.Character)
                    end
                end
            end))

            self:AddConnection(Network:SetConnection("StopEmote", "REMOTE_EVENT", function(emoteName: string)
                if emoteName == self.Config.Name and self.TrackPlaying and self.TrackPlaying.Animation then
                    self.TrackPlaying.Animation:Stop(0)
                    self.SpeedManager:RemoveSpeedFactor("Emoting")
                    
                    if self.TurnToMoveDirection.RemoveHeadPreventionFactor then
                        self.TurnToMoveDirection:RemoveHeadPreventionFactor("Emoting")
                    end

                    self.TrackPlaying = nil

                    if self.OnStop then
                        self:OnStop(self.Owner.Character)
                    end
                end
            end))
        end,
        BaseBehaviour = function(self: Types.Emote)
            if RunService:IsServer() then return end

            if self.BaseBehaviourAllowed then
                if self.TrackPlaying and self.TrackPlaying.Animation.IsPlaying then
                    return
                end

                if typeof(self.AnimationIds) == "string" then
                    self.TrackPlaying = self.AnimationTracks[self.AnimationIds]
                else
                    local AsTable = Utils.Type.DictToTable(self.AnimationTracks)
                    self.TrackPlaying = AsTable[rand:NextInteger(1, #AsTable)]
                end

                Network:FireServerConnection("PlayEmote", "REMOTE_EVENT", self.Config.Name, self.TrackPlaying.Sound)
            end
        end,
        Behaviour = function() end,
        OnStop = nil,

        HumanoidRootPart = nil,
        SpeedManager = nil,
        TurnToMoveDirection = nil,

        TrackPlaying = nil,
    }
end

--- Creates an emote with the settings specified in `Props`.
--- 
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function EmoteClass.CreateEmote(Props: Types.Emote): Types.Emote
    Props = Props or {}

    return Utils.Type.DeepTableOverwrite(EmoteClass.GetDefaultEmoteSettings(), Props)
end

return EmoteClass
