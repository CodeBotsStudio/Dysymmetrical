local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Types = require(script.Parent.Types)

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

--- Survivor preset for customization.
function CharTypes.GetDefaultSurvivorSettings(): Types.Survivor
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
            HitboxPriority = 1,
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
function CharTypes.CreateSurvivor(Props: Types.Survivor): Types.Survivor
    Props = Props or {}
    local Final = CharTypes.GetDefaultSurvivorSettings()

    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

--- Killer preset for customization.
function CharTypes.GetDefaultKillerSettings(): Types.Killer
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
			HitboxPriority = 1,
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
function CharTypes.CreateKiller(Props: Types.Killer): Types.Killer
    Props = Props or {}
    local Final = CharTypes.GetDefaultKillerSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

--- Creates a skin of a character with the settings specified in `Props`.
--- 
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function CharTypes.CreateSkin<T>(Type: "Killer" | "Survivor", CharacterName: string, Props: T & (Types.Killer | Types.Survivor)): T & (Types.Killer | Types.Survivor)
    local RootCharacter = Utils.Instance.GetCharacterModule(Type, CharacterName)
    if not RootCharacter then
        return
    end

    Props = Props or {}

    local Final: T & (Types.Survivor | Types.Killer) = Utils.Type.CopyTable(require(RootCharacter))
    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

return CharTypes
