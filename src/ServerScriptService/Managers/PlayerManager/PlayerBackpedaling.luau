local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSpeedManager = require(script.Parent.PlayerSpeedManager)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local FactorName = "Backpedaling"
local SpeedMult = 0.75

return {
    Init = function(_)
        Utils.Player.ObservePlayers(function(Player: Player)
            Utils.Character.ObserveCharacter(Player, function(Character: Model, CharacterJanitor: Types.Janitor)
                local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
                local HumanoidRootPart = Utils.Character.GetRootPart(Character)

                PlayerSpeedManager.AddSpeedFactor(Player, FactorName, 1)

                Utils.Instance.ObserveProperty(Humanoid, "MoveDirection", function(value: Vector3)
                    PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName] = HumanoidRootPart.CFrame:VectorToObjectSpace(value).Z > 0.1 and SpeedMult or 1
                end)
            end)
        end)
    end,
}