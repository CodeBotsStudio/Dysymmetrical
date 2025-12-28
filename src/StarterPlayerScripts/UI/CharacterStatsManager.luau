--!nocheck

local CharacterStatsManager = {
    UI = nil,
    Connection = nil,
}

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)

function CharacterStatsManager:Init()
    local UIPrefab = Utils.Instance.FindFirstChild(script, "Stats")
    
    Utils.Character.ObserveCharacter(LocalPlayer, function(char: Model)
        self:_InitUI(char, UIPrefab:Clone())
    end)
end

function CharacterStatsManager:_InitUI(Char: Model, UI: Frame)
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.UI then
        self.UI:Destroy()
    end

    if Char:FindFirstChild("Role").Value == "Spectator" then return end

    self.UI = UI
    UI.Parent = LocalPlayer.PlayerGui.PlayerStats
    
    local Stamina = UI.Stamina
    local StaminaText = Stamina.TextLabel
    local StaminaBar = Stamina.BarBackground.Bar
    
    local Health = UI.Health
    local HealthText = Health.TextLabel
    local HealthBar = Health.BarBackground.Bar
    
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")
    local StaminaAttributes = {
    	Stamina = Char.PlayerAttributes.Stamina,
    	MaxStamina = Char.PlayerAttributes.MaxStamina
    }

    self.Connection = RunService.PreRender:Connect(function(delta: number)
        if not self.UI then
            self.Connection:Disconnect()
            return
        end
        
	    HealthBar.Size = UDim2.fromScale(Utils.Math.Lerp(HealthBar.Size.X.Scale, Humanoid.Health / Humanoid.MaxHealth, delta * 9), 1)
	    --
	    StaminaBar.Size = UDim2.fromScale(Utils.Math.Lerp(StaminaBar.Size.X.Scale, StaminaAttributes.Stamina.Value / StaminaAttributes.MaxStamina.Value, delta * 9), 1)
    end)

    Utils.Instance.ObserveProperty(Humanoid, "Health", function(value: number)
        HealthText.Text = tostring(math.round(Humanoid.Health)).."/"..tostring(Humanoid.MaxHealth)
    end)

    local function UpdateStaminaText()
        StaminaText.Text = tostring(math.abs(math.round(StaminaAttributes.Stamina.Value))).."/"..tostring(StaminaAttributes.MaxStamina.Value)
    end
    Utils.Instance.ObserveProperty(StaminaAttributes.Stamina, "Value", UpdateStaminaText)
    Utils.Instance.ObserveProperty(StaminaAttributes.MaxStamina, "Value", UpdateStaminaText)
end

return CharacterStatsManager
