local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages._Index["howmanysmall_janitor@1.18.3"].janitor)
export type Janitor = Janitor.Janitor

local Signal = require(ReplicatedStorage.Utils.Signal)

--- Class used for character abilities.
export type Ability = {
    --- The display name.
    Name: string,
    --- The image of the ability in the GUI when playing.
    RenderImage: string,
    --- If the image should have a UICorner just in case it's not round.
    UICorner: boolean,
    --- If it's passive (to hide it in the GUI).
    Passive: boolean,

    --- Internal function to initialize the ability's generally used variables and connections.
    Init: (self: Ability, charModule: Killer | Survivor, owner: Player) -> (),
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
    --- Modifies the `UsesLeft` property in both client and server.
    --- 
    --- Any `Type` other from `"Set"` can be inconsistent in some very rare ping cases.
    --- 
    --- <b>SHOULD ONLY BE USED IN SERVER.</b>
    ChangeAbilityCharges: (self: Ability, Type: "Set" | "Add" | "Take", amount: number) -> (),

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
    --- The time it'll take to transition between the currently playing animation and this one and viceversa.
    --- 
    --- Overrides `Character.Config.AnimationTransitionTime` for `self.UseAnimation`'s transition time.
    UseAnimationTransitionTime: number,

    --- The cooldown setting of the ability / how long it takes to recharge. It can also be changed dynamically.
    Cooldown: number,
    --- The timer for the cooldown to finish. Don't tamper with this unless you know what you're doing!
    CooldownTimer: number,
    --- Will be `true` if the ability is on cooldown.
    OnCooldown: boolean,
    --- If `true`, the cooldown of this ability will be automatically applied when using it.
    AutomaticCooldown: boolean,
    --- Utility to check if the ability can legally be used.
    CanUse: (self: Ability) -> boolean,
    --- Extra, custom conditions to add to `Ability:CanUse()` instead of replacing the latter.
    --- 
    --- Must return a `boolean`.
    UseConditions: (self: Ability) -> boolean,
    --- Activates this ability's cooldown.
    --- 
    --- A custom cooldown can be specified in `duration`.
    --- If there's nothing set, it'll use `Ability.Cooldown`.
    SetOnCooldown: (self: Ability, duration: number?) -> (),
    --- <b>CLIENT FUNCTION:</b> Disables the input of every ability
    --- 
    --- The duration of the ability disabling is set by the `Duration` parameter. If it's `nil`, it'll fallback to `Ability.Duration`.
    --- 
    --- Will disable the Slash ability if it exists depending on `Ability.DisableSlashOnPerform`, which can be overriden by `DisableSlash`.
    --- 
    --- Won't take `DisableOtherAbilitiesOnPerform` into account as that's what calls this function automatically.
    DisableAllAbilities: (self: Ability, Duration: number?, DisableSlash: boolean?) -> (),

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

    Signals: {
        ChargesChanged: Signal.Signal<number>,
        Used: Signal.Signal<>,
        CooldownSet: Signal.Signal<number>,
    },

    --- Adds a connection / thread to the ability's janitor to be disposed of when the owner's character is destroyed.
    --- 
    --- Use this to make connections and threads.
    AddConnection: <T>(self: Ability, Connection: T & (RBXScriptConnection | thread)) -> T & (RBXScriptConnection | thread),
    --- Adds a connection / thread to the ability's janitor to be disposed of when the owner's character is destroyed.
    --- 
    --- Differs from `Ability:AddConnection()` in that the connections added through this function will be cancelled when the character gets stunned.
    --- 
    --- Use this to make connections and threads that can be cancelled when the character is stunned.
    AddStunnableConnection: <T>(self: Ability, Connection: T & (RBXScriptConnection | thread)) -> T & (RBXScriptConnection | thread),
    --- The table containing all connections currently instanced that can be cancelled through a stun.
    --- 
    --- Should only be used internally.
    StunnableConnections: {RBXScriptConnection | thread},
    --- The owner of the ability.
    Owner: Player,
    --- The ability's Janitor instance.
    --- 
    --- Used to make cleanups easier.
    Janitor: Janitor,
    --- The properties of this ability's owner.
    OwnerProperties: {
        --- The Character of the owner player. Also gettable through `Owner.Character`.
        Character: Model,
        --- The owner's character's `Humanoid` instance for usage. Also gettable through `Utils.Character.GetAlivePlayerHumanoid(Owner)`.
        Humanoid: Humanoid,
        --- The owner's character's `HumanoidRootPart` instance for usage. Also gettable through `Utils.Character.GetRootPart(Owner)`.
        HRP: BasePart,
        --- See `StarterPlayerScripts.InputManager`.
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
        --- See `StarterCharacterScripts.PlayerAbilities.Default.Sprinting`.
        Sprinting: any,
        --- See `StarterCharacterScripts.AnimationManager`.
        AnimationManager: any,
    },
    --- The source module where the ability comes from. Contains all character info.
    CharModule: Killer | Survivor,
}

