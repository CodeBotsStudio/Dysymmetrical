local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer

local FOVManager = {
	FOVFactors = {},
	DeltaMultiplier = 4, --6.5
	CanUpdateFOV = true,
	Janitor = nil,
}

function FOVManager:Init()
	self.Janitor = Janitor.new()
	self.Janitor:LinkToInstance(LocalPlayer.Character)

	self.Janitor:Add(RunService.PreRender:Connect(function(delta)
		if self.CanUpdateFOV then
			local FOV = LocalPlayer:GetAttribute("BaseFOV") or 70

			for _, factor in self.FOVFactors do
				FOV *= factor
			end

			Camera.FieldOfView = Utils.Math.Lerp(
				Camera.FieldOfView,
				FOV,
				delta * self.DeltaMultiplier
			)
		end
	end))
end

function FOVManager:AddFOVFactor(factorName: string, factorMultiplier: number)
	self.FOVFactors[factorName] = factorMultiplier
end

function FOVManager:RemoveFOVFactor(factorName: string)
	self.FOVFactors[factorName] = nil
end

return FOVManager
