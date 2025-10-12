local TurnToMoveDirection = {
	HeadPreventionFactors = {}
}
--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
--
local Character = script.Parent.Parent
--
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
if Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
	return TurnToMoveDirection
end
local HumanoidRootPart = CommonUtils:FindFirstChild(Character, "HumanoidRootPart")
local Torso = CommonUtils:FindFirstChild(Character, "Torso")
local Head = CommonUtils:FindFirstChild(Character, "Head")
--
local RootJoint = HumanoidRootPart:FindFirstChild("RootJoint")
local Neck = Torso.Neck
local RightShoulder = Torso:FindFirstChild("Right Shoulder")
local LeftShoulder = Torso:FindFirstChild("Left Shoulder")
local RightHip = Torso:FindFirstChild("Right Hip")
local LeftHip = Torso:FindFirstChild("Left Hip")
--
local RootC0 = RootJoint.C0
local NeckC0 = Neck.C0
local RightShoulderC0 = RightShoulder.C0
local LeftShoulderC0 = LeftShoulder.C0
local RightHipC0 = RightHip.C0
local LeftHipC0 = LeftHip.C0
--
local RootCF = CFrame.new()
local RightShoulderCF = CFrame.new()
local LeftShoulderCF = CFrame.new()
local RightHipCF = CFrame.new()
local LeftHipCF = CFrame.new()
local NeckCF = CFrame.new()
--
local lastWorkspaceServerTime = 0
local Updating = false
--
local framerate = 1/12
local lerpMult = 0.1
--
local deltaVal = framerate / lerpMult
--
function TurnToMoveDirection:AddHeadPreventionFactor(name: string)
	table.insert(self.HeadPreventionFactors, name)
end

function TurnToMoveDirection:RemoveHeadPreventionFactor(name: string)
	table.remove(self.HeadPreventionFactors, table.find(self.HeadPreventionFactors, name))
end

function TurnToMoveDirection:_UpdateNeckDirection()
	if Updating and #self.HeadPreventionFactors <= 0 then
		local p = Head.CFrame.p
		local lookAt = p + workspace.CurrentCamera.CFrame.LookVector * 10
		NeckCF = NeckCF:Lerp(CFrame.Angles(math.atan((Head.CFrame.Y - lookAt.Y) / (p - lookAt).magnitude) * 0.5, 0, -((p - lookAt).Unit:Cross(Torso.CFrame.lookVector).Y * -1)), deltaVal)
		Neck.C0 = NeckC0 * NeckCF
	else
		Neck.C0 = NeckC0
	end
end

function TurnToMoveDirection:_UpdateDirectionalMovement()
	if Humanoid.WalkSpeed <= 0.1 or HumanoidRootPart.Anchored or #self.HeadPreventionFactors > 0 or Character:GetAttribute("Ragdolling") then
		if Updating then
			Updating = false
			RootJoint.C0 = RootC0
			Neck.C0 = NeckC0
			RightShoulder.C0 = RightShoulderC0
			LeftShoulder.C0 = LeftShoulderC0
			RightHip.C0 = RightHipC0
			LeftHip.C0 = LeftHipC0
		end
		return
	else
		Updating = true

		local workspaceServerTimeNow = workspace:GetServerTimeNow()

		if workspaceServerTimeNow - lastWorkspaceServerTime >= framerate then
			lastWorkspaceServerTime = workspaceServerTimeNow
			local MoveDir = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)

			task.spawn(function()
				self:_UpdateNeckDirection()
			end)

			if MoveDir:Dot(Vector3.new(1, 0, -1).Unit) > 0.95 or MoveDir:Dot(Vector3.new(-1, 0, -1).Unit) > 0.95 then

				RootCF = RootCF:Lerp(CFrame.Angles(math.rad(-MoveDir.Z) * 5, 0, math.rad(-MoveDir.X) * 15), deltaVal)

				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 10, 0), deltaVal)

				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 10, 0), deltaVal)

				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, math.rad(-MoveDir.X) * 25, 0), deltaVal)

				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, math.rad(-MoveDir.X) * 25, 0), deltaVal)

			elseif MoveDir:Dot(Vector3.new(1, 0, 1).Unit) > 0.95 or MoveDir:Dot(Vector3.new(-1, 0, 1).Unit) > 0.95 then

				RootCF = RootCF:Lerp(CFrame.Angles(math.rad(-MoveDir.Z) * 5, 0, math.rad(MoveDir.X) * 15), deltaVal)

				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 10, 0), deltaVal)

				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 10, 0), deltaVal)

				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 25, 0), deltaVal)

				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 25, 0), deltaVal)

			elseif MoveDir:Dot(Vector3.new(0, 0, -1).Unit) > 0.95 then

				RootCF = RootCF:Lerp(CFrame.Angles(math.rad(-MoveDir.Z) * 0, 0, 0), deltaVal)

				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

			elseif MoveDir:Dot(Vector3.new(1, 0, 0).Unit) > 0.95 then

				RootCF = RootCF:Lerp(CFrame.Angles(0, 0, math.rad(-MoveDir.X) * 35), deltaVal)

				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 15, 0), deltaVal)

				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 15, 0), deltaVal)

				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, math.rad(-MoveDir.X) * 25, 0), deltaVal)

				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, math.rad(-MoveDir.X) * 30, 0), deltaVal)

			elseif MoveDir:Dot(Vector3.new(0, 0, 1).Unit) > 0.95 then

				RootCF = RootCF:Lerp(CFrame.Angles(math.rad(-MoveDir.Z) * 15, 0, 0), deltaVal)

				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)
				
				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)

			elseif MoveDir:Dot(Vector3.new(-1, 0, 0).Unit) > 0.95 then

				RootCF = RootCF:Lerp(CFrame.Angles(0, 0, math.rad(-MoveDir.X) * 35), deltaVal)

				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 15, 0), deltaVal)

				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, math.rad(MoveDir.X) * 15, 0), deltaVal)

				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, math.rad(-MoveDir.X) * 30, 0), deltaVal)

				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, math.rad(-MoveDir.X) * 25, 0), deltaVal)

			elseif MoveDir == Vector3.zero then

				RootCF = RootCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)
				
				RightShoulderCF = RightShoulderCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)
				
				LeftShoulderCF = LeftShoulderCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)
				
				RightHipCF = RightHipCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)
				
				LeftHipCF = LeftHipCF:Lerp(CFrame.Angles(0, 0, 0), deltaVal)
				
			end

			RootJoint.C0 = RootC0 * RootCF
			RightShoulder.C0 = RightShoulderC0 * RightShoulderCF
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderCF
			RightHip.C0 = RightHipC0 * RightHipCF
			LeftHip.C0 = LeftHipC0 * LeftHipCF
		end
	end
end

function TurnToMoveDirection:Init()
	local Conn = RunService.PreRender:Connect(function(_delta: number)
		self:_UpdateDirectionalMovement()
	end)
	Players.LocalPlayer.CharacterAdded:Once(function()
		Conn:Disconnect()
	end)
end

return TurnToMoveDirection
