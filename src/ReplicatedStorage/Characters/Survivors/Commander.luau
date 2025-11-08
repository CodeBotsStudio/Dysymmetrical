--!nocheck

-- local Debris = game:GetService("Debris")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Character = require(ReplicatedStorage.Classes.Character)
local Ability = require(ReplicatedStorage.Classes.Ability)
local Hitbox = require(ReplicatedStorage.Classes.Hitbox)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil

--Character Definition
local Commander: Character.Survivor = Character:GetDefaultSurvivorSettings()
Commander.Config.Name = "Commander"
Commander.Config.Quote = "*pyro noises*"
Commander.Config.Render = "rbxassetid://108440668883002"

--Abilities Definition

--Body Armor
local BodyArmor = Ability:GetDefaultAbilitySettings()
BodyArmor.Name = "Body Armor"
BodyArmor.Description = "Every time Commander gets damaged, he receives Resistance V for 1 second, acting as invincibility frames."
BodyArmor.Passive = true

--Flashpoint // Blindside
local Blindside: Ability.Ability = Ability:GetDefaultAbilitySettings()
Blindside.Name = "Blindside"

Blindside.ThrowDelay = 1
Blindside.TriggerDelay = 3.5
Blindside.FlashTime = 3.5
Blindside.FlashRadius = 6
Blindside.ThrowForce = 60

Blindside.Description = "Commander picks up a flashbang grenade and throws it after "..tostring(Blindside.ThrowDelay)..
    " seconds, triggering it after "..tostring(Blindside.TriggerDelay)..
    " seconds and flashing the killer for "..tostring(Blindside.FlashTime)..
    " seconds if they're in a "..tostring(Blindside.FlashRadius)..
    " stud radius."

Blindside.Cooldown = 30
Blindside.InputName = "FirstAbility"
Blindside.Duration = Blindside.ThrowDelay + 1

Blindside.Behaviour = function(self)
    if RunService:IsServer() then
        local AnimatedGrenade = self.OwnerProperties.Character:FindFirstChild("Grenade")
        AnimatedGrenade.Transparency = 0

        table.insert(self.Connections, task.delay(self.ThrowDelay, function()
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

            table.insert(self.Connections, task.delay(self.TriggerDelay, function()
                task.spawn(function()
                    Hitbox:New(self.Owner, {
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
                        OnHit = function(Hum: Humanoid)
                            CommonFunctions:GrantRewardToPlayer(self.Owner, 10, 20, "blinding the killer with Blindside")
                        end,
                    })
                end)

                local Light = FunctionalGrenade:FindFirstChildOfClass("PointLight")
                Light.Enabled = true
                TweenService:Create(Light, TweenInfo.new(0.1), {Brightness = 0}):Play()

                FunctionalGrenade:FindFirstChildOfClass("ParticleEmitter"):Emit(80)

                table.insert(self.Connections, task.delay(0.1, function()
                    FunctionalGrenade.Transparency = 1
                    Light.Enabled = false

                    Debris:AddItem(FunctionalGrenade, 8)
                end))
            end))
        end))
    end
end

--Reload
local Reload: Ability.Ability = Ability:GetDefaultAbilitySettings()
Reload.Name = "Reload"
Reload.InputName = "SecondAbility"
Reload.SlownessLevel = 3
Reload.Description = "Commander reloads his gun. He takes "..tostring(Reload.Duration).." seconds to do so and gets Slowness"..Utils:IntToRoman(Reload.SlownessLevel).." while reloading."
Reload.Duration = 5
Reload.Cooldown = 40

Reload.Behaviour = function(self)
    if RunService:IsServer() then
        return
    end

    if self.CharModule.GameplayConfig.Abilities.Justice.UsesLeft > 0 then
        return
    end

    table.insert(self.Connections, task.delay(self.Duration, function()
        self.OwnerProperties.SpeedManager:RemoveSpeedFactor(self.Name)
        Network:FireConnection("ReloadCommanderJustice")
    end))

    self.OwnerProperties.SpeedManager:AddSpeedFactor(self.Name, 0.35)
end

