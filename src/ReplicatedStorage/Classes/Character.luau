--!nocheck
local KillerIntro = require(script.Parent.KillerIntro)
local CharTypes = {}

--- Type used for survivor characters.
export type Survivor = {
    --- The player that currently owns the character instance.
    Owner: Player,
    --- Config that shouldn't affect gameplay mechanics.
    Config: {
        --- The display name of the character.
        Name: string,
        --- The character's `More Info` page content.
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
            --- TODO: The animation that'll play on stun.
            Stunned: string?,
            --- TODO: The animation that'll play before a stun ends.
            StunnedEnd: string?,
        },

        --- Any voicelines this character might have. It's built with strings as keys, and either strings, string tables or string dictionaries as values for random voicelines.
        --- * You can also name voicelines after abilities' code names (the ones that you define them with) so that they play when those abilities are used.
        --- * For example, if I have an ability named `TestAbility` in code and I add a `TestAbility` field here, it'll play a voiceline from here when I use it.
        Voicelines: {
            --- The voiceline (s) that'll play at random times while the character isn't saying any other voiceline.
            Idle: (string | {string} | {[string]: string | {string}})?,
            --- The voiceline (s) that'll play when LMS starts.
            --- If there's any character that you want this character to have a custom voiceline for, add its codename here.
            --- * If there's a specific skin, add the skin's codename at the beginning and *then* add the character's codename (e.g. `[SkinName][CharacterName]`, without spaces).
            LMS: {
                --- The default voiceline (s).
                Default: string | {string} | {[string]: string | {string}},
                [string]: string | {string} | {[string]: string | {string}},
            }?,
            --- The voiceline (s) that'll play when the character gets stunned. Yes, you can do this with survivors.
            Stunned: (string | {string} | {[string]: string | {string}})?,

            [string]: string | {string} | {[string]: string | {string}},
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
        Cache: {any},
    },

    --- An empty function that you can replace to execute custom behaviour when this character initializes.
    OnInit: (self: Survivor, charModel: Model) -> ()?,
    --- SERVER FUNCTION: An empty function that you can replace to execute custom behaviour when this character gets hit.
    --- * If you want the character to not get affected by the hit, you can return `"Ignored"`.
    OnHit: (self: Survivor, hitbox: any, damage: number) -> (string?)?,
}

