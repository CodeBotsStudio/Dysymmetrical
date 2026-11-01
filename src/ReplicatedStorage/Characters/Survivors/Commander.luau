local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Character = require(ReplicatedStorage.Classes.Character)
local Ability = require(ReplicatedStorage.Classes.Ability)
local Hitbox = require(ReplicatedStorage.Classes.Hitbox)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil
local PlayerSpeedManager = RunService:IsServer() and require(game:GetService("ServerScriptService").Managers.PlayerManager.PlayerSpeedManager) or nil

local function BlindsideBehaviour(self: Types.Ability)
    if RunService:IsServer() then
        local AnimatedGrenade = self.OwnerProperties.Character:FindFirstChild("Grenade")
        AnimatedGrenade.Transparency = 0

        self:AddConnection(task.delay(self.ThrowDelay, function()
            local FunctionalGrenade = AnimatedGrenade:Clone()
            local Joint = FunctionalGrenade:FindFirstChildWhichIsA("JointInstance")
            if Joint then
                Joint:Destroy()
            end
            FunctionalGrenade.Name = "ActiveFlashGrenade"
            FunctionalGrenade.CanCollide = true
            FunctionalGrenade.CollisionGroup = "Items"
            FunctionalGrenade.AssemblyLinearVelocity = (self.OwnerProperties.Character.HumanoidRootPart.CFrame.LookVector + Vector3.new(0, 0.5, 0)) * self.ThrowForce
            FunctionalGrenade.Parent = workspace:FindFirstChild("Map") and workspace.Map.InGame or workspace.TempObjectFolders

            AnimatedGrenade.Transparency = 1
        
            self:AddConnection(task.delay(self.TriggerDelay, function()
                task.spawn(function()
                    Hitbox.New(self.Owner, {
                        CFrame = CFrame.new(FunctionalGrenade.Position),
                        Size = Vector3.new(35, 35, 35),
                        Damage = 0,
                        Time = 1/40 * 3,
                        Shape = Enum.PartType.Ball,
                        EffectsToApply = {
                            {
                                Name = "Blindness",
                                Duration = 4,
                                Level = 1,
                            },
                        },
                        Connections = {
                            PostHit = function(Config: Types.HitboxSettings, Hum: Humanoid)
                                CommonFunctions.GrantRewardToPlayer(self.Owner, {Money = 10, EXP = 20, Reason = "cegar al asesino con Blindside"})
                            end,
                        }
                    })
                end)
            
                local Light = FunctionalGrenade:FindFirstChildWhichIsA("PointLight")
                Light.Enabled = true
                TweenService:Create(Light, TweenInfo.new(0.1), {Brightness = 0}):Play()
            
                FunctionalGrenade:FindFirstChildWhichIsA("ParticleEmitter"):Emit(80)
            
                self:AddConnection(task.delay(0.1, function()
                    FunctionalGrenade.Transparency = 1
                    Light.Enabled = false
                
                    Debris:AddItem(FunctionalGrenade, 8)
                end))
            end))
        end))

        return
    end
end

local function ReloadBehaviour(self: Types.Ability)
    if RunService:IsServer() then
        self:AddConnection(task.delay(self.Duration, function()
            self.CharModule.GameplayConfig.Abilities.Justice:ChangeAbilityCharges("Set", 1)
        end))

        CommonFunctions.ApplyEffect({
            TargetHumanoid = self.OwnerProperties.Humanoid,
            EffectSettings = {
                Name = "Slowness",
                Level = 3,
                Duration = 5,
            },
        })

        return
    end
end

local function JusticeExtraInit(self: Types.Ability)
    self.JusticeModel = Utils.Instance.FindFirstChild(self.OwnerProperties.Character, "Deagle")
end

