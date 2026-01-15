local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(Character: Model)
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
            local DesaturationSetting = Utils.Instance.FindFirstChild(Players.LocalPlayer, "PlayerData.Settings.Customization.ScreenDesaturation")

            local Desat = Instance.new("ColorCorrectionEffect")
            Desat.Name = "HealthDesat"
            Desat.Saturation = 0
            Desat.Parent = Lighting

            local function GetExistingDesat(): number
                local Amount = 0

                for _, FX in Lighting:GetChildren() do
                    if FX:IsA("ColorCorrectionEffect") and FX.Name ~= "HealthDesat" and not FX:GetAttribute("IgnoredByHealthDesat") then
                        Amount += FX.Saturation
                    end
                end

                return Amount
            end
            local function Update(value: number)
                print(value)
                local Magnitude = Humanoid.Health / Humanoid.MaxHealth
                local Base = GetExistingDesat()
                local Mult = math.min(0, -1 - Base)
                if Magnitude <= 0.5 and DesaturationSetting.Value then
                    Desat.Saturation = Mult * (1 - Magnitude * 2)
                else
                    Desat.Saturation = 0
                end
            end

            Utils.Instance.ObserveProperty(Humanoid, "Health", Update)
            Update(Humanoid.Health)
        end)
    end,
}