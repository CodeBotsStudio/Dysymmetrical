--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local CommonFunctions = RunService:IsServer() and require(ServerScriptService.System.CommonFunctions) or nil
local Character = require(ReplicatedStorage.Classes.Character)
local Ability = require(ReplicatedStorage.Classes.Ability)

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

--Character Definition
local NullexVoyd: Character.Killer = Character:GetDefaultKillerSettings()
NullexVoyd.Config.Name = "Nullex Voyd"
NullexVoyd.Config.Quote = "Order was the first lie."
NullexVoyd.Config.Render = "rbxassetid://139883756028491"
NullexVoyd.Config.Price = 1308

--Abilities Definition

--Slash
local Slash = require(ReplicatedStorage.Classes.Ability.Slash).New()
Slash.Duration = 0.35
--You can also use `NullexVoyd.GameplayConfig.SlashDuration = 0.35`.

--Callback Ping
local Info = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local MasterSoundGroup = SoundService.SoundGroups.Master
local SoundFolder = SoundService.TempSounds

local CallbackPing: Ability.Ability = Ability:GetDefaultAbilitySettings()
CallbackPing.Name = "Callback Ping"
CallbackPing.Description = "Allows Nullex Voyd to see every single alive player's aura for 3 seconds. He gets extremely slowed down while performed."
CallbackPing.Duration = 3
CallbackPing.InputName = "ThirdAbility"
CallbackPing.Cooldown = 32.5
CallbackPing.UseSound = "rbxassetid://72568635961241"

CallbackPing.Behaviour = function(self)
    if RunService:IsServer() then
        return
    end
    task.defer(function()
        local Sound = Instance.new("Sound")
        Sound.Name = self.Name
        Sound.SoundId = self.UseSound

        --muffling all audio except for the callback ping sound
        local Equalizer = Instance.new("EqualizerSoundEffect")
        Equalizer.LowGain = -10
        Equalizer.MidGain = 15
        Equalizer.HighGain = 80
        Equalizer.Parent = Sound

        Sound.Parent = SoundFolder

        Sound:Play()
        Debris:AddItem(Sound, Sound.TimeLength + 1)
    end)

    self.OwnerProperties.SpeedManager:AddSpeedFactor(self.Name, 0.18)
    self.OwnerProperties.FOVManager:AddFOVFactor(self.Name, 0.6)
    self.OwnerProperties.Character:SetAttribute("PreventSlash", true)

    task.defer(function()
        local Equalizer = Instance.new("EqualizerSoundEffect")
        Equalizer.LowGain = 0
        Equalizer.HighGain = 0
        Equalizer.MidGain = 0
        Equalizer.Parent = MasterSoundGroup
        TweenService:Create(Equalizer, Info, {LowGain = 10, MidGain = -15, HighGain = -80}):Play()
        
        task.delay(self.Duration, function() --must not go in self.Connections for it to never stay like that (might change it later)
            TweenService:Create(Equalizer, Info, {LowGain = 0, MidGain = 0, HighGain = 0}):Play()

            task.delay(1, function()
                Equalizer:Destroy()
            end)
        end)
    end)
    
    table.insert(self.Connections, task.delay(self.Duration, function()
        self.OwnerProperties.SpeedManager:RemoveSpeedFactor(self.Name)
        self.OwnerProperties.FOVManager:RemoveFOVFactor(self.Name)
        self.OwnerProperties.Character:SetAttribute("PreventSlash", false)
    end))

    --shows all players' aura
    for _, plr: Model in Utils:GetCharactersWithRoles(false).Survivor or {} do
        Utils:RevealPlayerAura(plr, self.Duration)
    end
end

--Data Anchor
local DataAnchor: Ability.Ability = Ability:GetDefaultAbilitySettings()
DataAnchor.Name = "Data Anchor"
DataAnchor.FirstCooldown = 3
DataAnchor.SecondCooldown = 20
DataAnchor.Cooldown = DataAnchor.FirstCooldown
DataAnchor.Description = "On first use, Nullex Voyd sets up a small device on the floor. When used again, Nullex Voyd gets teleported to that device and it gets destroyed, leaving a longer cooldown."
DataAnchor.InputName = "FirstAbility"
DataAnchor.PlayUseAnimationOnUse = false
DataAnchor.UseAnimation = "rbxassetid://124469822398680"
DataAnchor.PlaceSound = "rbxassetid://5556648575"
NullexVoyd.Config.TeleporterPrefab = script.NullexTeleporter
DataAnchor.Setup = false
DataAnchor.TeleporterInstance = nil
DataAnchor.PositionInfo = CFrame.new()
DataAnchor.DevicePosition = Vector3.new()

DataAnchor.Behaviour = function(self)
    if RunService:IsServer() then
        if self.Setup then
            self.OwnerProperties.Character:PivotTo(self.PositionInfo)

            if self.TeleporterInstance then
                self.TeleporterInstance:Destroy()
            end

            self.PositionInfo = CFrame.new()
            self.Setup = false
        else
            self.Setup = true

            table.insert(self.Connections, task.delay(0.75, function()
                self.DevicePosition = self.OwnerProperties.Character.HumanoidRootPart.Position - Vector3.new(0, 3 * self.OwnerProperties.Character:GetScale(), 0)
                Sounds:PlaySound(self.PlaceSound, {
                    Position = self.DevicePosition,
                    RollOffMaxDistance = 35,
                    RollOffMinDistance = 12,
                    Name = self.Name,
                    SoundGroup = SoundService.SoundGroups.Master.SFX,
                })
            end))
            table.insert(self.Connections, task.delay(0.917, function()
                local TpInstance = NullexVoyd.Config.TeleporterPrefab:Clone()
                TpInstance:PivotTo(CFrame.new(self.DevicePosition))
                TpInstance.Parent = workspace.Map.InGame
                self.PositionInfo = self.OwnerProperties.Character:GetPivot()
                self.TeleporterInstance = TpInstance
            end))
        end
    else
        if self.Setup then
            self.Cooldown = self.FirstCooldown
            self.Setup = false
        else
            self.Cooldown = self.SecondCooldown
            self.Setup = true

            self.OwnerProperties.SpeedManager:AddSpeedFactor(self.Name, 0)

            self.PlayUseAnimation()
            table.insert(self.Connections, task.delay(self.UseAnimationTrack.Length + 0.4, function()
                self.OwnerProperties.SpeedManager:RemoveSpeedFactor(self.Name)
            end))
        end
    end