--- Type used for survivor characters.
export type Survivor = {
    --- The player that currently owns the character instance.
    Owner: Player,
    --- Config that shouldn't affect gameplay mechanics.
    Config: {
        --- The display name of the character.
        Name: string,
        --- The character's `More Info` page content.
        --- 
        --- To know how to write this, check the example characters's modules.
        Description: {
            --- A section of the `More Info` page of this character.
            {
                --- The type of text this section will be.
                Type: "Text" | "Header" | "Separator" | "Quote",
                --- The text displayed in this section.
                Text: string,
                --- The displayed image in this section. Used for ability descriptions. Only usable in the `Text` type.
                Image: string?,
            }
        },
        --- A possible quote from the character that'll show up when you buy it.
        Quote: string,

        --- Information on where this character / skin originates from.
        --- 
        --- Anything set on here will be displayed in the character's / skin's card in the shop and in the inventory.
        Origin: {
            --- The text displayed on a tooltip when hovering over the icon.
            --- 
            --- Example: `"Originates from Die of Death!"`
            TooltipText: string?,
            --[=[
                The ID of the icon displayed in the character's / skin's card.
            
                Should be the icon of the place it originates from.
            ]=]
            Icon: string?,
        }?,
        --[=[
            Some properties of this character's card outline in the shop and inventory.
            
            Commonly used for achievement-only items to tell them apart from shop items.
            
            May also be used in more interesting ways.
        ]=]
        CardFrame: {
            --- The image ID of the outline.
            Image: string?,
            --[=[
                The size of the outline.

                `UDim2.fromScale()` should be used and its values should be similar to `{1, 1}`.
            ]=]
            Size: UDim2?,
        }?,

        --- The price of this character in the shop.
        Price: number,
        --- The render image / portrait ID of this character.
        Render: string?,

        --- All AnimationIDs related to this character.
        AnimationIDs: {
            --- The animation that'll play on an idle state.
            IdleAnimation: string,
            --- The animation that'll play on a walking state.
            WalkAnimation: string,
            --- The animation that'll play on a running state.
            RunAnimation: string,
            --- The animation that'll play on stun.
            Stunned: string?,
            --- The animation that'll play after `Stunned` if the stun is longer than the duration of `Stunned` and `StunnedEnd` combined.
            StunnedLoop: string?,
            --- The animation that'll play before a stun ends.
            StunnedEnd: string?,
            --- The animation that'll play in the character model's preview in the shop.
            --- 
            --- If none is provided, `IdleAnimation` will play instead.
            PreviewAnimation: string?,
        },

        --- The time it'll take to transition between animations.
        --- 
        --- Will be overriden by abilities if their `Ability.AnimationTransitionTime` exists, but will still work for idle, walk and run animations.
        AnimationTransitionTime: number,

        --[=[
            Any voicelines this character might have. It's built with strings as keys, and either strings or string dictionaries as values for random voicelines.
            
            For killers, use `Kill` to set the kill voicelines.
            
            In it set a `Default` value for any survivor.
            
            You may set customs for skins and characters using `"[SkinName][CharacterName]"` format.
            
            Remove `[SkinName]` to make it for a survivor in general.
        ]=]
        Voicelines: {
            --- The voiceline (s) that'll play at random times while the character isn't saying any other voiceline.
            Idle: (string | {string})?,
            --[=[
                The voiceline (s) that'll play when LMS starts.
                
                If there's any character that you want this character to have a custom voiceline for, add its codename here.
                
                If there's a specific skin, add the skin's codename at the beginning and *then* add the character's codename (e.g. `[SkinName][CharacterName]`, without spaces).
            ]=]
            LMS: {
                --- The default voiceline (s).
                Default: string | {string} | {[string]: string | {string}},
                [string]: string | {string} | {[string]: string | {string}},
            }?,
            --- The voiceline (s) that'll play when the character gets stunned. Yes, you can do this with survivors.
            Stunned: (string | {string})?,

            [string]: string | {string} | {[string]: string | {string}},
        },

        --[=[
            The names of the milestones for this character, defined by the number of the level they're granted on.    
        
            e.g. for making a Milestone II (lvl 50), I would define it like so:

            ```lua
            [CHARACTER_VARIABLE_NAME] = Character.CreateKiller({
                Config = {
                    Milestones = {
                        [50] = "CharacterMilestoneII", -- The level it's granted on -> The name of the skin's module
                    },
                },
            })
            ```
        ]=]
        Milestones: {[number]: string},

        --- Any SFX that you may want to play with the character.
        --- Voicelines go in `Voicelines`.
        Sounds: {
            --- The sound the character'll make when taking a step.
            --- 
            --- The walk & run animations MUST have a `Footstep` animation event when they take a step for this to work.
            --- 
            --- If an array of strings is passed, the game'll choose a random sound every time.
            FootstepSounds: (string | {string})?,
            [string]: (string | {string}),
        },
    },

    --- Gameplay mechanics config that will affect how the character works.
    GameplayConfig: {
        --- Amount of health.
        Health: number,
        --- The base number of the speed of this character (the walking speed).
        BaseSpeed: number,
        --- The number that the base speed will be multiplied by when sprinting.
        SprintSpeedMultiplier: number,
        --- Useful stamina properties that you can change.
        StaminaProperties: {
            --- The maximum amount of stamina.
            MaxStamina: number,
            --- How fast the stamina drains.
            StaminaDrain: number,
            --- How fast the stamina gets regained.
            StaminaGain: number,
        },

        --- All of the initialized abilities the character has.
        Abilities: {[string]: Ability},
        --- Any temp objects or instances that might be created mid-match.
        Cache: {[string]: any},
    },

    --- An empty function that you can replace to execute custom behaviour when this character initializes.
    OnInit: (self: Survivor, charModel: Model) -> ()?,
    --- SERVER FUNCTION: An empty function that you can replace to execute custom behaviour when this character gets hit.
    --- 
    --- If you want the character to not get affected by the hit, you can return `"Ignored"`.
    OnHit: (self: Survivor, hitbox: any, damage: number) -> (string?)?,
}

