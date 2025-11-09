local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local TimeManager
local CommonFunctions
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local HitboxFolder = workspace.TempObjectFolders.Hitboxes

local Hitbox = {}

--- Settings type for all hitboxes.
export type HitboxSettings = {
    --- Size of the hitbox in studs.
    Size: Vector3?,
    --- Offset for the assigned CFrame in the settings. Useful to e.g. move hitbox backwards or forwards for adjusting.
    CFrameOffset: CFrame?,
    --- Coordinate Frame of the hitbox. May also be a function to update it dynamically.
    CFrame: CFrame? | () -> (CFrame)?,
    --- Damage inflicted to any hit humanoids.
    Damage: number?,
    --- Determines how long the hitbox will last.
    Time: number?,
    --- Optional parameter to apply a force to any hit humanoids.
    Knockback: number?,
    --- Piercing. If false, the hitbox will stop whenever it hits a humanoid.
    HitMultiple: boolean?,
    --- If true, will try to predict the player's velocity & ping to be more accurate.
    PredictVelocity: boolean?,
    --- If true, will play an execution animation, killing the hit humanoid afterwards. Should be used with `HitMultiple` being false and only in slashes.
    ExecuteOnKill: boolean?,
    --- Info boolean that indicates if this hitbox is originated from a projectile.
    IsProjectile: boolean?,
    --- If true, the hitbox will be able to hit anyone.
    FriendlyFire: boolean?,
    --- Reason ID for custom behaviours on hit. Please assign this.
    Reason: string?,
    --- Optional parameter to specify certain status effects that'll be applied to whoever's hit.
    EffectsToApply: {{
        --- Name of the effect in the files.
		Name: string,
        --- Desired level to grant.
		Level: number?,
        --- How long it'll last.
		Duration: number?,
        --- If in a subfolder, specify it.
		Subfolder: string?,
	}}?,
    --- Internal variable used to make cancelling the hitbox possible.
    Connections: {[string]: (any?) -> ()}?,
    --- Empty function that serves as custom behaviour code when the hitbox hits a humanoid.
    OnHit: (hum: Humanoid) -> ()?,
}

