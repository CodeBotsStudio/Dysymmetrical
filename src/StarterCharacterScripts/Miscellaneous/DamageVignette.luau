local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

return {
    Init = function(_self)
        local Vignette = Utils.Instance.FindFirstChild(script, "DamageVignette"):Clone()
        Vignette.Parent = Utils.Instance.FindFirstChild(Players.LocalPlayer.PlayerGui, "TemporaryUI")

        local Humanoid = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")

        local JanitorInstance = Janitor.new()
        JanitorInstance:LinkToInstance(Humanoid)

        JanitorInstance:Add(RunService.PreRender:Connect(function(delta: number)
            local Target = Humanoid.Health < Humanoid.MaxHealth * 0.45 and 
                math.clamp(
                    Humanoid.Health / Humanoid.MaxHealth / 2 + 0.65,
                    0.5,
                    0.999
                ) or 0.999
            Vignette.ImageTransparency = Utils.Math.Lerp(
                Vignette.ImageTransparency,
                Target,
                delta * 9.8
            )
        end))

        --heartbeat
        JanitorInstance:Add(task.defer(function()
            while not JanitorInstance.CurrentlyCleaning and Humanoid and Humanoid.Parent do
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
        end))

        JanitorInstance:Add(function()
            if Vignette then
                Vignette:Destroy()
            end
        end, true)
    end,
}