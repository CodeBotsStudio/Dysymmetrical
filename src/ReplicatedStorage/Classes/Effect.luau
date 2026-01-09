local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local EffectType = {}

--- Effect preset for customization.
function EffectType.GetDefaultSettings(): Types.Effect
    return {
        Name = "Effect",
        Description = "Does something",
        Duration = 1,
        Level = 1,

        Apply = function(own: Types.Effect, level: number?, char: Model, duration: number)
            own.Level = level or own.Level
            own:ApplyEffect(level or own.Level, char, duration)
        end,
        Remove = function(own: Types.Effect, char: Model)
            own:RemoveEffect(char)
        end,

        ApplyEffect = function(_own: Types.Effect, _level: number?, _char: Model, _duration: number) end,
        RemoveEffect = function(_own: Types.Effect) end,

        TimeLeft = 1,
        ShowInGUI = true,
    }
end

--- ## DEPRECATED: use `Effect.GetDefaultSettings()` instead.
--- Effect preset for customization.
@deprecated
function EffectType.GetDefaultEffect(): Types.Effect
    return EffectType.GetDefaultSettings()
end

--- Creates an effect with the settings specified in `Props`.
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function EffectType.New(Props: Types.Effect): Types.Effect
    Props = Props or {}
    local Final = EffectType.GetDefaultSettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

--- ## DEPRECATED: use `Effect.New()` instead.
--- Creates an effect with the settings specified in `Props`.
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
@deprecated
function EffectType.CreateEffect(Props: Types.Effect): Types.Effect
    return EffectType.New(Props)
end

return EffectType
