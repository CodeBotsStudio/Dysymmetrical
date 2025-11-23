--!nocheck

local CharacterStatsManager = {}

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)

function CharacterStatsManager:Init()
    local UIPrefab = Utils:FindFirstChild(script, "Stats")
    
    LocalPlayer.CharacterAdded:Connect(function()
        self:_InitUI(UIPrefab:Clone())
    end)
end

function CharacterStatsManager:_InitUI(UI: Frame)
    if not LocalPlayer.Character or Utils:FindFirstChild(LocalPlayer.Character, "Role").Value == "Spectator" then return end
    local Char = LocalPlayer.Character

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

    local Connection: RBXScriptConnection
    Connection = RunService.PreRender:Connect(function(delta: number)
        if not Char then
	    	UI.Visible = false
	    	Connection:Disconnect()
	    	return
	    end

        HealthText.Text = tostring(math.round(Humanoid.Health)).."/"..tostring(Humanoid.MaxHealth)
	    HealthBar.Size = UDim2.fromScale(Utils:Lerp(HealthBar.Size.X.Scale, Humanoid.Health / Humanoid.MaxHealth, delta * 9), 1)
	    --
	    StaminaText.Text = tostring(math.abs(math.round(StaminaAttributes.Stamina.Value))).."/"..tostring(StaminaAttributes.MaxStamina.Value)
	    StaminaBar.Size = UDim2.fromScale(Utils:Lerp(StaminaBar.Size.X.Scale, StaminaAttributes.Stamina.Value / StaminaAttributes.MaxStamina.Value, delta * 9), 1)
    end)
end

return CharacterStatsManager
