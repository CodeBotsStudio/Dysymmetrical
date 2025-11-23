local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)

local Folder = ReplicatedStorage.LoadedPlayers

return function()
	Network:SetConnection("AddLoadedPlayer", "REMOTE_EVENT", function(plr: Player)
		if not Folder:FindFirstChild(plr.Name) then
			local Value = Instance.new("ObjectValue")
			Value.Name = plr.Name
			Value.Value = plr
			Value.Parent = Folder
		end

		task.wait(3)

		if plr then
			local Log = Utils:FindFirstChild(plr, "PlayerData.Misc.LastSeenLog")
			Log.Value = game.PlaceVersion
		end
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		if Folder:FindFirstChild(plr.Name) then
			Folder:FindFirstChild(plr.Name):Destroy()
		end
	end)
end