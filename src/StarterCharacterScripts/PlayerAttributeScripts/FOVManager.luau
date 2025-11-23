local FOVManager = {
	FOVFactors = {},
	DeltaMultiplier = 4, --6.5
	CanUpdateFOV = true,
	Conns = {},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
--
local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer

function FOVManager:Init()
	table.insert(self.Conns, RunService.PreRender:Connect(function(delta)
		if self.CanUpdateFOV then
			local FOV = LocalPlayer:GetAttribute("BaseFOV") or 70

			for _, factor in self.FOVFactors do
				FOV *= factor
			end

			Camera.FieldOfView = Utils:Lerp(
				Camera.FieldOfView,
				FOV,
				delta * self.DeltaMultiplier
			)
		end
	end))

	table.insert(self.Conns, LocalPlayer.CharacterAdded:Connect(function()
		for _, i in self.Conns do --ends the script's execution
			i:Disconnect()
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
