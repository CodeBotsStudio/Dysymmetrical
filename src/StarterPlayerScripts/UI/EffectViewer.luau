--!nocheck

local EffectViewer = {}

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local EffectDisplay: Frame

function EffectViewer:Init()
    EffectDisplay = Utils:FindFirstChild(script, "EffectDisplay")
    local UIPrefab = Utils:FindFirstChild(script, "StatusContainer")

    LocalPlayer.CharacterAdded:Connect(function(Char: Model)
        self:_SetupUI(UIPrefab:Clone(), Char)
    end)
end

function EffectViewer:_SetupUI(UI: Frame, char: Model)
    if Utils:FindFirstChild(char, "Role").Value == "Spectator" then
        UI:Destroy()
        return
    end

    UI.Parent = LocalPlayer.PlayerGui.Effects

    local EffectManager = require(char.PlayerAttributeScripts.EffectManager)
    
    local Connection: RBXScriptConnection = RunService.PreRender:Connect(function()
        local Effects: {} = EffectManager.Effects
	
	    for name, effect in Effects do
	    	if not effect.ShowInGUI then continue end
	    	local Display = UI:FindFirstChild(name)
	    	if not Display then
	    		Display = EffectDisplay:Clone()
	    		Display.Name = name
	    		Display.Title.Text = effect.Name
                if effect.Level > 1 then
                    local RomanLevel = Utils:IntToRoman(effect.Level)
                    Display.Title.Text = Display.Title.Text.." "..RomanLevel
                end
	    		Display.Parent = UI
	    	end
	    	Display.Timer.Text = Utils:ConvertToMinSec(effect.TimeLeft + 1)
	    end
    
	    for _, display in UI:GetChildren() do
	    	if display:IsA("Frame") and not Effects[display.Name] then
	    		display:Destroy()
	    	end
	    end
    end)

    UI.Destroying:Connect(function()
        Connection:Disconnect()
    end)
end

return EffectViewer
