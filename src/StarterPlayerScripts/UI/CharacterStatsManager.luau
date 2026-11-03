local CharacterStatsManager = {
    UI = nil,
    Connection = nil,
}

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
local InkFX = require(ReplicatedStorage.Modules.InkFX)

function CharacterStatsManager:Init()
    local UIPrefab = Utils.Instance.FindFirstChild(script, "Stats")
    
    Utils.Character.ObserveCharacter(LocalPlayer, function(char: Model)
        CharacterStatsManager._InitUI(char, UIPrefab:Clone())
    end)
end

function CharacterStatsManager._InitUI(Char: Model, UI: Frame)
    if CharacterStatsManager.Connection then
        CharacterStatsManager.Connection:Disconnect()
    end
    if CharacterStatsManager.UI then
        CharacterStatsManager.UI:Destroy()
    end

    if Char:FindFirstChild("Role").Value == "Spectator" then return end

    CharacterStatsManager.UI = UI
    UI.Parent = LocalPlayer.PlayerGui:WaitForChild("PlayerStats")
    
    local Stamina = UI.Stamina
    local StaminaText = Stamina.TextLabel
    local StaminaBar = Stamina.BarBackground.Bar
    
    local Health = UI.Health
    local HealthText = Health.TextLabel
    local HealthBar = Health.BarBackground.Bar
    local HealthTrail = HealthBar:Clone()
    HealthTrail.Name = "Trail"
    HealthTrail.BackgroundColor3 = Color3.fromRGB(236, 228, 210)
    HealthTrail.ZIndex = HealthBar.ZIndex
    HealthBar.ZIndex += 1
    HealthTrail.Parent = Health.BarBackground
    
    local Humanoid = Char:FindFirstChildWhichIsA("Humanoid")
    local StaminaAttributes = {
    	Stamina = Char.PlayerAttributes.Stamina,
    	MaxStamina = Char.PlayerAttributes.MaxStamina
    }

    CharacterStatsManager.Connection = RunService.PreRender:Connect(function(delta: number)
        if not CharacterStatsManager.UI then
            CharacterStatsManager.Connection:Disconnect()
            return
        end
        
        local HealthRatio = Humanoid.Health / Humanoid.MaxHealth
	    HealthBar.Size = UDim2.fromScale(math.lerp(HealthBar.Size.X.Scale, HealthRatio, delta * 9), 1)
        HealthTrail.Size = UDim2.fromScale(math.max(HealthRatio, math.lerp(HealthTrail.Size.X.Scale, HealthRatio, delta * 1.6)), 1)
	    --
        local StaminaRatio = StaminaAttributes.Stamina.Value / StaminaAttributes.MaxStamina.Value
	    StaminaBar.Size = UDim2.fromScale(math.lerp(StaminaBar.Size.X.Scale, StaminaRatio, delta * 9), 1)
        StaminaBar.BackgroundTransparency = if StaminaRatio < 0.25 and not InkFX.Calm() then 0.35 + 0.35 * math.sin(os.clock() * 9) else 0
    end)

    local LastHealth = Humanoid.Health
    Utils.Instance.ObserveProperty(Humanoid, "Health", function(value: number)
        if value < LastHealth - 0.5 then
            InkFX.Pop(HealthText, 1.35, 0.45)
            InkFX.Ripple(HealthText, 1.8, 0.6)
        elseif value > LastHealth + 0.5 then
            InkFX.Pop(HealthText, 1.15, 0.4)
        end
        LastHealth = value
        HealthText.Text = tostring(math.round(Humanoid.Health)).."/"..tostring(Humanoid.MaxHealth)
    end)

    local function UpdateStaminaText()
        StaminaText.Text = tostring(math.abs(math.round(StaminaAttributes.Stamina.Value))).."/"..tostring(StaminaAttributes.MaxStamina.Value)
    end
    Utils.Instance.ObserveProperty(StaminaAttributes.Stamina, "Value", UpdateStaminaText)
    Utils.Instance.ObserveProperty(StaminaAttributes.MaxStamina, "Value", UpdateStaminaText)
end

return CharacterStatsManager