--- Creates a new hitbox, assigning it to a specific player.
function Hitbox:New(SourcePlayer: Player, Config: HitboxSettings): {
    --- The humanoids the hitbox has already hit.
    HumanoidsHit: {Humanoid}?,
    --- The player that created this hitbox.
    Creator: Player?,
    --- The damage this hitbox deals.
    Damage: number?,
    --- The time that's passed since the creation of the hitbox.
    TimePast: number?,
    --- If the hitbox has been cancelled.
    Cancelled: boolean?,
    --- Cancels the hitbox and destroys it.
    --- Call this with a `:`.
    Cancel: (any) -> ()?,
}
    if not RunService:IsServer() then
        return {}
    end

    --initting it from here instead of outside due to it being server-sided
    if TimeManager == nil then
        TimeManager = require(ServerScriptService.Managers.TimeManager)
    end
    if CommonFunctions == nil then
        CommonFunctions = require(ServerScriptService.System.CommonFunctions)
    end

    local Char = SourcePlayer and SourcePlayer.Character
    local Root = Char and Char.PrimaryPart

    if not Root then
        return {}
    end

    Config = Config or {}
    Config = {
        Size = Config.Size or Vector3.new(4, 7, 4),
        CFrameOffset = Config.CFrameOffset or CFrame.new(),
        CFrame = Config.CFrame or nil,
        Damage = Config.Damage or 20,
        Time = Config.Time or 0.2,
        Knockback = Config.Knockback or 0,
        HitMultiple = Config.HitMultiple or false,
        PredictVelocity = Config.PredictVelocity == nil or Config.PredictVelocity,
        ExecuteOnKill = Config.ExecuteOnKill or false,
        IsProjectile = Config.IsProjectile or false,
        FriendlyFire = Config.FriendlyFire or false,
        Reason = Config.Reason or "Slash Attack",
        EffectsToApply = Config.EffectsToApply or {},
        Connections = Config.Connections or {},
    }

    local Over = OverlapParams.new()
    Over.FilterType = Enum.RaycastFilterType.Exclude
    Over.FilterDescendantsInstances = {Char}

    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.FilterDescendantsInstances = {Char}

    local Props = {
        HumanoidsHit = {},
        Creator = SourcePlayer,
        Damage = Config.Damage,
        TimePast = 0,
        Cancelled = false,
        IsProjectile = Config.IsProjectile,
    }
    Props.Cancel = function(p)
        p.Cancelled = true
    end

    task.defer(function()
        while Char and Char.Parent and Root and Props.TimePast < Config.Time and not Props.Cancelled and not Char.Effects:FindFirstChild("Stunned") do
            local Damaged = Props.HumanoidsHit

            if #Damaged <= 0 or Config.HitMultiple then
                local Part = Instance.new("Part")
                Part.Name = SourcePlayer.Name.."Hitbox"
                Part.Transparency = 1
                Part.CanCollide = false
                Part.CanQuery = false
                Part.CanTouch = false
                Part.CastShadow = false
                Part.Anchored = true
                Part.Size = Config.Size
                Part.CFrame = (Config.CFrame and (typeof(Config.CFrame) == "function" and Config.CFrame() or Config.CFrame) or Root.CFrame) * Config.CFrameOffset
                Part.Parent = HitboxFolder

                Debris:AddItem(Part, 0.75)

                if Config.PredictVelocity then
                    Utils:Print(SourcePlayer:GetNetworkPing())
                    local PingDivider = 6.5 - math.clamp(SourcePlayer:GetNetworkPing(), 0, 3)
                    local PingOffset = Part.CFrame:VectorToObjectSpace(Root.AssemblyLinearVelocity) / PingDivider
                    Part.CFrame *= CFrame.new(PingOffset)
                end

                Damaged = workspace:GetPartsInPart(Part, Over)

                table.sort(Damaged, function(a, b)
                    return (a.Parent:GetAttribute("HitboxPriority") or 1) > (b.Parent:GetAttribute("HitboxPriority") or 1)
                end)

                local Hit = {}

                for _, i in Damaged do
                    local Hum = i.Parent:FindFirstChildOfClass("Humanoid")
                    if Hum and Hum.Health > 0 and not Hum.Parent:GetAttribute("Invincible") and not Hum.Parent:GetAttribute("Executing") and not Damaged[Hum] and (workspace:GetAttribute("FriendlyFire") or Config.FriendlyFire or i.Parent.Role.Value) ~= Char.Role.Value then
                        if not Config.CFrame then
                            local index = 0
                            for _, o in {
                                Root.CFrame.LookVector,
                                CFrame.lookAt(Root.Position, i.Position).LookVector,
                            } do
                                local cast = workspace:Raycast(Root.Position, o * Part.Size.Z, RayParams)
                                local Inst = cast and cast.Instance
                                if Inst and not Inst.Parent:FindFirstChildOfClass("Humanoid") and Inst.Transparency ~= 1 and not Inst:GetAttribute("Hitbox") then
                                    index += 1
                                end
                            end

                            if index >= 2 then
                                continue
                            end
                        end

                        table.insert(Props.HumanoidsHit, Hum)
                        table.insert(Hit, Hum)
                        if not Config.HitMultiple then
                            break
                        end
                    end
                end

                Part.Color = #Hit > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

                for Index, Hum in Hit do
                    local P = Hum.Parent
                    local HRoot = P and P:IsA("Model") and P.PrimaryPart
                    local Resistance = P and P:FindFirstChild("Resistance") and P.Effects:FindFirstChild("Resistance") and P.Effects["Resistance"].Value or 0

                    local Damage = Config.Damage * (1 - Resistance / 5)

                    if HRoot then
                        P:SetAttribute("TimesHit", (P:GetAttribute("TimesHit") or 0) + 1)

                        if P:GetAttribute("CharacterName") ~= nil then
                            local CharacterModule = require(P.PlayerAbilities.CharacterAbilities).CharacterModule
                            if CharacterModule and CharacterModule.OnHit ~= nil then
                                if CharacterModule:OnHit(Props, Damage) == "Ignored" then
                                    continue
                                end
                            end
                        end

                        if Config.OnHit then
                            Config.OnHit(Hum)
                        end

                        if P:FindFirstChild("Killer") then
                            P.Killer.Value = SourcePlayer
                        end

                        if Hum.Health > 0 and Hum.Health - Damage <= 0 then
                            local KillerModule = require(Utils:GetCharacterModule("Killer", Char:GetAttribute("CharacterName"), Char:GetAttribute("CharacterSkinName")))

                            local KilledSurvivor = {
                                Name = P:GetAttribute("CharacterName"),
                                Skin = P:GetAttribute("CharacterSkinName"),
                            }

                            --kill voicelines
                            if KillerModule.Config.Voicelines.Kill and not P:GetAttribute("ExecutionsDisabled") then
                                local Voiceline = KilledSurvivor.Skin and KillerModule.Config.Voicelines.Kill[KilledSurvivor.Skin..KilledSurvivor.Name] or KillerModule.Config.Voicelines.Kill[KilledSurvivor.Name]
                                if not Voiceline then
                                    Voiceline = KillerModule.Config.Voicelines.Kill["Default"]
                                end

                                if Voiceline then
                                    Sounds:PlayVoiceline(Char, Voiceline)
                                end
                            end

                            --execution anims
                            if Config.ExecuteOnKill and not P:GetAttribute("ExecutionsDisabled") then
                                local ExecutionAnimsAvailable = KillerModule.GameplayConfig.Cache.Animations.Execution

                                if ExecutionAnimsAvailable then
                                    task.spawn(function()
                                        local ExecutionAnim = KilledSurvivor.Skin and ExecutionAnimsAvailable[KilledSurvivor.Skin..KilledSurvivor.Name] or ExecutionAnimsAvailable[KilledSurvivor.Name]
                                        if not ExecutionAnim then
                                            ExecutionAnim = ExecutionAnimsAvailable["Default"]
                                        end

                                        if not ExecutionAnim then

                                            if Config.Knockback >= 15 then
                                                HRoot.Velocity = Part.CFrame.LookVector * Config.Knockback * 10
                                            elseif Config.Knockback > 0 then
                                                local BodyVel = Instance.new("BodyVelocity")
                                                BodyVel.MaxForce = Vector3.new(1e999, 1e999, 1e999)
                                                BodyVel.Velocity = Part.CFrame.LookVector * Config.Knockback * 10
                                                BodyVel.Parent = HRoot
                                                Debris:AddItem(BodyVel, 0.05)
                                            end
                                            Hum.Health = 0

                                            return
                                        end

                                        local KillerAnim = ExecutionAnim.Killer

                                        local SurvivorAnim = KilledSurvivor.Skin and KillerModule.Config.AnimationIDs.Execution[KilledSurvivor.Skin..KilledSurvivor.Name] or KillerModule.Config.AnimationIDs.Execution[KilledSurvivor.Name]
                                        SurvivorAnim = SurvivorAnim or KillerModule.Config.AnimationIDs.Execution["Default"]
                                        SurvivorAnim = Utils:LoadAnimationFromID(P, SurvivorAnim)

                                        local ExSound = KilledSurvivor.Skin and KillerModule.Config.Sounds.Execute[KilledSurvivor.Skin..KilledSurvivor.Name] or KillerModule.Config.Sounds.Execute[KilledSurvivor.Name]
                                        ExSound = ExSound or KillerModule.Config.Sounds.Execute["Default"]

                                        P.Effects:ClearAllChildren()

                                        Char:SetAttribute("Executing", true)
                                        Char:SetAttribute("Invincible", true)
                                        P:SetAttribute("Executing", true)

                                        Char:PivotTo(CFrame.new(Root.Position, Vector3.new(HRoot.Position.X, Root.Position.Y, HRoot.Position.Z)))
                                        P:PivotTo(Root.CFrame * (KillerModule.Config.ExecutionSurvivorCFrameOffset or CFrame.new(0, 0, 5)))

                                        Root.Anchored = true
                                        HRoot.Anchored = true

                                        task.delay(KillerAnim.Length, function()
                                            if Char then
                                                Char:SetAttribute("Invincible", false)
                                                Char:SetAttribute("Executing", false)
                                            end
                                            if Root then
                                                Root.Anchored = false
                                            end
                                            if HRoot then
                                                HRoot.Anchored = false
                                            end
                                            if Hum then
                                                Hum.Health = 0
                                            end
                                        end)

                                        KillerAnim:Play(0)
                                        SurvivorAnim:Play(0)
                                        if ExSound then
                                            Sounds:PlaySound(ExSound, {
                                                Parent = Root,
                                            })
                                        end

                                        if KillerModule.GameplayConfig.OnExecution then
                                            KillerModule.GameplayConfig:OnExecution(KillerModule, P)
                                        end
                                    end)
                                else
                                    if Config.Knockback >= 15 then
                                        HRoot.Velocity = Part.CFrame.LookVector * Config.Knockback * 10
                                    elseif Config.Knockback > 0 then
                                        local BodyVel = Instance.new("BodyVelocity")
                                        BodyVel.MaxForce = Vector3.new(1e999, 1e999, 1e999)
                                        BodyVel.Velocity = Part.CFrame.LookVector * Config.Knockback * 10
                                        BodyVel.Parent = HRoot
                                        Debris:AddItem(BodyVel, 0.05)
                                    end
                                    Hum.Health = 0
                                end

                                return
                            end

                        end

                        if Config.Knockback >= 15 then
                            HRoot.Velocity = Part.CFrame.LookVector * Config.Knockback * 10
                        elseif Config.Knockback > 0 then
                            local BodyVel = Instance.new("BodyVelocity")
                            BodyVel.MaxForce = Vector3.new(1e999, 1e999, 1e999)
                            BodyVel.Velocity = Part.CFrame.LookVector * Config.Knockback * 10
                            BodyVel.Parent = HRoot
                            Debris:AddItem(BodyVel, 0.05)
                        end

                        if Damage > 0 then
                            CommonFunctions:DamagePlayer(SourcePlayer, Hum, Damage, Config.Reason)
                        end
                        if Config.EffectsToApply then
                            for _, i in Config.EffectsToApply do
					            CommonFunctions:ApplyEffect(Hum, i.Name, i.Level, i.Duration, i.Subfolder)
				            end
                        end

                        self:_RunCallback(Config.Connections, "Hit", Index == 1)
                    end
                end

                Props.TimePast += task.wait(1/40)
            else
                break
            end
        end
        
        self:_RunCallback(Config.Connections, "Ended")
    end)

    return Props
end

function Hitbox:_RunCallback(ConnList: {[string]: (any?) -> ()}?, ID: string, ...)
    if ConnList and ConnList[ID] then
        ConnList[ID](...)
    end
end

return Hitbox