--- Type used for killer characters.
export type Killer = {
    --- The player that currently owns the character instance.
    Owner: Player,
    --- Config that shouldn't affect gameplay mechanics.
    Config: {
        --- The display name of the character.
        Name: string,
        --- The character's `More Info` page content.
        --- 
        --- To know how to write this, check the example characters's modules.
        Description: {
            --- A section of the `More Info` page of this character.
            {
                --- The type of text this section will be.
                Type: "Text" | "Header" | "Separator" | "Quote",
                --- The text displayed in this section.
                Text: string | {string},
                --- The displayed image in this section. Used for ability descriptions. Only usable in the `Text` type.
                Image: string?,
            }
        },
        --- A possible quote from the character that'll show up when you buy it.
        Quote: string,

        --- Information on where this character / skin originates from.
        --- 
        --- Anything set on here will be displayed in the character's / skin's card in the shop and in the inventory.
        Origin: {
            --- The text displayed on a tooltip when hovering over the icon.
            --- 
            --- Example: `"Originates from Die of Death!"`
            TooltipText: string?,
            --[=[
                The ID of the icon displayed in the character's / skin's card.
            
                Should be the icon of the place it originates from.
            ]=]
            Icon: string?,
        }?,
        --[=[
            Some properties of this character's card outline in the shop and inventory.
            
            Commonly used for achievement-only items to tell them apart from shop items.
            
            May also be used in more interesting ways.
        ]=]
        CardFrame: {
            --- The image ID of the outline.
            Image: string?,
            --[=[
                The size of the outline.

                `UDim2.fromScale()` should be used and its values should be similar to `{1, 1}`.
            ]=]
            Size: UDim2?,
        }?,

        --- The price of this character in the shop.
        Price: number,
        --- The render image / portrait ID of this character.
        Render: string?,

        --- A possible custom LMS theme the character might have.
        --- If it's a table of strings, a random one will be pulled.
        LastManStandingTheme: (string | {string})?,
        --- Any possible LMS's for this character VS another specific character.
        --- Every entry in this table should be `CHARACTERMODULENAME = {Default = ID, SKINNAME = ID, ...}`, e.g. `Commander = {Default = "rbxassetid://0000000000"}`.
        --- You can add skins by making a new field in the table named after the skin's module's name, e.g. `Yourself = "rbxassetid://0000000000"`.
        --- If and ID is a table of strings, a random one will be pulled.
        SpecialLastManStandings: {[string]: {
            Default: string | {string},
            [string]: string | {string},
        }}?,

        --- All AnimationIDs related to this character.
        AnimationIDs: {
            --- The animation that'll play on an idle state.
            IdleAnimation: string,
            --- The animation that'll play on a walking state.
            WalkAnimation: string,
            --- The animation that'll play on a running state.
            RunAnimation: string,
            --- The animation that'll play on stun.
            Stunned: string?,
            --- The animation that'll play after `Stunned` if the stun is longer than the duration of `Stunned` and `StunnedEnd` combined.
            StunnedLoop: string?,
            --- The animation that'll play before a stun ends.
            StunnedEnd: string?,
            --- The animation that'll play in the character model's preview in the shop.
            --- 
            --- If none is provided, `IdleAnimation` will play instead.
            PreviewAnimation: string?,
            --- The animation that the killer will have in the intro animation.
            KillerRig: string?,
            --- The animation that the camera will have in the intro animation.
            CameraRig: string?,
            --- The animations that'll play when executing a player.
            --- 
            --- Inside, make a `Default` for any survivor.
            --- 
            --- You may make others with the `"[SkinName][CharacterName]"` format to add customs for skins and characters, e.g. `YourselfCommander = "rbxassetid://0000000000"`.
            --- 
            --- Remove `[SkinName]` to make it for a survivor in general, e.g. `Commander = "rbxassetid://0000000000"`.
            Execution: {
                Default: {
                    Killer: string,
                    Survivor: string,
                },
                [string]: {
                    Killer: string,
                    Survivor: string,
                },
            }?,
        },

        --- The time it'll take to transition between animations.
        --- 
        --- Will be overriden by abilities if their `Ability.AnimationTransitionTime` exists, but will still work for idle, walk and run animations.
        AnimationTransitionTime: number,

        

        --[=[
            Any voicelines this character might have. It's built with strings as keys, and either strings or string dictionaries as values for random voicelines.
            
            For killers, use `Kill` to set the kill voicelines.
            
            In it set a `Default` value for any survivor.
            
            You may set customs for skins and characters using `"[SkinName][CharacterName]"` format.
            
            Remove `[SkinName]` to make it for a survivor in general.
        ]=]
        Voicelines: {
            --[=[
                The voiceline (s) that'll play when this character kills a survivor.
                
                If there's any character that you want this character to have a custom voiceline for, add its codename here.
                
                If there's a specific skin, add the skin's codename at the beginning and *then* add the character's codename (e.g. `[SkinName][CharacterName]`, without spaces).
            ]=]
            Kill: {
                --- The default voiceline (s).
                Default: (string | {string}),
                [string]: (string | {string}),
            }?,
            --- The voiceline (s) that'll play at random times while the character isn't saying any other voiceline.
            Idle: (string | {string})?,
            --[=[
                The voiceline (s) that'll play when LMS starts.
                
                If there's any character that you want this character to have a custom voiceline for, add its codename here.
                
                If there's a specific skin, add the skin's codename at the beginning and *then* add the character's codename (e.g. `[SkinName][CharacterName]`, without spaces).
            ]=]
            LMS: {
                --- The default voiceline (s).
                Default: string | {string},
                [string]: string | {string} | {[string]: string | {string}},
            }?,
            --- The voiceline (s) that'll play when the character gets stunned.
            Stunned: (string | {string})?,

            [string]: string | {string} | {[string]: string | {string}},
        },

        --- The chase theme of the character, separated in layers that depend on distance between the survivors and the killer.
        ChaseThemes: {
            --- Layer 1: 60 studs.
            L1: string,
            --- Layer 2: 45 studs.
            L2: string,
            --- Layer 3: 30 studs.
            L3: string,
            --- Chase music: 15 studs (will stop when back at 60).
            L4: string,
        },

        --[=[
            The names of the milestones for this character, defined by the number of the level they're granted on.    
        
            e.g. for making a Milestone II (lvl 50), I would define it like so:

            ```lua
            [CHARACTER_VARIABLE_NAME] = Character.CreateKiller({
                Config = {
                    Milestones = {
                        [50] = "CharacterMilestoneII", -- The level it's granted on -> The name of the skin's module
                    },
                },
            })
            ```
        ]=]
        Milestones: {[number]: string},

        --- CLIENT FUNCTION: Empty function to execute code when the killer intro initializes (loads its content).
        --- 
        --- `KillerRig` and `CameraRig` will be `nil` when it's a 2D intro (`UiIntro`).
        OnIntroInit: (self: Killer, intro: AnimatedIntro | UiIntro, KillerRig: Model, CameraRig: Model) -> ()?,
        --- CLIENT FUNCTION: Empty function to execute code when the killer intro plays.
        --- 
        --- `KillerRig` and `CameraRig` will be `nil` when it's a 2D intro (`UiIntro`).
        OnIntroPlay: (self: Killer, intro: AnimatedIntro | UiIntro, KillerRig: Model, CameraRig: Model, AnimDuration: number) -> ()?,

        --- Any SFX that you may want to play with the character.
        --- Voicelines go in `Voicelines`.
        Sounds: {
            --- The sound that'll play when the killer's intro plays.
            --- 
            --- Can also be a table to play a random sound.
            IntroSound: (string | {string})?,
            --- The sound the character'll make when taking a step.
            --- 
            --- The walk & run animations MUST have a `Footstep` animation event when they take a step for this to work.
            --- 
            --- If an array of strings is passed, the game'll choose a random sound every time.
            FootstepSounds: (string | {string})?,
            --- The SFX of the Execution animations.
            --- Since animations may vary, it's possible to set custom sounds for each.
            Execution: {
                Default: (string | {string}),
                [string]: (string | {string}),
            },
            [string]: (string | {string}),
        },

        --- The CFrame value that'll be added to a survivor's CFrame when snapping to a killer's CFrame by being executed by them.
        --- 
        --- Defaults to `CFrame.new(0, 0, 5)` in `Hitbox`.
        ExecutionSurvivorCFrameOffset: CFrame?,
    },

    --- Gameplay mechanics config that will affect how the character works.
    GameplayConfig: {
        --- Amount of health.
        Health: number,
        --- The base number of the speed of this character (the walking speed).
        BaseSpeed: number,
        --- The number that the base speed will be multiplied by when sprinting.
        SprintSpeedMultiplier: number,
        --- Useful stamina properties that you can change.
        StaminaProperties: {
            --- The maximum amount of stamina.
            MaxStamina: number,
            --- How fast the stamina drains.
            StaminaDrain: number,
            --- How fast the stamina gets regained.
            StaminaGain: number,
        },

        --- All of the initialized abilities the character has, counting the slash.
        Abilities: {[string]: Ability},
        --- Any temp objects or instances that might be created mid-match.
        Cache: {[string]: any},
    },

    --- An empty function that you can replace to execute custom behaviour when this character initializes.
    OnInit: (self: Killer, charModel: Model) -> ()?,
    --- SERVER FUNCTION: An empty function that you can replace to execute custom behaviour when this character gets hit.
    --- 
    --- If you want the character to not get affected by the hit, you can return `"Ignored"`.
    OnHit: (self: Killer, hitbox: any, damage: number) -> (string?)?,
    --- SERVER FUNCTION: An empty function that you can replace to execute custom behaviour when this character executes a survivor (the animation MUST be set).
    OnExecution: ((self: Killer, victim: Model, usedAnimName: string) -> ())?,
}