--Justice
local Justice: Ability.Ability = Ability:GetDefaultAbilitySettings()
Justice.Name = "Justice"
Justice.StunTime = 4.2
Justice.Damage = 50
Justice.Description = "Commander pulls out a gun and shoots forward while in low speed. Does "..tostring(Justice.Damage).." damage to the killer and stuns them for "..tostring(Justice.StunTime).." seconds."
Justice.UseAnimation = "rbxassetid://131414947946564"
Justice.ShotSound = "rbxassetid://4485644082"
Justice.Cooldown = 45
Justice.InputName = "ThirdAbility"
Justice.Duration = 1/22 * 3
Justice.HitboxLength = 45

Justice.UseSettings = {
    InitialUses = 0,
    Limited = true,
}

Justice.ExtraInit = function(self)
    if not RunService:IsServer() then
        table.insert(self.Connections, Network:SetConnection("ReloadCommanderJustice", "BINDABLE_EVENT", function()
            self.UsesLeft = 1
        end))
    else
        self.JusticeModel = Utils:FindFirstChild(self.OwnerProperties.Character, "Deagle")
    end
end

Justice.Behaviour = function(self)
    if RunService:IsServer() then
        --Shot Sound & Hitbox
        table.insert(self.Connections, task.delay(1.17, function()
            task.spawn(function()
                Hitbox:New(self.Owner, {
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
                    OnHit = function(Hum: Humanoid)
                        CommonFunctions:GrantRewardToPlayer(self.Owner, 6, 14, "stunning the killer with Justice")
                    end,
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
        table.insert(self.Connections, task.delay(2, function()
            for _, i in self.JusticeModel:GetDescendants() do
                if i:IsA("BasePart") then
                    i.Transparency = 1
                end
            end
        end))

        --Show
        for _, i in self.JusticeModel:GetDescendants() do
            if i:IsA("BasePart") and not i:HasTag("Transparent") then
                i.Transparency = 0
            end
        end

        return
    else
        self.OwnerProperties.SpeedManager:AddSpeedFactor(self.Name, 0.3)
        table.insert(self.Connections, task.delay(self.UseAnimationTrack.Length, function()
            self.OwnerProperties.SpeedManager:RemoveSpeedFactor(self.Name)
        end))
    end
end

--Body Armor
Commander.OnHit = function(self, _hitbox, _damage)
    CommonFunctions:ApplyEffect(self.Owner.Character:FindFirstChildOfClass("Humanoid"), "Resistance", 5, 1)

    return
end

--Description Definition

Commander.Config.Description = {
    {
        Type = "Separator",
        Text = "GENERAL INFO",
    },
    {
        Type = "Header",
        Text = "COMMANDER",
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
        Text = "BODY ARMOR",
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
        Text = "BLINDSIDE",
    },
    {
        Type = "Text",
        Text = "Commander picks up a flashbang grenade and throws it after "..tostring(Blindside.ThrowDelay)..
            " seconds, triggering it after "..tostring(Blindside.TriggerDelay)..
            " seconds and inflicting the killer <b>Blindness</b> for "..tostring(Blindside.FlashTime)..
            " seconds if they're in a "..tostring(Blindside.FlashRadius)..
            " stud radius.",
    },
    {
        Type = "Header",
        Text = "RELOAD",
    },
    {
        Type = "Text",
        Text = "Commander reloads his gun, getting <b>Slowness "..Utils:IntToRoman(Reload.SlownessLevel).."</b> for "..tostring(Reload.Duration).." seconds.",
    },
    {
        Type = "Header",
        Text = "JUSTICE",
    },
    {
        Type = "Text",
        Text = {
            "Commander shoots forward "..tostring(Justice.HitboxLength).." studs. If it hits the killer, they get stunned for "..tostring(Justice.StunTime).." seconds and receive "..tostring(Justice.Damage).." damage.",
            "This ability's charge is obtained through <b>Reload</b>."
        },
    },
}

--Ability Table for usage
Commander.GameplayConfig.Abilities = {
    Blindside = Blindside,
    Reload = Reload,
    Justice = Justice,
}

return Commander
