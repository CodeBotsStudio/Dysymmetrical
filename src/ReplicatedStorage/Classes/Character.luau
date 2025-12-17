--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local KillerIntro = require(script.Parent.KillerIntro)

local CharTypes = {
    AutoLoadedAnims = {
        "Idle",
        "Walk",
        "Run",
        "Stunned",
        "StunnedEnd",
        "Preview",
        "Slash",
        "KillerRig",
        "CameraRig",
        "Execution",
    }
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
            Idle: (string | {string} | {[string]: string | {string}})?,
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
            Stunned: (string | {string} | {[string]: string | {string}})?,

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
        Abilities: {[string]: any},
        --- Any temp objects or instances that might be created mid-match.
        Cache: {
            Animations: {[string]: AnimationTrack},
            [string]: any,
        },
    },

    --- An empty function that you can replace to execute custom behaviour when this character initializes.
    OnInit: (self: Survivor, charModel: Model) -> ()?,
    --- SERVER FUNCTION: An empty function that you can replace to execute custom behaviour when this character gets hit.
    --- 
    --- If you want the character to not get affected by the hit, you can return `"Ignored"`.
    OnHit: (self: Survivor, hitbox: any, damage: number) -> (string?)?,
}

--- Survivor preset for customization.
function CharTypes.GetDefaultSurvivorSettings(): Survivor
    return {
        Owner = nil,
        Config = {
            Name = "Survivor",
            Description = {
                {
                    Type = "Text",
                    Text = "PLACEHOLDER",
                },
            },
            Quote = "hello",

            Price = 0,
            Render = "",

            AnimationIDs = {
                IdleAnimation = "rbxassetid://128254839975087",
                WalkAnimation = "rbxassetid://95139037304316",
                RunAnimation = "rbxassetid://84289923509689",
            },

            AnimationTransitionTime = 0.3,

            Voicelines = {},

            Sounds = {},
        },

        GameplayConfig = {
            Health = 100,
            BaseSpeed = 10.5,
            SprintSpeedMultiplier = 26 / 10.5,
            StaminaProperties = {
                MaxStamina = 100,
                StaminaDrain = 10,
                StaminaGain = 20,
            },

            Abilities = {},
            Cache = {
                Animations = {},
            },
        },

        OnInit = nil,
        OnHit = nil,
    }
end

--- Creates a survivor with the settings specified in `Props`.
--- 
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function CharTypes.CreateSurvivor(Props: Survivor): Survivor
    Props = Props or {}
    local Final = CharTypes.GetDefaultSurvivorSettings()

    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

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
            Idle: (string | {string} | {[string]: string | {string}})?,
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
            --- The voiceline (s) that'll play when the character gets stunned.
            Stunned: (string | {string} | {[string]: string | {string}})?,

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
        OnIntroInit: (self: Killer, intro: KillerIntro.AnimatedIntro | KillerIntro.UiIntro, KillerRig: Model, CameraRig: Model) -> ()?,
        --- CLIENT FUNCTION: Empty function to execute code when the killer intro plays.
        --- 
        --- `KillerRig` and `CameraRig` will be `nil` when it's a 2D intro (`UiIntro`).
        OnIntroPlay: (self: Killer, intro: KillerIntro.AnimatedIntro | KillerIntro.UiIntro, KillerRig: Model, CameraRig: Model, AnimDuration: number) -> ()?,

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
        Abilities: {any},
        --- Any temp objects or instances that might be created mid-match.
        Cache: {
            Animations: {[string]: AnimationTrack},
            [string]: any,
        },
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

--- Killer preset for customization.
function CharTypes.GetDefaultKillerSettings(): Killer
    return {
        Owner = nil,
        Config = {
            Name = "Killer",
            Description = {
                {
                    Type = "Text",
                    Text = "PLACEHOLDER",
                },
            },
            Quote = "hello",

            Price = 0,
            Render = "",

            LastManStandingTheme = "rbxassetid://125799740823318",
            SpecialLastManStandings = {},

            AnimationIDs = {
                IdleAnimation = "rbxassetid://138818467051890",
                WalkAnimation = "rbxassetid://96779101755387",
                RunAnimation = "rbxassetid://139221510401164",
            },

            AnimationTransitionTime = 0.3,

            Voicelines = {},

            ChaseThemes = {
                L1 = "rbxassetid://101608255438688",
                L2 = "rbxassetid://122380833390973",
                L3 = "rbxassetid://78435073515542",
                L4 = "rbxassetid://100400124559989",
            },

            Sounds = {},
        },

        GameplayConfig = {
            Health = 1200,
            BaseSpeed = 10.5,
            SprintSpeedMultiplier = 26 / 10.5,
            StaminaProperties = {
                MaxStamina = 110,
                StaminaDrain = 10.5,
                StaminaGain = 21,
            },

            Abilities = {},
            Cache = {
                Animations = {},
            },
        },

        OnInit = nil,
        OnHit = nil,
        OnExecution = nil,
    }
end

--- Creates a killer with the settings specified in `Props`.
--- 
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function CharTypes.CreateKiller(Props: Killer): Killer
    Props = Props or {}
    local Final = CharTypes.GetDefaultKillerSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

--- Creates a skin of a character with the settings specified in `Props`.
--- 
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function CharTypes.CreateSkin<T>(Type: "Killer" | "Survivor", CharacterName: string, Props: T & (Killer | Survivor)): T & (Killer | Survivor)
    local RootCharacter = Utils.Instance.GetCharacterModule(Type, CharacterName)
    if not RootCharacter then
        return
    end

    Props = Props or {}

    local Final: T & (Survivor | Killer) = Utils.Type.CopyTable(require(RootCharacter))
    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

return CharTypes