--- Type used for 2D killer intros.
export type UiIntro = {
    --- Connections and threads that make the intro work. Add any `task.delay()`s or `RBXScriptConnection`s here.
    Connections: {RBXScriptConnection & thread},
    --- Everything that'll be removed after the intro ends.
    Disposables: {[string]: Instance},

    --- Function used to prepare the intro to be played.
    Init: (self: UiIntro) -> (),
    --- Plays the intro.
    Play: (self: UiIntro) -> (any),
    --- Used when the intro ends so that everything gets disposed.
    Destroy: (self: UiIntro) -> (),

    --- The module of the character for custom usage.
    Module: Killer,
    --- The player's VideoPlayer that'll be used to play the intro's sprite animation if it has one.
    VideoPlayer: any,
}

--- Type used for 3D killer intros.
export type AnimatedIntro = {
    --- Connections and threads that make the intro work. Add any `task.delay()`s or `RBXScriptConnection`s here.
    Connections: {RBXScriptConnection & thread},
    --- Everything that'll be removed after the intro ends.
    Disposables: {[string]: Instance},
    --- All of the animations that are used in the intro.
    Animations: {[string]: AnimationTrack},

    --- Function used to prepare the intro to be played.
    Init: (self: AnimatedIntro) -> (),
    --- Plays the intro.
    --- @return The killer rig.
    --- @return The camera rig.
    --- @return The length of the camera rig's animation.
    Play: (self: AnimatedIntro) -> (Model, Model, number),
    --- Used when the intro ends so that everything gets disposed.
    Destroy: (self: AnimatedIntro) -> (),

    --- The module of the character for custom usage.
    Module: Killer,
}

