local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)

local Folder = ReplicatedStorage.LoadedPlayers

return function()
	Network:SetConnection("AddLoadedPlayer", "REMOTE_EVENT", function(plr: Player)
		if not Folder:FindFirstChild(plr.Name) then
			local Value = Instance.new("ObjectValue")
			Value.Name = plr.Name
			Value.Value = plr
			Value.Parent = Folder
		end
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		if Folder:FindFirstChild(plr.Name) then
			Folder:FindFirstChild(plr.Name):Destroy()
		end
	end)
end