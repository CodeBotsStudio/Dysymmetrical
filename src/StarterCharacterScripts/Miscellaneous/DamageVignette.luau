local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        local Vignette = Utils:FindFirstChild(script, "DamageVignette")
        Vignette.Parent = Utils:FindFirstChild(Players.LocalPlayer.PlayerGui, "TemporaryUI")

        local Humanoid = Utils:FindFirstChild(Players.LocalPlayer.Character, "Humanoid")

        RunService.PreRender:Connect(function(delta: number)
            local Target = Humanoid.Health < Humanoid.MaxHealth * 0.45 and 
                math.clamp(
                    Humanoid.Health / Humanoid.MaxHealth / 2 + 0.65,
                    0.5,
                    0.999
                ) or 0.999
            Vignette.ImageTransparency = Utils:Lerp(
                Vignette.ImageTransparency,
                Target,
                delta * 9.8
            )
        end)

        --heartbeat
        task.spawn(function()
            while true do
                if Humanoid.Health <= 0 or Humanoid.Health >= Humanoid.MaxHealth * 0.45 then
                    task.wait(0.05)
                    continue
                end

                local WaitTime = 0.15 + Humanoid.Health / Humanoid.MaxHealth / 2

                Vignette.ImageTransparency *= 0.8
                task.wait(WaitTime)
                Vignette.ImageTransparency *= 0.8
                task.wait(WaitTime * 2)
            end
        end)
    end,
}