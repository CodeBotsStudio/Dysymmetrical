local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        local Humanoid = Utils:FindFirstChild(Players.LocalPlayer.Character, "Humanoid")
        local DesaturationSetting = Utils:FindFirstChild(Players.LocalPlayer, "PlayerData.Settings.Customization.ScreenDesaturation")

        local Desat = Instance.new("ColorCorrectionEffect")
        Desat.Name = "HealthDesat"
        Desat.Saturation = 0
        Desat.Parent = Lighting

        local function GetExistingDesat(): number
            local Amount = 0

            for _, i in Lighting:GetChildren() do
                if i:IsA("ColorCorrectionEffect") and i.Name ~= "HealthDesat" and not i:GetAttribute("IgnoredByHealthDesat") then
                    Amount += i.Saturation
                end
            end

            return Amount
        end
        local function Update()
            local Magnitude = Humanoid.Health / Humanoid.MaxHealth
            local Base = GetExistingDesat()
            local Mult = math.min(0, -1 - Base)
            if Magnitude <= 0.5 and DesaturationSetting.Value then
                Desat.Saturation = Mult * (1 - Magnitude * 2)
            else
                Desat.Saturation = 0
            end
        end

        Humanoid:GetPropertyChangedSignal("Health"):Connect(Update)
        Update()
    end,
}