--- Class used for Status Effects (e.g. speed, weakness...).
export type Effect = {
    --- Display name of the Effect.
    Name: string,
    --- Description of the Effect (used when hovering over it in a character's info page).
    Description: string,
    --- Default duration of the Effect. Can be changed right before applying.
    Duration: number,
    --- Default level of the Effect. Can be changed right before applying.
    Level: number,

    --- INTERNAL: Applies the effect and executes `ApplyEffect()`.
    Apply: (own: Effect, level: number, char: Model, duration: number) -> (),
    --- INTERNAL: Removes the effect and executes `RemoveEffect()`.
    Remove: (own: Effect, char: Model) -> (),

    --- Function that should contain the code executed when the effect is applied (custom functionality).
    ApplyEffect: (own: Effect, level: number, char: Model, duration: number) -> (),
    --- Function that should contain the code executed when the effect is removed (custom functionality).
    RemoveEffect: (own: Effect, char: Model) -> (),

    --- The time left for the Effect to wear off.
    TimeLeft: number,
    --- If true, it'll show the effect's name, level and time left on a card on the right side of the screen while it remains.
    ShowInGUI: boolean,
}

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
    Init: (self: Emote, owner: Player, animator: Animator) -> (),
    BaseBehaviour: (self: Emote) -> (),
    Behaviour: ((self: Emote, character: Model) -> ())?,
    --- Callback for when the emote stops.
    OnStop: ((self: Emote, character: Model) -> ())?,

    Animator: Animator,
    HumanoidRootPart: BasePart,
    SpeedManager: {any},
    TurnToMoveDirection: {any},

    TrackPlaying: AnimationTrack,
    AddConnection: <T>(self: Emote, Connection: T & (RBXScriptConnection | thread)) -> T & (RBXScriptConnection | thread),

    Owner: Player,
    Janitor: Janitor,
}

