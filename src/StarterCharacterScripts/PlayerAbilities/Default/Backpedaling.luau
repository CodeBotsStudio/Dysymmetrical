--!nocheck

local Backpedaling = {}
--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
--
local LocalPlayer = game:GetService("Players").LocalPlayer
local char = LocalPlayer.Character
local HumanoidRootPart: BasePart = Utils:FindFirstChild(char, "HumanoidRootPart")
local Humanoid = Utils:FindFirstChild(char, "Humanoid")
--
local SpeedManager = require(script.Parent.Parent.Parent.PlayerAttributeScripts.SpeedManager)
--
local FactorName = "Backpedaling"
local SpeedMult = 0.75
--
function Backpedaling:Init()
	local Conn: RBXScriptConnection = RunService.Heartbeat:Connect(function()
		local MoveDir = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
		if MoveDir.Z > 0.1 then
			if not SpeedManager.SpeedFactors[FactorName] then
				SpeedManager:AddSpeedFactor(FactorName, SpeedMult)
			end
		elseif SpeedManager.SpeedFactors[FactorName] then
			SpeedManager:RemoveSpeedFactor(FactorName)
		end
	end)

    local ParentConn: RBXScriptConnection
	ParentConn = char.Destroying:Connect(function()
		Conn:Disconnect()
		ParentConn:Disconnect()
	end)
end

return Backpedaling
