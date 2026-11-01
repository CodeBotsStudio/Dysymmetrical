local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local CommonFunctions = RunService:IsServer() and require(ServerScriptService.System.CommonFunctions) or nil
local PlayerSpeedManager = RunService:IsServer() and require(game:GetService("ServerScriptService").Managers.PlayerManager.PlayerSpeedManager) or nil
local Character = require(ReplicatedStorage.Classes.Character)
local Ability = require(ReplicatedStorage.Classes.Ability)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local Info = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local MasterSoundGroup = SoundService.SoundGroups.Master
local SoundFolder = SoundService.TempSounds

local function DataAnchorBehaviour(self: Types.Ability)
    if RunService:IsServer() then
        if self.Setup then
            self.OwnerProperties.Character:PivotTo(self.PositionInfo)
        
            if self.TeleporterInstance then
                self.TeleporterInstance:Destroy()
            end
        
            self.PositionInfo = nil
            self.Setup = false
        else
            self.Setup = true

            PlayerSpeedManager.AddSpeedFactor(self.Owner, self.Name, 0)
            self:AddConnection(task.delay(2.1, function()
                PlayerSpeedManager.RemoveSpeedFactor(self.Owner, self.Name)
            end))
            self:AddConnection(task.delay(0.75, function()
                self.DevicePosition = self.OwnerProperties.Character.HumanoidRootPart.Position - Vector3.new(0, 3 * self.OwnerProperties.Character:GetScale(), 0)
                Sounds.PlaySound(self.PlaceSound, {
                    Position = self.DevicePosition,
                    RollOffMaxDistance = 35,
                    RollOffMinDistance = 12,
                    Name = self.Name,
                    SoundGroup = SoundService.SoundGroups.Master.SFX,
                })
            end))
            self:AddConnection(task.delay(0.917, function()
                local TpInstance = self.CharModule.Config.TeleporterPrefab:Clone()
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
            self:PlayUseAnimation()
        end
    end
end

local function CallbackPingBehaviour(self: Types.Ability)
    if RunService:IsServer() then
        PlayerSpeedManager.AddSpeedFactor(self.Owner, self.Name, 0.18)
        self.OwnerProperties.Character:SetAttribute("PreventSlash", true)

        self:AddConnection(task.delay(self.Duration, function()
            PlayerSpeedManager.RemoveSpeedFactor(self.Owner, self.Name)
            self.OwnerProperties.Character:SetAttribute("PreventSlash", false)
        end))

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

    self.OwnerProperties.FOVManager:AddFOVFactor(self.Name, 0.6)

    task.defer(function()
        local Equalizer = Instance.new("EqualizerSoundEffect")
        Equalizer.LowGain = 0
        Equalizer.HighGain = 0
        Equalizer.MidGain = 0
        Equalizer.Parent = MasterSoundGroup
        TweenService:Create(Equalizer, Info, {LowGain = 10, MidGain = -15, HighGain = -80}):Play()

        self:AddConnection(task.delay(self.Duration, function()
            TweenService:Create(Equalizer, Info, {LowGain = 0, MidGain = 0, HighGain = 0}):Play()
        
            self:AddConnection(task.delay(1, function()
                Equalizer:Destroy()
            end))
        end))
    end)

    self:AddConnection(task.delay(self.Duration, function()
        self.OwnerProperties.FOVManager:RemoveFOVFactor(self.Name)
    end))

    --shows all players' aura
    for _, plr: Model in Utils.Character.GetCharactersWithRoles(false).Survivor or {} do
        Utils.Player.RevealPlayerAura(plr, self.Duration)
    end
end

function OverchargeBehaviour(self: Types.Ability)
    if RunService:IsServer() then
        CommonFunctions.ApplyEffect({
            TargetHumanoid = self.OwnerProperties.Character:FindFirstChildWhichIsA("Humanoid"),
            EffectSettings = {
                Name = "Speed", 
                Level = self.SpeedLevel, 
                Duration = self.SpeedDuration
            }
        })

        self:AddConnection(task.delay(self.SpeedDuration, function()
            CommonFunctions.ApplyEffect({
                TargetHumanoid = self.OwnerProperties.Character:FindFirstChildWhichIsA("Humanoid"),
                EffectSettings = {
                    Name = "Slowness", 
                    Level = self.SlownessLevel, 
                    Duration = self.SlownessDuration
                }
            })
        end))
    
        return
    end
end

--Character Definition
local NullexVoyd: Types.Killer = Character.CreateKiller({
    Config = {
        Name = "Nullex Voyd",
        Quote = "El orden fue la primera mentira.",
        Render = "rbxassetid://139883756028491",
        Price = 1308,

        Origin = {
            TooltipText = "¡Viene del Proyecto Terminus!",
            Icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        },

        TeleporterPrefab = script.NullexTeleporter,
    },
    
    GameplayConfig = {
        Abilities = {

            --Slash
            Slash = require(ReplicatedStorage.Classes.Ability.Slash).New({
                Duration = 0.35
            }),

            DataAnchor = Ability.New({
                Name = "Data Anchor",

                FirstCooldown = 3,
                SecondCooldown = 20,

                Cooldown = 3,

                InputName = "FirstAbility",

                PlayUseAnimationOnUse = false,
                UseAnimation = "rbxassetid://124469822398680",
                PlaceSound = "rbxassetid://5556648575",

                TeleporterInstance = nil,
                Setup = false,
                PositionInfo = CFrame.new(),

                Behaviour = DataAnchorBehaviour,
            }),

            CallbackPing = Ability.New({
                Name = "Callback Ping",
                Duration = 3,
                InputName = "ThirdAbility",
                Cooldown = 32.5,
                UseSound = "rbxassetid://72568635961241",
                Behaviour = CallbackPingBehaviour,
            }),

            Overcharge = Ability.New({
                Name = "Overcharge",
                Cooldown = 45,
                InputName = "FourthAbility",
                SpeedDuration = 3.2,
                SpeedLevel = 3,
                SlownessDuration = 1.5,
                SlownessLevel = 3,
                Duration = 4.7,
                DisableSlashOnPerform = false,
                Behaviour = OverchargeBehaviour,
            }),
        },
    },
})

local NullexVoydNameLabel = "<font color=\"rgb(180, 180, 180)\">"..NullexVoyd.Config.Name.."</font>"
NullexVoyd.Config.Description = {
    {
        Type = "Separator",
        Text = "INFORMACIÓN GENERAL",
    },
    {
        Type = "Header",
        Text = NullexVoyd.Config.Name:upper(),
    },
    {
        Type = "Quote",
        Text = "\""..NullexVoyd.Config.Quote.."\"",
    },
    {
        Type = "Text",
        Text = "Antes era un autómata policial creado para imponer el orden; ahora es un verdugo del silencio nacido del vacío. "..
            NullexVoydNameLabel.." caza a quienes cruzan verdades prohibidas y deforma el espacio para perseguirlos entre las sombras. "..
            "Con una descarga de energía corrupta salta distancias, acelera más allá de lo humano y desgarra con fuerza anómala. "..
            "Nadie puede esconderse: su mirada atraviesa paredes y su toque deshace la existencia misma.",
    },
    {
        Type = "Header",
        Text = "ESTADÍSTICAS",
    },
    {
        Type = "Text",
        Text = {
            "Dificultad: ★★★☆☆",
            -- "Difficulty: 6 7",
            "Vida: "..tostring(NullexVoyd.GameplayConfig.Health),
            "Velocidad base: "..tostring(NullexVoyd.GameplayConfig.BaseSpeed),
            "Velocidad al correr: "..tostring(math.round(NullexVoyd.GameplayConfig.BaseSpeed * NullexVoyd.GameplayConfig.SprintSpeedMultiplier * 10) / 10),
            "Aguante máximo: "..tostring(NullexVoyd.GameplayConfig.StaminaProperties.MaxStamina),
            "Aguante perdido por segundo: "..tostring(NullexVoyd.GameplayConfig.StaminaProperties.StaminaDrain),
            "Aguante recuperado por segundo: "..tostring(NullexVoyd.GameplayConfig.StaminaProperties.StaminaGain),
        },
    },
    {
        Type = "Separator",
        Text = "HABILIDADES",
    },
    {
        Type = "Header",
        Text = NullexVoyd.GameplayConfig.Abilities.Slash.Name:upper(),
    },
    {
        Type = "Text",
        Text = NullexVoydNameLabel.." lanza un tajo básico que hace "..tostring(NullexVoyd.GameplayConfig.Abilities.Slash.Damage).." de daño.",
        Image = "rbxassetid://9759886280",
    },
    {
        Type = "Header",
        Text = NullexVoyd.GameplayConfig.Abilities.CallbackPing.Name:upper(),
    },
    {
        Type = "Text",
        Text = NullexVoydNameLabel.." se ralentiza durante "..tostring(NullexVoyd.GameplayConfig.Abilities.CallbackPing.Duration).." segundos y ve el aura de cada superviviente vivo y visible de la partida que no tenga <b>Indetectable</b>.",
    },
    {
        Type = "Header",
        Text = NullexVoyd.GameplayConfig.Abilities.DataAnchor.Name:upper(),
    },
    {
        Type = "Text",
        Text = {
            NullexVoydNameLabel.." coloca un dispositivo en el suelo que todos ven con claridad y que no se puede destruir.",
            "Si usa esta habilidad otra vez, "..NullexVoydNameLabel.." se teletransporta al instante al dispositivo y lo destruye.",
        },
    },
    {
        Type = "Header",
        Text = NullexVoyd.GameplayConfig.Abilities.Overcharge.Name:upper(),
    },
    {
        Type = "Text",
        Text = NullexVoydNameLabel.." sobrecarga sus sistemas con electricidad y gana <b>Velocidad "..Utils.Math.IntToRoman(NullexVoyd.GameplayConfig.Abilities.Overcharge.SpeedLevel).."</b> durante "..tostring(NullexVoyd.GameplayConfig.Abilities.Overcharge.SpeedDuration).." segundos. "..
        "Cuando se acaba, sus sistemas se agotan un momento y sufre <b>Lentitud "..Utils.Math.IntToRoman(NullexVoyd.GameplayConfig.Abilities.Overcharge.SlownessLevel).."</b> durante "..tostring(NullexVoyd.GameplayConfig.Abilities.Overcharge.SlownessDuration).." segundos.",
    },
}

return NullexVoyd
