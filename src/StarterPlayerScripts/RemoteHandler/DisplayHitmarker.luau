local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)

local Hitmarker = require(ReplicatedStorage.Classes.Hitmarker)

return function()
	Network:SetConnection("DisplayHitmarker", "REMOTE_EVENT", function(position: Vector3, amount: number)
		Hitmarker.new(position, amount)
	end)
end