--- Survivor preset for customization.
function CharTypes:GetDefaultSurvivorSettings(): Survivor
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
            Render = "rbxassetid://18831151594",

            AnimationIDs = {
                IdleAnimation = "rbxassetid://128254839975087",
                WalkAnimation = "rbxassetid://95139037304316",
                RunAnimation = "rbxassetid://84289923509689",
            },

            Voicelines = {},
        },

        GameplayConfig = {
            Health = 100,
            BaseSpeed = 10.5,
            SprintSpeedMultiplier = 2.66666,
            StaminaProperties = {
                MaxStamina = 100,
                StaminaDrain = 10,
                StaminaGain = 30,
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

--- Type used for killer characters.
export type Killer = {
    --- The player that currently owns the character instance.
    Owner: Player,
    --- Config that shouldn't affect gameplay mechanics.
    Config: {
        --- The display name of the character.
        Name: string,
        --- The character's `More Info` page content.
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

        --- The price of this character in the shop.
        Price: number,
        --- The render image / portrait ID of this character.
        Render: string?,

        --- A possible custom LMS theme the character might have.
        LastManStandingTheme: string?,
        SpecialLastManStandings: {[string]: {
            Default: string,
            [string]: string,
        }}?,

        --- All AnimationIDs related to this character.
        AnimationIDs: {
            --- The animation that'll play on an idle state.
            IdleAnimation: string,
            --- The animation that'll play on a walking state.
            WalkAnimation: string,
            --- The animation that'll play on a running state.
            RunAnimation: string,
            --- TODO: The animation that'll play on stun.
            Stunned: string?,
            --- TODO: The animation that'll play before a stun ends.
            StunnedEnd: string?,
            --- The animation that'll play when slashing.
            SlashAnimation: string?,
            --- The animation that the killer will have in the intro animation.
            KillerRig: string?,
            --- The animation that the camera will have in the intro animation.
            CameraRig: string?,
            --- The animations that'll play when executing a player.
            --- Inside, make a `Default` for any survivor.
            --- You may make others with the `"[SkinName][CharacterName]"` format to add customs for skins and characters.
            --- Remove `[SkinName]` to make it for a survivor in general.
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

        --- Any voicelines this character might have. It's built with strings as keys, and either strings or string dictionaries as values for random voicelines.
        --- For killers, use `Kill` to set the kill voicelines.
        --- In it set a `Default` value for any survivor.
        --- You may set customs for skins and characters using `"[SkinName][CharacterName]"` format.
        --- Remove `[SkinName]` to make it for a survivor in general.
        Voicelines: {
            --- The voiceline (s) that'll play when this character kills a survivor.
            --- If there's any character that you want this character to have a custom voiceline for, add its codename here.
            --- * If there's a specific skin, add the skin's codename at the beginning and *then* add the character's codename (e.g. `[SkinName][CharacterName]`, without spaces).
            Kill: {
                --- The default voiceline (s).
                Default: (string | {string}),
                [string]: (string | {string}),
            }?,
            --- The voiceline (s) that'll play at random times while the character isn't saying any other voiceline.
            Idle: (string | {string} | {[string]: string | {string}})?,
            --- The voiceline (s) that'll play when LMS starts.
            --- If there's any character that you want this character to have a custom voiceline for, add its codename here.
            --- * If there's a specific skin, add the skin's codename at the beginning and *then* add the character's codename (e.g. `[SkinName][CharacterName]`, without spaces).
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

        --- CLIENT FUNCTION: Empty function to execute code when the killer intro initializes (loads its content).
        --- `KillerRig` and `CameraRig` will be `nil` when it's a 2D intro (`UiIntro`).
        OnIntroInit: (self: Killer, intro: KillerIntro.AnimatedIntro | KillerIntro.UiIntro, KillerRig: Model, CameraRig: Model) -> ()?,
        --- CLIENT FUNCTION: Empty function to execute code when the killer intro plays.
        --- `KillerRig` and `CameraRig` will be `nil` when it's a 2D intro (`UiIntro`).
        OnIntroPlay: (self: Killer, intro: KillerIntro.AnimatedIntro | KillerIntro.UiIntro, KillerRig: Model, CameraRig: Model, AnimDuration: number) -> ()?,

        --- Any SFX that you may want to play with the character.
        --- Voicelines go in `Voicelines`.
        Sounds: {
            --- The sound that'll play when the killer's intro plays.
            --- Can also be a table to play a random sound.
            IntroSound: (string | {string})?,
            --- The SFX of the Execution animations.
            --- Since animations may vary, it's possible to set custom sounds for each.*
            Execution: {
                Default: (string | {string}),
                [string]: (string | {string}),
            },
            [string]: (string | {string}),
        },

        --- The CFrame value that'll be added to a survivor's CFrame when snapping to a killer's CFrame by being executed by them. Defaults to `CFrame.new(0, 0, 5)` in `Hitbox`.
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

        --- The damage the slash'll do.
        SlashDamage: number,
        --- The cooldown the slash'll have.
        SlashCooldown: number,
        --- How long every slash's hitbox will last.
        SlashDuration: number,

        --- All of the initialized abilities the character has, counting the slash.
        Abilities: {any},
        --- Any temp objects or instances that might be created mid-match.
        Cache: {any},
    },

    --- An empty function that you can replace to execute custom behaviour when this character initializes.
    OnInit: (self: Killer, charModel: Model) -> ()?,
    --- SERVER FUNCTION: An empty function that you can replace to execute custom behaviour when this character gets hit.
    --- * If you want the character to not get affected by the hit, you can return `"Ignored"`.
    OnHit: (self: Survivor, hitbox: any, damage: number) -> (string?)?,
}

--- Killer preset for customization.
function CharTypes:GetDefaultKillerSettings(): Killer
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
            Render = "rbxassetid://18831151594",

            LastManStandingTheme = "rbxassetid://125799740823318",
            SpecialLastManStandings = {},

            AnimationIDs = {
                IdleAnimation = "rbxassetid://138818467051890",
                WalkAnimation = "rbxassetid://96779101755387",
                RunAnimation = "rbxassetid://139221510401164",
                SlashAnimation = "rbxassetid://133504250023139",
            },

            Voicelines = {},

            ChaseThemes = {
                L1 = "rbxassetid://101608255438688",
                L2 = "rbxassetid://122380833390973",
                L3 = "rbxassetid://78435073515542",
                L4 = "rbxassetid://100400124559989",
            },
        },

        GameplayConfig = {
            Health = 1200,
            BaseSpeed = 10.5,
            SprintSpeedMultiplier = 2.66666,
            StaminaProperties = {
                MaxStamina = 110,
                StaminaDrain = 8,
                StaminaGain = 32,
            },

            SlashDamage = 20,
            SlashCooldown = 2,
            SlashDuration = 0.4,

            Abilities = {},
            Cache = {
                Animations = {},
            },
        },

        OnInit = nil,
        OnHit = nil,
    }
end

return CharTypes
