local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local LocalPlayer = game:GetService("Players").LocalPlayer

local FactorName = "Backpedaling"
local SpeedMult = 0.75

return {
	Init = function(_)
		local char = LocalPlayer.Character
		local Humanoid = char:FindFirstChildWhichIsA("Humanoid")
		local HumanoidRootPart = Utils.Character.GetAliveRootPart(char)

		local SpeedManager = require(script.Parent.Parent.Parent.PlayerAttributeScripts.SpeedManager)

		local jan = Janitor.new()
		jan:LinkToInstance(char)

		jan:Add(RunService.Heartbeat:Connect(function()
			local MoveDir = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
			if MoveDir.Z > 0.1 then
				if not SpeedManager.SpeedFactors[FactorName] then
					SpeedManager:AddSpeedFactor(FactorName, SpeedMult)
				end
			elseif SpeedManager.SpeedFactors[FactorName] then
				SpeedManager:RemoveSpeedFactor(FactorName)
			end
		end))
	end,
}
