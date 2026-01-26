local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UIManager = require(script.Parent)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        --get the prefab
        local UIPrefab = Utils.Instance.AwaitChild(script, "PlayerVitals")
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(Character: Model, CharacterJanitor: Types.Janitor)
            --if the character is a spectator, halt
            if not Character:GetAttribute("Role") or Character:GetAttribute("Role") == "Spectator" then
                return
            end

            --clone the prefab over to the ui
            local UI = UIPrefab:Clone()
            UI.Parent = UIManager.FetchScreenGui("PlayerVitals")

            --destroy ui when the character is destroyed
            CharacterJanitor:Add(UI, "Destroy")

            --get the humanoid for health stuff
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

            --getting containers for ui elements
            local HealthContainer = UI.Health
            local StaminaContainer = UI.Stamina

            --bar variables
            local HealthBar = HealthContainer.BarBackground.Bar
            local StaminaBar = StaminaContainer.BarBackground.Bar
            --adding a per-frame connection for updating the lerps
            CharacterJanitor:Add(RunService.PreRender:Connect(function(delta: number)
                --if there's no ui, halt
                if not UI then
                    return
                end

                --update sizes depending on health and stamina, max and current amounts
                HealthBar.Size = UDim2.fromScale(math.lerp(HealthBar.Size.X.Scale, Humanoid.Health / Humanoid.MaxHealth, delta * 9), 1)
                StaminaBar.Size = UDim2.fromScale(math.lerp(StaminaBar.Size.X.Scale, Character:GetAttribute("Stamina") / Character:GetAttribute("MaxStamina"), delta * 9), 1)
            end))

            --health text
            local HealthText = HealthContainer.TextLabel
            --health text update through rounding
            local function UpdateHealth()
                HealthText.Text = tostring(math.round(Humanoid.Health)).."/"..tostring(math.round(Humanoid.MaxHealth))
            end
            --add to janitor and execute just in case
            CharacterJanitor:Add(Humanoid:GetPropertyChangedSignal("Health"):Connect(UpdateHealth))
            UpdateHealth()

            --stamina text
            local StaminaText = StaminaContainer.TextLabel
            --stamina text update through rounding in absolute numbers
            local function UpdateStamina()
                StaminaText.Text = tostring(math.abs(math.round(Character:GetAttribute("Stamina")))).."/"..tostring(math.round(Character:GetAttribute("MaxStamina")))
            end
            --add to janitor through both stamina and max stamina and execute just in case
            CharacterJanitor:Add(Character:GetAttributeChangedSignal("Stamina"):Connect(UpdateStamina))
            CharacterJanitor:Add(Character:GetAttributeChangedSignal("MaxStamina"):Connect(UpdateStamina))
            UpdateStamina()
        end)
    end,
}
