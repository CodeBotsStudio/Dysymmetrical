local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local TimeManager = RunService:IsServer() and require(ServerScriptService.Managers.TimeManager) or nil
local CommonFunctions = RunService:IsServer() and require(ServerScriptService.System.CommonFunctions) or nil
local Network = require(ReplicatedStorage.Modules.Network)
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
    --- The shape of the hitbox.
    --- 
    --- Read `Enum.PartType`.
    Shape: Enum.PartType?,
    --- The specific execution animation to use if `ExecuteOnKill` is `true`.
    --- 
    --- Will be looked up automatically if this isn't set.
    --- 
    --- TODO: **Fill this field with examples as this property is a bit weird to use and research is needed.**
    ExecutionAnimation: string?,
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
    --- Any callbacks for events fired in the hitbox's functionality.
    -- TODO: write what connections there are and what they do
    Connections: {[string]: (any?) -> ()}?,
}

--- Details on a hitbox's current stats
export type HitboxDetails = {
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


--- Creates a new hitbox, assigning it to a specific player.
function Hitbox.New(SourcePlayer: Player, Config: HitboxSettings): HitboxDetails

    -- Prevent this from normally running on the client
    --i love writing server shit and putting it in ReplicatedStorage :] -dys
    if not RunService:IsServer() then
        return {}
    end

    -- Define the player in question for this hitbox, find their HumanoidRoot (or adjacent)
    local Char = SourcePlayer and SourcePlayer.Character -- "Oh, that's pretty clever, too. Huh!" – Itred
    local Root = Char and Char.PrimaryPart
    -- Prevent the hitbox from running if such is not found.
    if not Root then
        -- "Figured some feedback on this would be nice, I can see this accidentally being tripped with custom player models for a killer (maybe???)" – Itred
        warn("ReplicatedStorage/Classes/Hitbox: Notice – Hitbox creation halted, due to no primarypart being present in the character of player '"..SourcePlayer.Name.."'.")
        return {}
    end

    -- Grab configuration to the pre-existing config table, or initialize some defaults for a new one if it doesn't exist.
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
        Shape = Config.Shape or Enum.PartType.Block,
        ExecutionAnimation = Config.ExecutionAnimation or nil,
        EffectsToApply = Config.EffectsToApply or {},
        Connections = Config.Connections or {},
    }

    -- Make a new hitbox filter
    local Over = OverlapParams.new()
    Over.FilterType = Enum.RaycastFilterType.Exclude
    Over.FilterDescendantsInstances = {Char}
    Over.CollisionGroup = "Attackable"

    -- Make a new raycast filter
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.FilterDescendantsInstances = {Char}

    local Conns

    -- Initialize a property table for storing some important details about the hitbox that we'll want to fetch later; additionally, make a useful cancelling function, also for later.
    local Props = {
        HumanoidsHit = {},
        Creator = SourcePlayer,
        Damage = Config.Damage,
        TimePast = 0,
        Cancelled = false,
        IsProjectile = Config.IsProjectile,
        Cancel = function(p)
            if p.Cancelled then
                return
            end

            p.Cancelled = true
            for _, Conn in Conns do
                Conn:Disconnect()
            end
        end,
    }

    local Effects = Char.Effects

    Conns = {
        Effects.ChildAdded:Connect(function(newChild)
            if newChild.Name == "Stunned" then
                Props:Cancel()
            end
        end),

        Char.AncestryChanged:Connect(function(_, newParent)
            if newParent == nil then
                Props:Cancel()
            end
        end),

        Char.Destroying:Connect(function()
            Props:Cancel()
        end),

        Root.AncestryChanged:Connect(function(_, newParent)
            if newParent == nil then
                Props:Cancel()
            end
        end),

        Root.Destroying:Connect(function()
            Props:Cancel()
        end)
    }

    -- Start the process of looking for anything that collides with the hitbox.
    task.defer(function()
        if Effects:FindFirstChild("Stunned") then
            return
        end

        -- caching part and cloning it instead of creating it every time
        local Part = Instance.new("Part")
        Part.Name = SourcePlayer.Name.."Hitbox"
        Part.Transparency = 1
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CanTouch = false
        Part.CastShadow = false
        Part.Anchored = true
        Part.Size = Config.Size
        Part.Shape = Config.Shape

        while not Props.Cancelled and Props.TimePast < Config.Time do
            local Damaged = Props.HumanoidsHit

            if #Damaged <= 0 or Config.HitMultiple then
                local CheckPart = Part:Clone()
                CheckPart.CFrame = (Config.CFrame and (typeof(Config.CFrame) == "function" and Config.CFrame() or Config.CFrame) or Root.CFrame) * Config.CFrameOffset
                CheckPart.Parent = HitboxFolder

                -- The hitbox itself lingers for a little while, even after parsing it, so it can be seen for those who have hitboxes enabled in their client settings(?).
                Debris:AddItem(CheckPart, 0.75)

                -- Some amount of ping compensation for placing the hitbox.
                if Config.PredictVelocity and not Config.IsProjectile then
                    -- Utils.Misc.Print(SourcePlayer:GetNetworkPing())
                    local PingDivider = 6.5 - math.clamp(SourcePlayer:GetNetworkPing(), 0, 3)
                    local PingOffset = CheckPart.CFrame:VectorToObjectSpace(Root.AssemblyLinearVelocity) / PingDivider
                    CheckPart.CFrame *= CFrame.new(PingOffset)
                end

                -- Finally parse through the hitbox itself.
                Damaged = workspace:GetPartsInPart(CheckPart, Over)

                -- Flip through all of the parts hit, sort them by hitboxpriority for the next step.
                table.sort(Damaged, function(a, b)
                    return (a.Parent:GetAttribute("HitboxPriority") or 1) > (b.Parent:GetAttribute("HitboxPriority") or 1)
                end)

                -- Make a new table for storing all players hit this loop.
                local Hit = {}

                -- Go through every hit player in the order mentioned beforehand.
                for _index, collidedpart in Damaged do

                    -- Determine whether or not the part in question belongs to a character by searching for a "humanoid" object sibling.
                    local Humanoid = collidedpart.Parent:FindFirstChildOfClass("Humanoid")

                    -- Proceed if the following conditions are met:
                        -- If the humanoid exists, 
                        -- has more than 0 health, 
                        -- if the chracter tied to it is not invincible, 
                        -- is not executing (for killers), 
                        -- has not already been hit by this attack (so one doesn't take 300 damage from getting their arms, legs, and torso all within the same hitbox),
                        -- and if they're either not on the same team as the user, or if the hitbox has friendly fire enabled.
                    if Humanoid and Humanoid.Health > 0 and not Humanoid.Parent:GetAttribute("Invincible") and not Humanoid.Parent:GetAttribute("Executing") and not Damaged[Humanoid] and (workspace:GetAttribute("FriendlyFire") or Config.FriendlyFire or (collidedpart.Parent:FindFirstChild("Role") and collidedpart.Parent.Role.Value or Char.Role.Value)) ~= Char.Role.Value then
                       
                        -- If the hitbox has no preset anchor, the anchor its using is the HumanoidRootPart of the user– perform some sanity checks to ensure the target isn't getting hit through a wall or similar.
                        if not Config.CFrame then

                            local index = 0
                            -- Starting from both the current facing position of the user, and the position of the user, facing towards the collided part, fire one more check forwards.
                            for _, o in {
                                Root.CFrame.LookVector,
                                CFrame.lookAt(Root.Position, collidedpart.Position).LookVector,
                            } do
                                -- Check in front of both of these starting points, moving out by the hitbox's length.
                                local cast = workspace:Raycast(Root.Position, o * CheckPart.Size.Z, RayParams)
                                local Inst = cast and cast.Instance

                                -- If the object hit is not a character (has no humanoid sibling), is not fully transparent, and is not a hitbox, then its a wall or something map-related– add one to an index counter.
                                if Inst and not Inst.Parent:FindFirstChildOfClass("Humanoid") and Inst.Transparency ~= 1 and not Inst:GetAttribute("Hitbox") then
                                    index += 1
                                end
                            end

                            -- Only if both of the above checks hit something assumedly map-related, skip hitting this player.
                            if index >= 2 then
                                continue
                            end
                        end

                        -- Otherwise, add the player to two different tracking tables.
                        table.insert(Props.HumanoidsHit, Humanoid)
                        table.insert(Hit, Humanoid)

                        -- Additionally, if the hitbox isn't set up to hit multiple players, stop it right here. Otherwise, let it keep going through any other player it may have hit this loop..
                        if not Config.HitMultiple then
                            break
                        end
                    end
                end

                -- Change the hitbox part's color depending on whether or not it hit any targets.
                CheckPart.Color = #Hit > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)


                -- Register a hit in every player detected in the previous step.
                for Index, Humanoid in Hit do

                    Hitbox._RunCallback(Config.Connections, "PreHit", Config, Humanoid, Index == 1)

                    -- Look for critical parts in the character in question, as well as the resistance effect, if applicable.
                    local TargetCharacter = Humanoid.Parent
                    local HRoot = TargetCharacter and TargetCharacter:IsA("Model") and TargetCharacter.PrimaryPart
                    local Resistance = TargetCharacter and TargetCharacter:FindFirstChild("Resistance") and TargetCharacter.Effects:FindFirstChild("Resistance") and TargetCharacter.Effects["Resistance"].Value or 0

                    -- Configure damage to be affected by the Resistance effect.
                    local Damage = Config.Damage * (1 - Resistance / 5)

                    -- If a HumanoidRootPart exists as a sibling to the humanoid object, proceed with registering a hit.
                    if HRoot then
                        -- Find out how many times this character has been hit so far(?).
                        TargetCharacter:SetAttribute("TimesHit", (TargetCharacter:GetAttribute("TimesHit") or 0) + 1)

                        -- If a survivor/killer is found tied to this character model, look for potential hit effects.
                        if TargetCharacter:GetAttribute("CharacterName") ~= nil then

                            -- Find the survivor/killer module tied to this character.
                            local CharacterModule = require(TargetCharacter.PlayerAbilities.CharacterAbilities).CharacterModule

                            -- If the survivor/killer has a function callback for being hit, and they nullify the hit for one reason or another, skip them and move on.
                            if CharacterModule and CharacterModule.OnHit ~= nil then
                                if CharacterModule:OnHit(Props, Damage) == "Ignored" then
                                    continue
                                end
                            end

                        end

                        -- If theres a function set to be executed on player hit for this hitbox, toss the humanoid to it.
                        Hitbox._RunCallback(Config.Connections, "Hit", Config, Humanoid, Index == 1)

                        -- Store the user as the last player whom hit the target, to give a readout of their killer if they are to die from a status effect or similar.
                        if TargetCharacter:FindFirstChild("Killer") then
                            TargetCharacter.Killer.Value = SourcePlayer
                        end

                        -- If the target has more than 0 health, but is killed by the hitbox:
                        if Humanoid.Health > 0 and Humanoid.Health - Damage <= 0 then

                            -- Find the killermodule for the user, who is assumedly on the "killer" team
                            local Module = require(Utils.Instance.GetCharacterModule(Char.Role.Value, Char:GetAttribute("CharacterName"), Char:GetAttribute("CharacterSkinName")))

                            -- Find out who the survivor they killed was, and what their skin was (if applicable)
                            local KilledSurvivor = {
                                Name = TargetCharacter:GetAttribute("CharacterName"),
                                Skin = TargetCharacter:GetAttribute("CharacterSkinName"),
                            }

                            -- Play on-kill voicelines, only if the user is properly able to execute the target.
                            if Module.Config.Voicelines.Kill and not TargetCharacter:GetAttribute("ExecutionsDisabled") then

                                -- Fetch the voiceline, or if one isn't found, resort to a default.
                                local Voiceline = KilledSurvivor.Skin and Module.Config.Voicelines.Kill[KilledSurvivor.Skin..KilledSurvivor.Name] or Module.Config.Voicelines.Kill[KilledSurvivor.Name]
                                if not Voiceline then
                                    Voiceline = Module.Config.Voicelines.Kill["Default"]
                                end

                                -- Finally, play the voiceline.
                                if Voiceline then
                                    Sounds:PlayVoiceline(Char, Voiceline)
                                end
                            end

                            -- Play execution animations, if applicable
                            if Char.Role.Value == "Killer" and Config.ExecuteOnKill and not TargetCharacter:GetAttribute("ExecutionsDisabled") then
                                
                                -- Fetch if the user has execution animations to use
                                local ExecutionAnimsAvailable = Module.Config.AnimationIDs[Config.ExecutionAnimation or "Execution"]

                                -- If the user has valid execution animations to use, go through with running them:
                                if ExecutionAnimsAvailable then
                                    task.defer(function() -- Switched from task.spawn() to task.defer() to avoid task scheduler conflicts

                                        -- Set the user and the target to be in an executing state. 
                                        Char:SetAttribute("Executing", true)
                                        Char:SetAttribute("Invincible", true)
                                        TargetCharacter:SetAttribute("Executing", true)

                                        -- Get the player that's about to be executed
                                        task.spawn(function()
                                            local TargetPlayer = Players:GetPlayerFromCharacter(TargetCharacter)
                                            if TargetPlayer then
                                                -- Execute the same code as if a survivor was killed while in chase to make it more fair for the killer (it won't execute again when the character actually dies later)
                	                            Network:FireClientConnection(SourcePlayer, "KilledPlayer", "REMOTE_EVENT", TargetPlayer)
                	                            Network:FireConnection("KilledPlayer", SourcePlayer, TargetPlayer)

					                            CommonFunctions.UpdatePlayerStat(SourcePlayer, "KillerStats.Kills", 1)
                	                            CommonFunctions.GrantRewardToPlayer(SourcePlayer, 20, 60, "killing a Survivor")

					                            TimeManager:SetTime(TimeManager.CurrentTime + 35)
                                            end
                                        end)

                                        -- Find out if theres a special execution animation to use for this specific survivor; if there isn't, use a default.
                                        local ExecutionAnim =
                                            (KilledSurvivor.Skin and
                                                ExecutionAnimsAvailable[KilledSurvivor.Skin..KilledSurvivor.Name]
                                                or ExecutionAnimsAvailable[KilledSurvivor.Name]
                                            )
                                            or ExecutionAnimsAvailable["Default"]

                                        -- If there are no execution animations to use, for one reason or another, resort to just killing the target and flinging it really far.
                                        if not ExecutionAnim then
                                            CommonFunctions.DamagePlayer(SourcePlayer, Humanoid, Damage, Config.Reason, CheckPart.CFrame.LookVector, Config.Knockback)

                                            return
                                        end

                                        -- If there is an animation to play, grab it.
                                        local RuntimeKillerModule = require(Char.PlayerAbilities.CharacterAbilities).CharacterModule
                                        local KillerExecAnims = RuntimeKillerModule.GameplayConfig.Cache.Animations[Config.ExecutionAnimation or "Execution"]
                                        local KillerAnim = ((KilledSurvivor.Skin and
                                                KillerExecAnims[KilledSurvivor.Skin..KilledSurvivor.Name]
                                                or KillerExecAnims[KilledSurvivor.Name]
                                            )
                                            or KillerExecAnims["Default"])
                                        .Killer

                                        -- If the survivor has a special death animation for this case, grab that, too.
                                        local SurvivorAnim = Utils.Character.LoadAnimationFromID(TargetCharacter, ExecutionAnim.Survivor)

                                        -- Grab the execution sound to play, if applicable; or use a default, if needed.
                                        local ExSound
                                        if Module.Config.Sounds.Execute then
                                            ExSound = 
                                                (KilledSurvivor.Skin and
                                                    Module.Config.Sounds.Execute[KilledSurvivor.Skin..KilledSurvivor.Name]
                                                    or Module.Config.Sounds.Execute[KilledSurvivor.Name]
                                                )
                                                or Module.Config.Sounds.Execute["Default"]
                                        end

                                        -- Clear all of the target's effects (they won't need 'em where they're goin').
                                        TargetCharacter.Effects:ClearAllChildren()

                                        -- Anchor both the user and the target to play the animation
                                        Root.Anchored = true
                                        HRoot.Anchored = true

                                        -- Move in for the kill
                                        Char:PivotTo(CFrame.new(Root.Position, Vector3.new(HRoot.Position.X, Root.Position.Y, HRoot.Position.Z)))
                                        TargetCharacter:PivotTo(Root.CFrame * (Module.Config.ExecutionSurvivorCFrameOffset or CFrame.new(0, 0, -3)) * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0))

                                        -- Schedule some work for when the animation is over: to reset the execution and invincible state back to false for the user, and do some cleanup (including, y'know, actually killing the target the user just executed).
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
                                            if Humanoid then
                                                Humanoid.Health = 0
                                            end
                                        end)

                                        -- Start playing the animation on both characters, emit the sound.
                                        KillerAnim:Play(0)
                                        SurvivorAnim:Play(0)
                                        if ExSound then
                                            Sounds:PlaySound(ExSound, {
                                                Parent = Root,
                                            })
                                        end

                                        -- Fire a signal for any on-execution abilities the killer may have.
                                        if RuntimeKillerModule.OnExecution then
                                            RuntimeKillerModule:OnExecution(TargetCharacter, Config.ExecutionAnimation or "Execution")
                                        end

                                    end)
                                else
                                    -- If no execution animations are availible, resort to 'ol reliable– flinging the target. 
                                    CommonFunctions.DamagePlayer(SourcePlayer, Humanoid, Damage, Config.Reason, CheckPart.CFrame.LookVector, Config.Knockback)
                                end

                                return
                            end

                        end

                        -- If the hitbox deals damage or healing, inflict it and do some knockback if existent.
                        if Damage ~= 0 then
                            CommonFunctions.DamagePlayer(SourcePlayer, Humanoid, Damage, Config.Reason, CheckPart.CFrame.LookVector, Config.Knockback)
                        end

                        -- If the hitbox applies effects, apply them.
                        if Config.EffectsToApply then
                            for _, Effect in Config.EffectsToApply do
					            CommonFunctions.ApplyEffect(Humanoid, Effect.Name, Effect.Level, Effect.Duration, Effect.Subfolder)
				            end
                        end

                        -- If the hitbox has a callback tied to it, fire it.
                        Hitbox._RunCallback(Config.Connections, "PostHit", Config, Humanoid, Index == 1)
                    end
                end

                -- Repeat the hitbox parsing check once every 40th of a second.
                Props.TimePast += task.wait(1/40)
            else
                break
            end
        end
        
        -- If the hitbox has a callback tied to it for when it ends, run that.
        Hitbox._RunCallback(Config.Connections, "Ended")
    end)

    return Props
end

-- Coordinate a callback for anything that would need to be listening to the hitbox's various states (ending, hitting something, etc.).
function Hitbox._RunCallback(ConnList: {[string]: (any?) -> ()}?, ID: string, ...)
    if ConnList and ConnList[ID] then
        ConnList[ID](...)
    end
end

return Hitbox
