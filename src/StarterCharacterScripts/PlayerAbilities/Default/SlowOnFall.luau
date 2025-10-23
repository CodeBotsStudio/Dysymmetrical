local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        local char = script.Parent.Parent.Parent
        local role = Utils:FindFirstChild(char, "Role")

        local thr = {}

        task.wait(1)

        if role.Value == "Survivor" then
            local HRP = char.HumanoidRootPart
            local SpeedManager = require(char.PlayerAttributeScripts.SpeedManager)
            char.Humanoid.StateChanged:Connect(function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
                if new == Enum.HumanoidStateType.Landed then
                    for _, i in thr do
                        task.cancel(i)
                    end
                    local Vel = math.abs(HRP.AssemblyLinearVelocity.Y)
                    local Mult = 40 / Vel / 1.5
                    local Recovery = Vel / 40 * 0.25
                    SpeedManager:AddSpeedFactor("FallSlowness", Mult)
                    thr["twn"] = task.defer(function()
                        local elapsed = 0
                        repeat
                           local alpha = math.clamp(elapsed / Recovery, 0, 1)
                           SpeedManager.SpeedFactors["FallSlowness"] = Utils:Lerp(Mult, 1, TweenService:GetValue(alpha, Enum.EasingStyle.Circular, Enum.EasingDirection.In))
                           elapsed += task.wait()
                        until alpha == 1 or not SpeedManager.SpeedFactors["FallSlowness"]
                    end)
                    thr["rmv"] = task.delay(Recovery + 0.1, function()
                        SpeedManager:RemoveSpeedFactor("FallSlowness")
                    end)
                end
            end)
        end
    end
}