local EffectType = {}

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

--- Effect preset for customization.
function EffectType:GetDefaultEffect(): Effect
    return {
        Name = "Effect",
        Description = "Does something",
        Duration = 1,
        Level = 1,

        Apply = function(own: Effect, level: number?, char: Model, duration: number)
            own.Level = level or own.Level
            own:ApplyEffect(level or own.Level, char, duration)
        end,
        Remove = function(own: Effect, char: Model)
            own:RemoveEffect(char)
        end,

        ApplyEffect = function(_own: Effect, _level: number?, _char: Model, _duration: number) end,
        RemoveEffect = function(_own: Effect) end,

        TimeLeft = 1,
        ShowInGUI = true,
    }
end

return EffectType
