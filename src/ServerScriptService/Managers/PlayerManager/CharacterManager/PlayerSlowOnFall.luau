local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Types = require(ReplicatedStorage.Classes.Types)
local PlayerSpeedManager = require(script.Parent.PlayerSpeedManager)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils.Player.ObservePlayers(function(Player: Player)
            Utils.Character.ObserveHumanoid(Player, function(Humanoid: Humanoid, HumanoidJanitor: Types.Janitor)
                local Character: Model = Humanoid.Parent
                --if the character isn't a survivor, halt
                if Character:GetAttribute("Role") ~= "Survivor" then
                    return
                end

                local HRP = Utils.Character.GetRootPart(Character)
                local thread
                HumanoidJanitor:Add(Humanoid.StateChanged:Connect(function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
                    --the humanoid must've landed
                    if new ~= Enum.HumanoidStateType.Landed then
                        return
                    end

                    --don't apply another slow on fall if there is already one happening (will try to rework this in the future)
                    if thread then
                        return
                    end
                    
                    --getting fall speed
                    local Vel = math.abs(HRP.AssemblyLinearVelocity.Y)
                    --crazy calculations
                    local Mult = 40 / Vel / 1.5
                    local Recovery = Vel / 40 * 0.25
                    --add the speed factor
                    PlayerSpeedManager.AddFactor(Player, "FallSlowness", Mult)
                    --thread thing
                    thread = task.defer(function()
                        local elapsed = 0
                        local alpha = 0
                        --tweening the value to 1
                        repeat
                            alpha = math.clamp(elapsed / Recovery, 0, 1)
                            PlayerSpeedManager.ManagedPlayers[Player].Factors.FallSlowness = math.lerp(Mult, 1, TweenService:GetValue(alpha, Enum.EasingStyle.Circular, Enum.EasingDirection.In))
                            elapsed += task.wait()
                        until alpha == 1 or not Humanoid or not PlayerSpeedManager.ManagedPlayers[Player].Factors.FallSlowness
                        --remove the factor
                        PlayerSpeedManager.RemoveFactor(Player, "FallSlowness")
                    end)
                end))
            end)
        end)
    end,
}