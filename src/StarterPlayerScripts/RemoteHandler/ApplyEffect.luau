--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Network = require(ReplicatedStorage.Modules.Network)

return function()
	local EffectFolder = ReplicatedStorage.Effects
	
	Network:SetConnection("ApplyEffect", "REMOTE_EVENT", function(effect: string, level: number?, duration: number?, subfolder: string?)
		level = level or 1
		
		local Effect: ModuleScript
		if subfolder and #subfolder > 0 then
			Effect = EffectFolder:FindFirstChild(subfolder):FindFirstChild(effect)
		else
			Effect = EffectFolder:FindFirstChild(effect)
		end
		
		if not Effect then return end

		local EffectCode = require(Effect)
		require(LocalPlayer.Character.PlayerAttributeScripts.EffectManager):AddEffect(EffectCode, level, duration)
	end)
end