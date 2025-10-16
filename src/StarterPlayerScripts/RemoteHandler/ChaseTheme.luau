local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)
local TerrorRadius = require(ReplicatedStorage.Utils.TerrorRadius)

return function()
	local CurrentRadius

	Network:SetConnection("ChaseTheme", "REMOTE_EVENT", function(killerName: string, killerSkin: string, KillerCharacter: Model)
		if CurrentRadius ~= nil then
			CurrentRadius:Delete()
			CurrentRadius = nil
			return
		end
		
		if not killerName then
			return
		end

		-- CurrentRadius = TerrorRadius.New(require(CommonUtils:GetCharacterModule("Killer", killerName, killerSkin)).Config.ChaseThemes, KillerCharacter)
	end)
end