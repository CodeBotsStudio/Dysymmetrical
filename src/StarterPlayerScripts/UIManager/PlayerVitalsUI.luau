local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UIManager = require(script.Parent)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        local UIPrefab = Utils.Instance.AwaitChild(script, "PlayerVitals")
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(Character: Model, CharacterJanitor: Types.Janitor)
            if not Character:GetAttribute("Role") or Character:GetAttribute("Role") == "Spectator" then
                return
            end

            local UI = UIPrefab:Clone()
            UI.Parent = UIManager.FetchScreenGui("PlayerVitals")

            CharacterJanitor:Add(UI, "Destroy")

            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

            local HealthContainer = UI.Health
            local StaminaContainer = UI.Stamina

            local HealthBar = HealthContainer.BarBackground.Bar
            local StaminaBar = StaminaContainer.BarBackground.Bar
            CharacterJanitor:Add(RunService.PreRender:Connect(function(delta: number)
                if not UI then
                    return
                end

                HealthBar.Size = UDim2.fromScale(math.lerp(HealthBar.Size.X.Scale, Humanoid.Health / Humanoid.MaxHealth, delta * 9), 1)
                StaminaBar.Size = UDim2.fromScale(math.lerp(StaminaBar.Size.X.Scale, Character:GetAttribute("Stamina") / Character:GetAttribute("MaxStamina"), delta * 9), 1)
            end))

            local HealthText = HealthContainer.TextLabel
            local function UpdateHealth()
                HealthText.Text = tostring(math.round(Humanoid.Health)).."/"..tostring(Humanoid.MaxHealth)
            end
            CharacterJanitor:Add(Humanoid:GetPropertyChangedSignal("Health"):Connect(UpdateHealth))

            local StaminaText = StaminaContainer.TextLabel
            local function UpdateStamina()
                StaminaText.Text = tostring(math.abs(math.round(Character:GetAttribute("Stamina")))).."/"..tostring(Character:GetAttribute("MaxStamina"))
            end
            CharacterJanitor:Add(Character:GetAttributeChangedSignal("Stamina"):Connect(UpdateStamina))
            CharacterJanitor:Add(Character:GetAttributeChangedSignal("MaxStamina"):Connect(UpdateStamina))
            UpdateStamina()
        end)
    end,
}
