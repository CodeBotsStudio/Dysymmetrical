--!nocheck

local Effect = require(game:GetService("ReplicatedStorage").Classes.Effect)

local DominoEffect: Effect.Effect = Effect:GetDefaultEffect()

DominoEffect.Name = "Domino Effect"
DominoEffect.Description = "If hit by the killer, it receives a splash of ink in its screen for 4 seconds"
DominoEffect.ShowInGUI = true
DominoEffect.Duration = 3.5
DominoEffect.Attacks = {
    "Slash Attack",
}
DominoEffect.Splatter = script.DominoEffectSplatter

return DominoEffect
