local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSpeedManager = require(script.Parent.PlayerSpeedManager)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local FactorName = "Backpedaling"
local SpeedMult = 0.75

return {
    Init = function(_)
        Utils.Player.ObservePlayers(function(Player: Player)
            Utils.Character.ObserveHumanoid(Player, function(Humanoid: Humanoid, HumanoidJanitor: Types.Janitor)
                local HumanoidRootPart = Utils.Character.GetRootPart(Humanoid.Parent)

                --initially set a speed factor
                PlayerSpeedManager.AddFactor(Player, FactorName, 1)

                --check when the move direction for the humanoid changes
                Utils.Instance.ObserveProperty(Humanoid, "MoveDirection", function(value: Vector3)
                    --compare the direction relative to the hrp's rotation and, if it's backwards, make the factor lower
                    --if it's not backwards, leave it in 1 to nullify the backpedaling speed factor
                    PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName] = HumanoidRootPart.CFrame:VectorToObjectSpace(value).Z > 0.1 and SpeedMult or 1
                end)
            end)
        end)
    end,
}