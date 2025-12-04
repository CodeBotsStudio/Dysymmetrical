local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LERP_ALPHA = 0.25
local FOWARD_LEAN_ANGLE = math.rad(10)
local SIDE_LEAN_ANGLE = math.rad(35)

local TARGET_FPS = 60
local TARGET_DELTA = 1 / TARGET_FPS

local camera = workspace.CurrentCamera

return {
	HeadPreventionFactors = {},
	Init = function(self)
		Utils.Player.ObservePlayers(function(player: Player, playerJanitor)
			playerJanitor:Add(Utils.Character.ObserveHumanoid(player, function(humanoid: Humanoid, humanoidJanitor)
				local character = humanoid.Parent
				--TODO: support for r15 and customs
				if character:GetAttribute("CustomRig") or humanoid.RigType ~= Enum.HumanoidRigType.R6 then
					return
				end

				local rootPart = humanoid.RootPart
				local torso = Utils.Instance.FindFirstChild(character, "Torso") :: BasePart
				local head = Utils.Instance.FindFirstChild(character, "Head") :: BasePart

				local joints: {[string]: Motor6D} = {
					RootJoint = rootPart:FindFirstChild("RootJoint"),
					Neck = torso:FindFirstChild("Neck"),
					RightShoulder = torso:FindFirstChild("Right Shoulder"),
					LeftShoulder = torso:FindFirstChild("Left Shoulder"),
					RightHip = torso:FindFirstChild("Right Hip"),
					LeftHip = torso:FindFirstChild("Left Hip"),
				}

				local defaultC0s = {}
				local offsets = {}

				for name, joint in joints do
					defaultC0s[name] = joint.C0
					offsets[name] = CFrame.identity
				end

				local function lerpTilt(name: string, angles: {number}, deltaTimeSim: number)
					offsets[name] = offsets[name]:Lerp(CFrame.Angles(table.unpack(angles)), LERP_ALPHA * deltaTimeSim)
				end

				local Accumulator = 0
				humanoidJanitor:Add(RunService.PreSimulation:Connect(function(deltaTimeSim: number)
					Accumulator += deltaTimeSim
					if Accumulator < TARGET_DELTA then
						return
					end

					deltaTimeSim = Accumulator * 60
					Accumulator = 0

					-- NOTE: disabled this because of smooth shift lock, might find a workaround later -dys

					-- if not humanoid.AutoRotate then
					-- 	for name, joint in joints do
					-- 		if name == "Neck" then
					-- 			continue
					-- 		end
					-- 		joint.C0 = joint.C0:Lerp(defaultC0s[name], 0.1 * deltaTimeSim)
					-- 	end
					-- 	return
					-- end

					local moveDirection = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

					local x = math.clamp(moveDirection.X, -1, 1)
					local z = math.clamp(moveDirection.Z, -1, 1)

					local forwardLean = -z * FOWARD_LEAN_ANGLE
					local sideLean = -x * SIDE_LEAN_ANGLE
					-- isBackward = z > 0.5
					local hipTiltFactor = z > 0.5 and 1 or -1

					for name, angles in {
						RootJoint = {forwardLean, 0, sideLean * -hipTiltFactor},
						Neck = {-forwardLean * 0.5, 0, -sideLean * 0.5},
						Shoulder = {0, x * math.rad(10), 0},
						Hip = {0, hipTiltFactor * x * math.rad(20), 0},
					} do

						if name:lower() == "hip" or name:lower() == "shoulder" then
							for _, side in {"Left", "Right"} do
								lerpTilt(side..name, angles, deltaTimeSim)
							end

							continue
						end

						lerpTilt(name, angles, deltaTimeSim)
					end

					for name, joint in joints do
						if name == "Neck" then
							continue
						end
						joint.C0 = defaultC0s[name] * offsets[name]
					end

					if player ~= Players.LocalPlayer then
						return
					end

					local cameraLook = camera.CFrame.LookVector
					local torsoLook = torso.CFrame.LookVector
					local headPos = head.Position
					local targetPos = headPos + cameraLook * 10

					local dist = (headPos - targetPos).Magnitude
					local diff = head.Position.Y - targetPos.Y

					local finalx = (((headPos - targetPos).Unit):Cross(torsoLook)).Y * -1
					local y = (math.atan(diff / dist) / 2)

					joints.Neck.C0 = Utils.Type.GetCountOfDict(self.HeadPreventionFactors) <= 0 and joints.Neck.C0:Lerp(defaultC0s["Neck"] * CFrame.Angles(y, 0, -finalx), LERP_ALPHA * deltaTimeSim) or defaultC0s["Neck"]
				end))
			end))
		end)
	end,
	AddHeadPreventionFactor = function(self, name: string)
		self.HeadPreventionFactors[name] = true
	end,
	RemoveHeadPreventionFactor = function(self, name: string)
		self.HeadPreventionFactors[name] = nil
	end,
}