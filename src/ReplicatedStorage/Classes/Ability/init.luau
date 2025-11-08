--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local AbilityType = {}

--- Class used for character abilities.
export type Ability = {
    --- The display name.
    Name: string,
    --- The description used in the character's info.
    Description: string,
    --- The image of the ability in the GUI when playing.
    RenderImage: string,
    --- If the image should have a UICorner just in case it's not round.
    UICorner: boolean,
    --- If it's passive (to hide it in the GUI).
    Passive: boolean,

    --- Internal function to initialize the ability's generally used variables and connections.
    Init: (self: Ability, charModule: any, owner: Player) -> (),
    --- Empty function to execute extra code right after the ability is initialized using `Init`.
    ExtraInit: (self: Ability) -> (),
    --- Empty function to execute extra code right before the ability gets destroyed using `Destroy`.
    OnRemove: (self: Ability) -> (),
    --- Reloads the animation to be `newId`.
    ReloadAnimation: (self: Ability, newId: string) -> (),
    --- Plays the use animation for this ability. Mainly used internally.
    PlayUseAnimation: (self: Ability) -> (),
    --- Destroys the ability, disconnecting any connections it might have, cancelling any threads...
    Destroy: (self: Ability) -> (),

    --- CLIENT FUNCTION: Attempts to use the ability by checking if it's possible in the first place.
    AttemptUse: (self: Ability) -> (),

    --- The name of the input used for the ability, set up in `InputManager`.
    InputName: string,
    --- Literally the behaviour of the ability; what it does. Write your ability here.
    Behaviour: (self: Ability) -> (),

    --- The animation ID of the use animation.
    UseAnimation: string,
    --- The track that `UseAnimation` is tied to.
    UseAnimationTrack: AnimationTrack,
    --- Toggle that lets you not play the use animation when using this ability.
    PlayUseAnimationOnUse: boolean,

    --- The cooldown setting of the ability / how long it takes to recharge. It can also be changed dynamically.
    Cooldown: number,
    --- The timer for the cooldown to finish. Don't tamper with this unless you know what you're doing!
    CooldownTimer: number,
    --- Will be true if the ability is on cooldown.
    OnCooldown: boolean,
    --- Utility to check if the ability can legally be used.
    CanUse: (self: Ability) -> boolean,

    --- The duration of the ability. Mainly used to disable input until it finishes. Doesn't need to be the literal length.
    Duration: number,

    --- If `true`, when using this ability, it'll disable every ability for `Duration` time.
    DisableOtherAbilitiesOnPerform: boolean,
    --- If `true`, when using this ability, it'll disable the Slash ability for `Duration` time.
    --- Only works if the character is a killer and if `DisableOtherAbilitiesOnPerform` is `true`.
    DisableSlashOnPerform: boolean,

    --- The uses / charges left for this ability. Won't matter if uses aren't limited.
    UsesLeft: number,

    --- Settings for uses / charges.
    UseSettings: {
        --- If false, the ability won't care about uses / charges.
        Limited: boolean,
        --- Initial uses / charges for an ability when starting a round.
        InitialUses: number,
    },

    --- Connections and threads that make the ability work. Add any `task.delay()`s or `RBXScriptConnection`s here.
    Connections: {RBXScriptConnection | thread},
    --- The owner of the ability.
    Owner: Player,
    --- The properties of this ability's owner.
    OwnerProperties: {
        --this is hybrid (client & server)
        --- The Character of the owner player. Also gettable through `Owner.Character`.
        Character: Model,
        --- The owner's character's HumanoidRootPart instance for usage. Also gettable through `Owner.Character:FindFirstChild("HumanoidRootPart")`.
        HRP: BasePart,
        --this is server
        --- See `ServerScriptService.System.CommonFunctions`.
        CommonFunctions: any,
        --the rest are all from client
        --- See `StarterPlayerScripts..InputManager`.
        InputManager: any,
        --- See `StarterCharacterScripts.PlayerAttributeScripts.SpeedManager`.
        SpeedManager: any,
        --- See `StarterCharacterScripts.PlayerAttributeScripts.FOVManager`.
        FOVManager: any,
        --- See `StarterCharacterScripts.PlayerAttributeScripts.EffectManager`.
        EffectManager: any,
        --- See `StarterCharacterScripts.Miscellaneous.EmoteManager`.
        EmoteManager: any,
        --- See `StarterCharacterScripts.Miscellaneous.TurnToMoveDirection`.
        TurnToMoveDirection: any,
    },
    --- The source module where the ability comes from. Contains all character info.
    CharModule: any,
}