--- Settings type for all hitboxes.
export type HitboxSettings = {
    --- Size of the hitbox in studs.
    Size: Vector3,
    --- Offset for the assigned CFrame in the settings. Useful to e.g. move hitbox backwards or forwards for adjusting.
    CFrameOffset: CFrame?,
    --- Coordinate Frame of the hitbox. May also be a function to update it dynamically.
    CFrame: CFrame? | () -> (CFrame)?,
    --- Damage inflicted to any hit humanoids.
    Damage: number,
    --- Determines how long the hitbox will last.
    Time: number,
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
    Reason: string,
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
        --- If this effect has already been applied, overwrite the existing one.
        OverwriteExisting: boolean?,
	}}?,
    --- Any callbacks for events fired in the hitbox's functionality.
    -- TODO: write what connections there are and what they do
    Connections: {[string]: (any?) -> ()}?,
}

--- Details on a hitbox's current stats
export type HitboxDetails = {
    --- The humanoids the hitbox has already hit.
    HumanoidsHit: {Humanoid},
    --- The player that created this hitbox.
    Creator: Player,
    --- The damage this hitbox deals.
    Damage: number,
    --- The time that's passed since the creation of the hitbox.
    TimePast: number,
    --- If the hitbox has been cancelled.
    Cancelled: boolean,
    --- The multiple connections of this hitbox to detect if the character gets stunned or destroyed.
    Connections: {RBXScriptConnection},
    --- Cancels the hitbox and destroys it.
    --- 
    --- Call this with a `:`.
    Cancel: (self: HitboxDetails) -> (),
}