local function JusticeBehaviour(self: Types.Ability)
    if not RunService:IsServer() then
        return
    end
    
    --Shot Sound & Hitbox
    self:AddConnection(task.delay(1.17, function()
        task.spawn(function()
            Hitbox.New(self.Owner, {
                CFrameOffset = CFrame.new(0, 0, -(self.HitboxLength / 2)),
                Size = Vector3.new(3, 1.5, self.HitboxLength),
                Time = self.Duration,
                Reason = "el disparo",
                Damage = self.Damage,
                EffectsToApply = {
                    {
                        Name = "Stunned",
                        Level = 1,
                        Duration = self.StunTime,
                        Subfolder = "KillerSpecific"
                    },
                },
                Connections = {
                    PostHit = function(Config: Types.HitboxSettings, Hum: Humanoid)
                        CommonFunctions.GrantRewardToPlayer(self.Owner, {Money = 6, EXP = 14, Reason = "aturdir al asesino con Justice"})
                    end,
                }
            })
        end)
    
        local FirePart = self.JusticeModel.FirePart
        FirePart.Burst:Emit(4)
        FirePart.Front:Emit(12)
        FirePart.Smoke:Emit(8)
        FirePart.Flash:Emit(3)
        Sounds.PlaySound(self.ShotSound, {Volume = 2}, {
            Position = FirePart.Position,
        })
    end))

    --Hide
    self:AddConnection(task.delay(2, function()
        for _, Part in self.JusticeModel:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.Transparency = 1
            end
        end
    end))

    task.spawn(function()
        PlayerSpeedManager.AddSpeedFactor(self.Owner, self.Name, 0.3)
        self:AddConnection(task.delay(self.UseAnimationTrack and self.UseAnimationTrack.Length or self.Duration, function()
            PlayerSpeedManager.RemoveSpeedFactor(self.Owner, self.Name)
        end))
    end)

    --Show
    for _, Part in self.JusticeModel:GetDescendants() do
        if Part:IsA("BasePart") and not Part:HasTag("Transparent") then
            Part.Transparency = 0
        end
    end
end

local function OnCommanderHit(_self: Types.Survivor, _hitbox: Types.HitboxDetails, _damage: number, humanoid: Humanoid)
    CommonFunctions.ApplyEffect({
        TargetHumanoid = humanoid,
        EffectSettings = {
            Name = "Resistance",
            Level = 2,
            Duration = 1,
        },
    })
end

local Commander: Types.Survivor = Character.CreateSurvivor({
    Config = {
        Name = "Commander",
        Quote = "*pyro noises*",
        Render = "rbxassetid://108440668883002",

        Origin = {
            TooltipText = "¡Viene del Proyecto Terminus!",
            Icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        },
    },

    GameplayConfig = {
        Abilities = {
            BodyArmor = Ability.New({
                Name = "Body Armor",
                -- Description = "Every time Commander gets damaged, he receives Resistance V for 1 second, acting as invincibility frames.",
                Passive = true,
            }),

            Blindside = Ability.New({
                Name = "Blindside",

                ThrowDelay = 1,
                TriggerDelay = 3.5,
                FlashTime = 3.5,
                FlashRadius = 6,
                ThrowForce = 60,

                -- Description = "Commander picks up a flashbang grenade and throws it after 3.5 seconds, triggering it after 3.5 seconds and flashing the killer for 3.5 seconds if they're in a 6 stud radius.",

                Cooldown = 30,
                InputName = "FirstAbility",
                Duration = 2,

                Behaviour = BlindsideBehaviour,
            }),

            Reload = Ability.New({
                Name = "Reload",
                Duration = 5,
                Cooldown = 40,
                InputName = "SecondAbility",
                SlownessLevel = 3,
                -- Description = "Commander reloads his gun. He takes 5 seconds to do so and gets Slowness III while reloading.",
                Behaviour = ReloadBehaviour,
            }),

            Justice = Ability.New({
                Name = "Justice",
                Description = "Commander saca la pistola y dispara al frente mientras va despacio. Hace 50 de daño al asesino y lo aturde 4,2 segundos.",
                UseAnimation = "",
                ShotSound = "",
                Cooldown = 45,
                InputName = "ThirdAbility",
                Duration = 1/22 * 3,
                HitboxLength = 45,
                Damage = 50,
                StunTime = 4.2,

                UseSettings = {
                    InitialUses = 0,
                    Limited = true,
                },

                ExtraInit = JusticeExtraInit,

                Behaviour = JusticeBehaviour,
            }),
        },
    },

    OnHit = OnCommanderHit,
})