--- Ability preset for customization.
function AbilityType:GetDefaultAbilitySettings(): Ability
    --instantiates a new `Animation` instance for loading the use animation (CLIENT ONLY)
    local Animation = not RunService:IsServer() and Instance.new("Animation") or nil

    return {
        Name = "Ability",
        Description = "Does something",
        RenderImage = "rbxassetid://9759886280",
        UICorner = true,
        Passive = false,
        
        Init = function(own: Ability, charModule: any, plr: Player)
            own.Owner = plr
            own.CharModule = charModule
            if RunService:IsServer() then
                Utils:Print("Initting "..own.Name.." ability for "..plr.Name)

                --is this exploitable? yes.
                --do i give a fuck? no.
                --thanks byfron.

                own.OwnerProperties = {
                    Character = own.Owner.Character,
                    HRP = Utils:FindFirstChild(own.Owner.Character, "HumanoidRootPart"),
                    CommonFunctions = require(ServerScriptService.System.CommonFunctions),
                }

                table.insert(own.Connections, Network:SetConnection("UsePlayerAbility", "REMOTE_EVENT", function(player: Player, abilityName: string)
                    if player == plr and abilityName == own.Name and own:CanUse() then
                        task.spawn(function()
                            if own.CharModule.Config.Voicelines and own.CharModule.Config.Voicelines[own.Name] then
                                Sounds:PlayVoiceline(own.Owner.Character, own.CharModule.Config.Voicelines[own.Name])
                            end
                        end)

                        --cooldown stuffs
                        own.OnCooldown = true
                        own.CooldownTimer = (own.Cooldown - 0.1) / 2
                        task.spawn(function()
                            for _ = 0.1, own.CooldownTimer * 10 + 1 do
                                task.wait(0.1)
                                own.CooldownTimer -= 0.1
                                if own.CooldownTimer <= 0 then
                                    own.CooldownTimer = 0
                                    break
                                end
                            end
                            own.OnCooldown = false
                        end)

                        Network:FireClientConnection(own.Owner, "UsePlayerAbility", "REMOTE_EVENT", own.Name)
                        if own.Behaviour then
                            own:Behaviour()
                        end
                    end
                end))

                --clearing ability connections to dispose of this code when the player gets readded
                table.insert(own.Connections, plr.CharacterAdded:Connect(function()
                    own:Destroy()
                end))

                --executes any extra initialization code that the ability might need
                if own.ExtraInit then
                    own:ExtraInit()
                end

                return
            end

            own.OwnerProperties = {
                Character = own.Owner.Character,
                HRP = Utils:FindFirstChild(own.Owner.Character, "HumanoidRootPart"),
                InputManager = require(own.Owner.PlayerScripts.InputManager),
                SpeedManager = require(own.Owner.Character.PlayerAttributeScripts.SpeedManager),
                FOVManager = require(own.Owner.Character.PlayerAttributeScripts.FOVManager),
                EffectManager = require(own.Owner.Character.PlayerAttributeScripts.EffectManager),
                EmoteManager = require(own.Owner.Character.Miscellaneous.EmoteManager),
                TurnToMoveDirection = require(own.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
            }

            own.UsesLeft = own.UseSettings.InitialUses
            if #own.UseAnimation > 0 then
                Animation.AnimationId = own.UseAnimation

                --nesting in pcall so that if there's nothing it doesn't matter
                pcall(function()
                    local AnimName = own.Name:gsub(" ", "").."UseAnim"
                    charModule.GameplayConfig.Cache.Animations[AnimName] = Utils:LoadAnimationFromID(own.Owner.Character, own.UseAnimation)
                    own.UseAnimationTrack = charModule.GameplayConfig.Cache.Animations[AnimName]
                end)
            end

            own.PlayUseAnimation = function()
                if own.UseAnimationTrack then
                    own.UseAnimationTrack:Play(0)
	                own.OwnerProperties.TurnToMoveDirection:AddHeadPreventionFactor(own.Name)
                    task.delay(own.UseAnimationTrack.Length - (1/20 * 2), function()
                        own.UseAnimationTrack:Stop(0)
	                    own.OwnerProperties.TurnToMoveDirection:RemoveHeadPreventionFactor(own.Name)
                    end)
                end
            end

            if own.OwnerProperties.InputManager.DefaultActions[own.InputName] ~= nil then
                table.insert(own.Connections, own.OwnerProperties.InputManager.DefaultActions[own.InputName].Pressed:Connect(function()
                    own:AttemptUse()
                end))
            end

            table.insert(own.Connections, Network:SetConnection("UsePlayerAbility", "REMOTE_EVENT", function(abilityName: string)
                if abilityName == own.Name then
                    --disables ability keys for preventing the usage of a different ability while using it
                    if own.DisableOtherAbilitiesOnPerform then
                        for _, input in own.OwnerProperties.InputManager.DefaultActions do
                            if input.Name:lower():find("ability") or (input.Name:lower():find("slash") and own.DisableSlashOnPerform) then
                                input.Enabled = false
                                table.insert(own.Connections, task.delay(if own.UseAnimationTrack then own.UseAnimationTrack.Length else own.Duration, function()
                                    input.Enabled = true
                                end))
                            end
                        end
                    end
                    --cooldown stuffs
                    own.OnCooldown = true
                    own.CooldownTimer = own.Cooldown - 0.1
                    task.spawn(function()
                        for _ = 0.1, own.CooldownTimer * 10 + 1 do
                            task.wait(0.1)
                            own.CooldownTimer -= 0.1
                            if own.CooldownTimer <= 0 then
                                own.CooldownTimer = 0
                                break
                            end
                        end
                        own.OnCooldown = false
                    end)
                    --decreasing uses left if it's supposed to be limited
                    if own.UseSettings.Limited then
                        own.UsesLeft -= 1
                    end
                    --plays any existant use animation
                    if own.PlayUseAnimationOnUse then
                        own:PlayUseAnimation()
                    end
                    --ability stuffs
                    if own.Behaviour then
                        task.spawn(function()
                            own:Behaviour()
                        end)
                    end
                end
            end))

            --clearing ability connections to dispose of this code when the player gets readded
            table.insert(own.Connections, own.Owner.CharacterAdded:Connect(function()
                own:Destroy()
            end))

            --executes any extra initialization code that the ability might need
            if own.ExtraInit then
                own:ExtraInit()
            end
        end,

        ExtraInit = nil,
        OnRemove = nil,

        ReloadAnimation = function(own: Ability, id: string)
            Animation.AnimationId = id
            pcall(function()
                own.UseAnimationTrack = Utils:LoadAnimationFromID(own.Owner.Character, id)
            end)
        end,

        PlayUseAnimation = nil,

        Destroy = function(own: Ability)
            if own.OnRemove then
                own:OnRemove()
            end
            for _, i in own.Connections do
                if typeof(i) == "thread" then
                    task.cancel(i)
                else
                    i:Disconnect()
                end
            end
            table.clear(own.Connections)
        end,

        AttemptUse = function(own: Ability)
            if RunService:IsServer() then
                return
            end

            print(own.CooldownTimer)

            if own:CanUse() then
                Network:FireServerConnection("UsePlayerAbility", "REMOTE_EVENT", own.Name) --i know this is insecure but sue me lol
            end
        end,

        InputName = "FirstAbility",
        Behaviour = nil,

        UseAnimation = "",
        UseAnimationTrack = nil,
        PlayUseAnimationOnUse = true,

        Cooldown = 5,
        CooldownTimer = 0,
        OnCooldown = false,

        --read
        CanUse = function(own: Ability): boolean
            --if it's limited then it should have to have enough uses left
            local EnoughUses = true
            if workspace:GetAttribute("ChargesEnabled") and own.UseSettings.Limited then
                EnoughUses = own.UsesLeft > 0
            end

            --if the ability is on cooldown or not
            local OnCooldown = false
            if workspace:GetAttribute("CooldownsEnabled") and own.OnCooldown then
                OnCooldown = true
            end

            --if the player isn't stunned, thus can be conscious OR has hope (UNDERTALE REFERENCE????)
            local EffectPrevention = false
            if RunService:IsServer() then
                if own.Owner.Character.Effects:FindFirstChild("Stunned") or own.Owner.Character.Effects:FindFirstChild("Helpless") then
                    EffectPrevention = true
                end
            else
                if own.OwnerProperties.EffectManager.Effects["Stunned"] or own.OwnerProperties.EffectManager.Effects["Helpless"] then
                    EffectPrevention = true
                end
            end

            --if the player isn't emoting
            local Emoting = false
            if not RunService:IsServer() then
                Emoting = own.OwnerProperties.EmoteManager.CurrentlyPlayingEmote
            end

            return EnoughUses
            and own.Owner.Character:FindFirstChildOfClass("Humanoid").Health > 0 --if the player's alive
            and not own.Owner.Character:FindFirstChild("HumanoidRootPart").Anchored --if the player isn't restrained by initial round setup
            and not Emoting
            and not EffectPrevention
            and not OnCooldown
        end,
        
        Duration = 0.4,

        DisableOtherAbilitiesOnPerform = true,
        DisableSlashOnPerform = true,

        UsesLeft = 1,

        UseSettings = {
            Limited = false,
            InitialUses = 1,
        },

        Connections = {},
    }
end

return AbilityType