--- Holds data for any given projectile
export type Projectile = {
    --- The player that created the projectile.
    SourcePlayer: Player,
    --- The model of the projectile.
    --- It has to have a `CollisionBox` part inside of it that acts as a hitbox for `DestroyOnCollision` if it's `true`.
    --- If it's a model, make a `Pivot` part inside it that represents the center and make it the `PrimaryPart` property.
    --- Then, weld every other part in the model to it.
    -- TODO: fix MODEL projectiles since only BasePart projectiles work properly
    Model: (Model | BasePart),
    --- The initial position of the projectile.
    StartingCFrame: CFrame?,
    --- The speed of the projectile.
    Speed: number,
    --- How much the projectile will rotate in its lifetime.
    --- Use `CFrame.fromEulerAnglesXYZ()` and `math.rad()` for this.
    FinalRotation: CFrame?,
    --- How much time in seconds it'll take for the projectile to be removed naturally.
    Lifetime: number,
    --- The behaviour of the throw.
    --- * If it's `Forward`, it'll be thrown relative to the `Forward` vector of `StartingCFrame`.
    --- * If it's `Mouse`, it'll be thrown towards where the mouse is pointing at.
    ThrowType: ("Forward" | "Mouse")?,
    --- The settings of the projectile's hitbox.
    HitboxSettings: HitboxSettings?,
    --- If `true`, the projectile will be destroyed whenever it collides with a part, including players.
    DestroyOnCollision: boolean?,

    --- Callback fired when the projectile is about to be destroyed by `Projectile:Destroy()` when it gets called from colliding with something when `DestroyOnCollision` is `true`.
    OnHitDestroy: (self: Projectile, Details: ProjectileDetails) -> "PreventDestruction"?,
    --- Callback fired when the projectile is about to be destroyed by `Projectile:Destroy()`.
    OnDestroy: (self: Projectile, Details: ProjectileDetails) -> (),
}

export type ProjectileDetails = {
    --- The model of the projectile.
    Model: Instance & (BasePart | Model),
    --- The tween that acts as the projectile's movement.
    Tween: Tween,
    --- The hitbox associated to this projectile.
    Hitbox: HitboxDetails,
    --- Destroys this projectile by destroying the model and cancelling the hitbox.
    Destroy: (self: ProjectileDetails) -> (),
}

export type Achievement = {
    --- This achievement's display name.
    Title: string,
    --- If `HideTitleIfLocked` is `true` and the achievement hasn't been unlocked, this will be the display title instead of `Title`.
    HiddenTitle: string?,
    --- This achievement's description.
    --- 
    --- Should generally display *how* to get this achievement.
    Description: string,
    --- If `HideDescriptionIfLocked` is `true` and the achievement hasn't been unlocked, this will be the description instead of `Description`.
    HiddenDescription: string?,
    --- This achievement's *square* icon ID.
    Icon: string,
    --- The icon for the lock displayed if this achievement hasn't been unlocked if `HideIconIfLocked` is `true`.
    LockIcon: string?,
    --- If `true`, the title of this achievement will be displayed as interrogation marks if it hasn't been unlocked.
    HideTitleIfLocked: boolean?,
    --- If `true`, the description of this achievement will be displayed as interrogation marks if it hasn't been unlocked.
    HideDescriptionIfLocked: boolean?,
    --- If `true`, the icon of this achievement will be displayed as a lock (defined in `LockIcon`) if it hasn't been unlocked.
    HideIconIfLocked: boolean?,
    --- If `true`, the reward given by obtaining this achievement won't be displayed on hover until it's unlocked if applicable.
    HideRewardIfLocked: boolean?,
    --- The ID of the Roblox badge equivalent to this achievement. **Completely optional.**
    BadgeID: number?,
    --- The type of reward to grant when granting this achievement if applicable.
    RewardType: "Currency" | "Skin" | "Character" | "Emote",
    --- Amount of currency to grant when this achievement is granted if `RewardType == "Currency"`.
    Amount: number?,
    --- Name of the character / emote to grant when this achievement is granted if `RewardType ~= nil and RewardType ~= "Currency"`.
    --- 
    --- If it's not an emote, also fill `CharacterRole` with either `Killer` or `Survivor`.
    --- 
    --- For skins, name this variable like the character the skin is for, and add the skin's name to `Skin`.
    Item: string?,
    --- The role of the character / skin to grant if `RewardType == "Skin" or RewardType == "Character"`.
    CharacterRole: ("Killer" | "Survivor")?,
    --- Name of the skin to grant if applicable. Also fill `Item`.
    Skin: string?,
    --- Place in the list of its achievement group.
    LayoutOrder: number,
    --- Any numeric requirement to automatically grant this achievement (useful for e.g. milestone achievements).
    Requirement: number?,
    --- If `true`, the achievement will be fully hidden in the achievements menu unless it's been unlocked (useful for e.g. event achievements).
    Hide: boolean?,
}

