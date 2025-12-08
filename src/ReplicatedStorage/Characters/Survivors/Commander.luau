--!nocheck

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Character = require(ReplicatedStorage.Classes.Character)
local Ability = require(ReplicatedStorage.Classes.Ability)
local Hitbox = require(ReplicatedStorage.Classes.Hitbox)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil

local Commander = Character.CreateSurvivor({
    Config = {
        Name = "Commander",
        Quote = "*pyro noises*",
        Render = "rbxassetid://108440668883002",
    },

    GameplayConfig = {
        Abilities = {
            BodyArmor = Ability.CreateAbility({
                Name = "Body Armor",
                -- Description = "Every time Commander gets damaged, he receives Resistance V for 1 second, acting as invincibility frames.",
                Passive = true,
            }),

            Blindside = Ability.CreateAbility({
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

                Behaviour = function(self)
                    if RunService:IsServer() then
                        local AnimatedGrenade = self.OwnerProperties.Character:FindFirstChild("Grenade")
                        AnimatedGrenade.Transparency = 0

                        self:AddConnection(task.delay(self.ThrowDelay, function()
                            local FunctionalGrenade = AnimatedGrenade:Clone()
                            local Joint = FunctionalGrenade:FindFirstChildOfClass("JointInstance")
                            if Joint then
                                Joint:Destroy()
                            end
                            FunctionalGrenade.Name = "ActiveFlashGrenade"
                            FunctionalGrenade.CanCollide = true
                            FunctionalGrenade.CollisionGroup = "Items"
                            FunctionalGrenade.AssemblyLinearVelocity = (self.OwnerProperties.Character.HumanoidRootPart.CFrame.LookVector + Vector3.new(0, 0.5, 0)) * self.ThrowForce
                            FunctionalGrenade.Parent = workspace.Map.InGame

                            AnimatedGrenade.Transparency = 1
                        
                            self:AddConnection(task.delay(self.TriggerDelay, function()
                                task.spawn(function()
                                    Hitbox.New(self.Owner, {
                                        CFrame = CFrame.new(FunctionalGrenade.Position),
                                        Size = Vector3.new(35, 35, 35),
                                        Damage = 0,
                                        Time = 1/40 * 3,
                                        EffectsToApply = {
                                            {
                                                Name = "Blindness",
                                                Duration = 4,
                                                Level = 1,
                                            },
                                        },
                                        Connections = {
                                            PostHit = function(Hum: Humanoid)
                                                CommonFunctions.GrantRewardToPlayer(self.Owner, 10, 20, "blinding the killer with Blindside")
                                            end,
                                        }
                                    })
                                end)
                            
                                local Light = FunctionalGrenade:FindFirstChildOfClass("PointLight")
                                Light.Enabled = true
                                TweenService:Create(Light, TweenInfo.new(0.1), {Brightness = 0}):Play()
                            
                                FunctionalGrenade:FindFirstChildOfClass("ParticleEmitter"):Emit(80)
                            
                                self:AddConnection(task.delay(0.1, function()
                                    FunctionalGrenade.Transparency = 1
                                    Light.Enabled = false
                                
                                    Debris:AddItem(FunctionalGrenade, 8)
                                end))
                            end))
                        end))

                        return
                    end
                end,
            }),

            Reload = Ability.CreateAbility({
                Name = "Reload",
                Duration = 5,
                Cooldown = 40,
                InputName = "SecondAbility",
                SlownessLevel = 3,
                -- Description = "Commander reloads his gun. He takes 5 seconds to do so and gets Slowness III while reloading.",
                Behaviour = function(self)
                    if RunService:IsServer() then
                        self:AddConnection(task.delay(self.Duration, function()
                            self:ChangeAbilityCharges("Set", 1)
                        end))

                        CommonFunctions.ApplyEffect(self.OwnerProperties.Character:FindFirstChildOfClass("Humanoid"), "Slowness", 3, 5)

                        return
                    end
                end,
            }),

            Justice = Ability.CreateAbility({
                Name = "Justice",
                Description = "Commander pulls out a gun and shoots forward while in low speed. Does 50 damage to the killer and stuns them for 4.2 seconds.",
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

                ExtraInit = function(self)
                    self.JusticeModel = Utils.Instance.FindFirstChild(self.OwnerProperties.Character, "Deagle")
                end,

                Behaviour = function(self)
                    if RunService:IsServer() then
                        --Shot Sound & Hitbox
                        self:AddConnection(task.delay(1.17, function()
                            task.spawn(function()
                                Hitbox.New(self.Owner, {
                                    CFrameOffset = CFrame.new(0, 0, -(self.HitboxLength / 2)),
                                    Size = Vector3.new(3, 1.5, self.HitboxLength),
                                    Time = self.Duration,
                                    Reason = "The Gun Shot",
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
                                        PostHit = function(Hum: Humanoid)
                                            CommonFunctions.GrantRewardToPlayer(self.Owner, 6, 14, "stunning the killer with Justice")
                                        end,
                                    }
                                })
                            end)
                        
                            local FirePart = self.JusticeModel.FirePart
                            FirePart.Burst:Emit(4)
                            FirePart.Front:Emit(12)
                            FirePart.Smoke:Emit(8)
                            FirePart.Flash:Emit(3)
                            Sounds:PlaySound(self.ShotSound, {Volume = 2}, {
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
                    
                        --Show
                        for _, Part in self.JusticeModel:GetDescendants() do
                            if Part:IsA("BasePart") and not Part:HasTag("Transparent") then
                                Part.Transparency = 0
                            end
                        end
                    else
                        self.OwnerProperties.SpeedManager:AddSpeedFactor(self.Name, 0.3)
                        self:AddConnection(task.delay(self.UseAnimationTrack.Length, function()
                            self.OwnerProperties.SpeedManager:RemoveSpeedFactor(self.Name)
                        end))
                    end
                end,
            }),
        },
    },

    OnHit = function(self, _hitbox, _damage)
        CommonFunctions.ApplyEffect(self.Owner.Character:FindFirstChildOfClass("Humanoid"), "Resistance", 5, 1)

        return
    end,
})

Commander.Config.Description = {
    {
        Type = "Separator",
        Text = "GENERAL INFO",
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
        Text = "Initially a simple soldier that managed to turn the military upside-down with his leadership. "
            .."After some altercations in a company he got hired in as a guard against anomalies, he managed to survive a fatal accident and become one of the peak soldiers in the army. "
            .."He's been intensely trained for years and has experience with handguns and flash grenades, using them as efficiently as possible and purchasing the tools with most quality.",
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
            "Health: "..tostring(Commander.GameplayConfig.Health),
            "Base Speed: "..tostring(Commander.GameplayConfig.BaseSpeed),
            "Sprint Speed: "..tostring(math.round(Commander.GameplayConfig.BaseSpeed * Commander.GameplayConfig.SprintSpeedMultiplier * 10) / 10),
            "Max Stamina: "..tostring(Commander.GameplayConfig.StaminaProperties.MaxStamina),
            "Stamina Loss per second: "..tostring(Commander.GameplayConfig.StaminaProperties.StaminaDrain),
            "Stamina Gain per second: "..tostring(Commander.GameplayConfig.StaminaProperties.StaminaGain),
        },
    },
    {
        Type = "Separator",
        Text = "PASSIVES",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.BodyArmor.Name:upper(),
    },
    {
        Type = "Quote",
        Text = "\"Diamond armor, full set!\" -Minecraft Steve",
    },
    {
        Type = "Text",
        Text = "Every time Commander gets hit, he gets <b>Resistance V</b> for 1 second, acting as invincibility frames.",
        Image = "http://www.roblox.com/asset/?id=113412520",
    },
    {
        Type = "Separator",
        Text = "ABILITIES",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.Blindside.Name:upper(),
    },
    {
        Type = "Text",
        Text = "Commander picks up a flashbang grenade and throws it after "..tostring(Commander.GameplayConfig.Abilities.Blindside.ThrowDelay)..
            " seconds, triggering it after "..tostring(Commander.GameplayConfig.Abilities.Blindside.TriggerDelay)..
            " seconds and inflicting the killer <b>Blindness</b> for "..tostring(Commander.GameplayConfig.Abilities.Blindside.FlashTime)..
            " seconds if they're in a "..tostring(Commander.GameplayConfig.Abilities.Blindside.FlashRadius)..
            " stud radius.",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.Reload.Name:upper(),
    },
    {
        Type = "Text",
        Text = "Commander reloads his gun, getting <b>Slowness "..Utils.Math.IntToRoman(Commander.GameplayConfig.Abilities.Reload.SlownessLevel)..
            "</b> for "..tostring(Commander.GameplayConfig.Abilities.Reload.Duration).." seconds.",
    },
    {
        Type = "Header",
        Text = Commander.GameplayConfig.Abilities.Justice.Name:upper(),
    },
    {
        Type = "Text",
        Text = {
            "Commander shoots forward "
            ..tostring(Commander.GameplayConfig.Abilities.Justice.HitboxLength).." studs. If it hits the killer, they get stunned for "
            ..tostring(Commander.GameplayConfig.Abilities.Justice.StunTime).." seconds and receive "
            ..tostring(Commander.GameplayConfig.Abilities.Justice.Damage).." damage.",
            "This ability's charge is obtained through <b>Reload</b>."
        },
    },
}

return Commander