end

--Overcharge
local Overcharge: Ability.Ability = Ability:GetDefaultAbilitySettings()
Overcharge.Name = "Overcharge"
Overcharge.Description = "Increases walk speed for a very short time but removes the ability to use any ability apart from the slash. When it ends, it lowers his walk speed under default and prevents him from using his abilities for a very very short time (stun)."
Overcharge.Cooldown = 45
Overcharge.InputName = "FourthAbility"
Overcharge.SpeedDuration = 3.2
Overcharge.SpeedLevel = 3
Overcharge.SlownessDuration = 1.5
Overcharge.SlownessLevel = 3
Overcharge.Duration = Overcharge.SpeedDuration + Overcharge.SlownessDuration

Overcharge.Behaviour = function(self)
    if RunService:IsServer() then
        CommonFunctions:ApplyEffect(self.OwnerProperties.Character:FindFirstChildOfClass("Humanoid"), "Speed", self.SpeedLevel, self.SpeedDuration)

        table.insert(self.Connections, task.delay(self.SpeedDuration, function()
            CommonFunctions:ApplyEffect(self.OwnerProperties.Character:FindFirstChildOfClass("Humanoid"), "Slowness", self.SlownessLevel, self.SlownessDuration)
        end))

        return
    end
end

local NullexVoydNameLabel = "<font color=\"rgb(180, 180, 180)\">"..NullexVoyd.Config.Name.."</font>"
NullexVoyd.Config.Description = {
    {
        Type = "Separator",
        Text = "GENERAL INFO",
    },
    {
        Type = "Header",
        Text = "NULLEX VOYD",
    },
    {
        Type = "Quote",
        Text = "\""..NullexVoyd.Config.Quote.."\"",
    },
    {
        Type = "Text",
        Text = "Once a law enforcement automaton built to enforce order, now a void-born executioner of silence. "..
            NullexVoydNameLabel.." hunts those who trespass forbidden truths, warping space to pursue them through shadows. "..
            "With a surge of corrupted energy, he blinks across distance, accelerates beyond human reach, and rends with anomalous force. "..
            "None can hide — his gaze pierces walls, his touch unravels existence itself.",
    },
    {
        Type = "Header",
        Text = "STATS",
    },
    {
        Type = "Text",
        Text = {
            "Difficulty: ★★★☆☆",
            -- "Difficulty: 6 7",
            "Health: "..tostring(NullexVoyd.GameplayConfig.Health),
            "Base Speed: "..tostring(NullexVoyd.GameplayConfig.BaseSpeed),
            "Sprint Speed: "..tostring(math.round(NullexVoyd.GameplayConfig.BaseSpeed * NullexVoyd.GameplayConfig.SprintSpeedMultiplier * 10) / 10),
            "Max Stamina: "..tostring(NullexVoyd.GameplayConfig.StaminaProperties.MaxStamina),
            "Stamina Loss per second: "..tostring(NullexVoyd.GameplayConfig.StaminaProperties.StaminaDrain),
            "Stamina Gain per second: "..tostring(NullexVoyd.GameplayConfig.StaminaProperties.StaminaGain),
        },
    },
    {
        Type = "Separator",
        Text = "ABILITIES",
    },
    {
        Type = "Header",
        Text = "SLASH",
    },
    {
        Type = "Text",
        Text = NullexVoydNameLabel.." performs a basic slash, dealing "..tostring(Slash.Damage).." damage.",
        Image = "rbxassetid://9759886280",
    },
    {
        Type = "Header",
        Text = "CALLBACK PING",
    },
    {
        Type = "Text",
        Text = NullexVoydNameLabel.." slows down for "..tostring(CallbackPing.Duration).." seconds, revealing to him the aura of every single visible & alive survivor in the match that doesn't have <b>Undetectable</b>.",
    },
    {
        Type = "Header",
        Text = "DATA ANCHOR",
    },
    {
        Type = "Text",
        Text = {
            NullexVoydNameLabel.." places a device on the floor, visible to everyone clearly but undestructible.",
            "If this ability is used a second time, "..NullexVoydNameLabel.." will be teleported to this device instantly, destroying it in the process.",
        },
    },
    {
        Type = "Header",
        Text = "OVERCHARGE",
    },
    {
        Type = "Text",
        Text = NullexVoydNameLabel.." overloads his systems with electricity, giving him <b>Speed "..Utils:IntToRoman(Overcharge.SpeedLevel).."</b> for "..tostring(Overcharge.SpeedDuration).." seconds. "..
        "When the effect wears off, his systems will exhaust briefly, inflicting him with <b>Slowness "..Utils:IntToRoman(Overcharge.SlownessLevel).."</b> for "..tostring(Overcharge.SlownessDuration).." seconds.",
    },
}

NullexVoyd.GameplayConfig.Abilities = {
    Slash = Slash,
    CallbackPing = CallbackPing,
    DataAnchor = DataAnchor,
    Overcharge = Overcharge,
}

return NullexVoyd
