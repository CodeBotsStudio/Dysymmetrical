local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local SpeedManager = {
	SpeedFactors = {},
	LastMultiplier = 1,
	CanSprint = true,
	Janitor = nil,
}

function SpeedManager:Init()
	local char = Players.LocalPlayer.Character
	local humanoid = Utils.Instance.FindFirstChild(char, "Humanoid")

	self.Janitor = Janitor.new()
	self.Janitor:LinkToInstance(char)

	self.Janitor:Add(RunService.PreSimulation:Connect(function(_delta: number)
		local CurrentSpeed = char:GetAttribute("BaseSpeed")
		if CurrentSpeed == nil then
			CurrentSpeed = 10.5
		end

		local TotalFactor = 1
		for _, factor in self.SpeedFactors do
			TotalFactor *= factor
		end

		CurrentSpeed *= TotalFactor
		humanoid.WalkSpeed = CurrentSpeed
		
		self.LastMultiplier = TotalFactor
	end))

	self.Janitor:Add(Network:SetConnection("DamagePlayer", "REMOTE_EVENT", function(_sourcePlayer: Player, _reason: string)
		self:AddSpeedFactor("DamageSpeedBurst", 1.26)
		task.delay(1, function()
			self:RemoveSpeedFactor("DamageSpeedBurst")
		end)
	end))
end

function SpeedManager:AddSpeedFactor(factorName: string, factorMultiplier: number)
	self.SpeedFactors[factorName] = factorMultiplier
end

function SpeedManager:RemoveSpeedFactor(factorName: string)
	self.SpeedFactors[factorName] = nil
end

return SpeedManager
