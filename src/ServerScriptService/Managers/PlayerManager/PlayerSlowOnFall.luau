local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PlayerSpeedManager = require(script.Parent.PlayerSpeedManager)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils.Player.ObservePlayers(function(Player: Player)
            Utils.Character.ObserveCharacter(Player, function(Character: Model)
                local Role = Character:FindFirstChild("Role")
                if Role.Value ~= "Survivor" then
                    return
                end

                PlayerSpeedManager.AddSpeedFactor(Player, "FallSlowness", 1)

                local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
                local HRP = Utils.Character.GetRootPart(Character)
                local thread
                Humanoid.StateChanged:Connect(function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
                    if new == Enum.HumanoidStateType.Landed then
                        if thread then
                            return
                        end
                        local Vel = math.abs(HRP.AssemblyLinearVelocity.Y)
                        local Mult = 40 / Vel / 1.5
                        local Recovery = Vel / 40 * 0.25
                        PlayerSpeedManager.ManagedPlayers[Player].Factors.FallSlowness = Mult
                        thread = task.defer(function()
                            local elapsed = 0
                            local alpha = 0
                            repeat
                                alpha = math.clamp(elapsed / Recovery, 0, 1)
                                PlayerSpeedManager.ManagedPlayers[Player].Factors.FallSlowness = math.lerp(Mult, 1, TweenService:GetValue(alpha, Enum.EasingStyle.Circular, Enum.EasingDirection.In))
                                elapsed += task.wait()
                            until alpha == 1 or not PlayerSpeedManager.ManagedPlayers[Player].Factors.FallSlowness
                        end)
                    end
                end)
            end)
        end)
    end,
}