Commander.Config.Description = {
    {
        Type = "Separator",
        Text = "INFORMACIÓN GENERAL",
    },
    {
        Type = "Header",
        Text = Commander.Config.Name:upper(),
    },
    {
        Type = "Quote",
        Text = "\""..Commander.Config.Quote.."\""
    },
    {
        Type = "Text",
        Text = "Empezó como un simple soldado que puso el ejército patas arriba con su liderazgo. "
            .."Tras varios altercados en la empresa que lo contrató como guardia contra anomalías, sobrevivió a un accidente mortal y se convirtió en uno de los mejores soldados del ejército. "
            .."Lleva años de entrenamiento intenso, domina las pistolas y las granadas cegadoras, las usa con la máxima eficacia y compra siempre el mejor equipo.",
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
            "Vida: "..tostring(Commander.GameplayConfig.Health),
            "Velocidad base: "..tostring(Commander.GameplayConfig.BaseSpeed),
            "Velocidad al correr: "..tostring(math.round(Commander.GameplayConfig.BaseSpeed * Commander.GameplayConfig.SprintSpeedMultiplier * 10) / 10),
            "Aguante máximo: "..tostring(Commander.GameplayConfig.StaminaProperties.MaxStamina),
            "Aguante perdido por segundo: "..tostring(Commander.GameplayConfig.StaminaProperties.StaminaDrain),
            "Aguante recuperado por segundo: "..tostring(Commander.GameplayConfig.StaminaProperties.StaminaGain),
        },
    },
    {
        Type = "Separator",
        Text = "PASIVAS",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.BodyArmor.Name:upper(),
    },
    {
        Type = "Quote",
        Text = "\"¡Armadura de diamante, set completo!\" -Steve de Minecraft",
    },
    {
        Type = "Text",
        Text = "Cada vez que golpean a Commander, gana <b>Resistencia V</b> durante 1 segundo, como fotogramas de invencibilidad.",
        Image = "http://www.roblox.com/asset/?id=113412520",
    },
    {
        Type = "Separator",
        Text = "HABILIDADES",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.Blindside.Name:upper(),
    },
    {
        Type = "Text",
        Text = "Commander saca una granada cegadora y la lanza tras "..tostring(Commander.GameplayConfig.Abilities.Blindside.ThrowDelay)..
            " segundos; estalla tras "..tostring(Commander.GameplayConfig.Abilities.Blindside.TriggerDelay)..
            " segundos y causa <b>Ceguera</b> al asesino durante "..tostring(Commander.GameplayConfig.Abilities.Blindside.FlashTime)..
            " segundos si está a menos de "..tostring(Commander.GameplayConfig.Abilities.Blindside.FlashRadius)..
            " studs.",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.Reload.Name:upper(),
    },
    {
        Type = "Text",
        Text = "Commander recarga la pistola y sufre <b>Lentitud "..Utils.Math.IntToRoman(Commander.GameplayConfig.Abilities.Reload.SlownessLevel)..
            "</b> durante "..tostring(Commander.GameplayConfig.Abilities.Reload.Duration).." segundos.",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.Justice.Name:upper(),
    },
    {
        Type = "Text",
        Text = {
            "Commander dispara al frente a "
            ..tostring(Commander.GameplayConfig.Abilities.Justice.HitboxLength).." studs. Si acierta al asesino, lo aturde durante "
            ..tostring(Commander.GameplayConfig.Abilities.Justice.StunTime).." segundos y le hace "
            ..tostring(Commander.GameplayConfig.Abilities.Justice.Damage).." de daño.",
            "La carga de esta habilidad se consigue con <b>Reload</b>."
        },
    },
}

return Commander