export type Item = {
    --- The display name of this item.
    Name: string,
    --- The tool that'll be copied over to this item's owner.
    ToolPrefab: Tool,
    --- The icon of this item in the GUI-
    Icon: string?,

    --- INTERNAL: Initializes this item.
    Init: (self: Item, owner: Player) -> (),
    --- INTERNAL: Called when `ToolInstance.Equipped` is fired. Don't replace this.
    Equip: (self: Item) -> (),
    --- INTERNAL: Called when `ToolInstance.Unequipped` is fired. Don't replace this.
    Unequip: (self: Item) -> (),

    --- Callback executed after `Item.Equip()` is called.
    OnEquip: ((self: Item) -> ())?,
    --- Callback executed after `Item.Unequip()` is called.
    OnUnequip: ((self: Item) -> ())?,

    --- Callback executed when `ToolInstance.Activated` is fired.
    --- 
    --- Write your item logic here-
    Behaviour: (self: Item) -> (),

    --- Any animation IDs to load to `Owner`'s character.
    AnimationIDs: {
        --- Played when `Equip()` is called.
        Equip: string?,
        --- Played after `AnimationIDs.Equip`. If the latter is `nil`, this'll be played instantly in its place.
        Idle: string?,
        --- Played when `Behaviour()` is called.
        Use: string?,
        [string]: string,
    },
    SoundIDs: {
        --- Played when `Equip()` is called.
        Equip: string?,
        --- Played when `Unequip()` is called.
        Unequip: string?,
        --- Played when `Behaviour()` is called.
        Use: string?,
        [string]: string,
    },

    --- Any `AnimationTrack` instances generated when and ID from `AnimationIDs` when this tool is initialized.
    AnimationTracks: {[string]: AnimationTrack},

    --- Adds a connection / thread to the item's janitor to be disposed of when the owner's character is destroyed.
    --- 
    --- Use this to make connections and threads.
    AddConnection: <T>(self: Item, Connection: T & (RBXScriptConnection | thread)) -> T & (RBXScriptConnection | thread),
    --- Adds a connection / thread to the item's janitor to be disposed of when the owner's character is destroyed.
    --- 
    --- ## This function should be used for connections that WILL be cancelled / disconnected when the item is unequipped.
    --- 
    --- Use this to make connections and threads.
    AddUseConnection: <T>(self: Item, Connection: T & (RBXScriptConnection | thread)) -> T & (RBXScriptConnection | thread),
    UseConnections: {RBXScriptConnection | thread},

    --- The owner of this item.
    Owner: Player,
    --- The properties of this item's owner.
    OwnerProperties: {
        --- The Character of the owner player. Also gettable through `Owner.Character`.
        Character: Model,
        --- The owner's character's `Humanoid` instance for usage. Also gettable through `Utils.Character.GetAlivePlayerHumanoid(Owner)`.
        Humanoid: Humanoid,
        --- The owner's character's `HumanoidRootPart` instance for usage. Also gettable through `Utils.Character.GetRootPart(Owner)`.
        HRP: BasePart,
        --- See `StarterPlayerScripts.InputManager`.
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
        --- See `StarterCharacterScripts.PlayerAbilities.Default.Sprinting`.
        Sprinting: any,
        --- See `StarterCharacterScripts.AnimationManager`.
        AnimationManager: any,
    },
    --- The `Janitor` instance of this item.
    Janitor: Janitor,
    --- The `Tool` instance in the backpack of `Owner` when this item is initialized and live.
    ToolInstance: Tool,
}

export type PickableItem = {
    --- The equivalent `Item` of this pickable item to give when picking it up.
    ItemEquivalent: Item,
    --- An optional name to use in the `ProximityPrompt` instance of this item instead of `ItemEquivalent.Name`.
    DisplayName: string?,
    --- A description / quote under this pickable item's name in its `ProximityPrompt`.
    Description: string,
    --- The model to spawn in the map with its `ProximityPrompt`.
    Model: Model,
    --- Any offset to apply to `Model` when spawning it in the map.
    CFrameOffset: CFrame?,
    --- If specified, the rotation of the model when this item spawns in the map will be random in every axis set in this table.
    --- 
    --- If this table is `nil` or the table is empty, it won't do anything.
    --- 
    --- Defining this as `"All"` is the same as defining it as `{"X", "Y", "Z"}`
    RandomRotation: ({"X" | "Y" | "Z"} | "All")?,

    --- Initializes this item. Should only be called when spawning this item by either dropping it or spawning a map.
    Init: (self: PickableItem) -> (),

    --- This pickable item's `Janitor` instance.
    Janitor: Janitor,

    --- Adds a connection / thread to the item's janitor to be disposed of when the owner's character is destroyed.
    --- 
    --- Use this to make connections and threads.
    AddConnection: <T>(self: PickableItem, Connection: T & (RBXScriptConnection | thread)) -> T & (RBXScriptConnection | thread),
    --- The physical model of this item that is currently in the map.
    ModelInstance: Model,
}

return {}
