local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
local HitmarkerCreator = require(ReplicatedStorage.Utils.HitmarkerCreator)
return function()
	Network:SetConnection("DisplayHitmarker", "REMOTE_EVENT", function(position: Vector3, amount: number)
		HitmarkerCreator:ShowHitmarker(position, amount)
	end)
end