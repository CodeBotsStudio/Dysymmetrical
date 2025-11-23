local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local GlobalTurnToMoveDirection = {
    HeadPreventionFactors = {},
}

local framerate = 1/60
local lerpMult = 0.1

local deltaVal = framerate / lerpMult

function GlobalTurnToMoveDirection:Init()
    Players.PlayerAdded:Connect(function(plr: Player)
		self:SetupPlayer(plr)
	end)
    for _, Player: Player in Players:GetPlayers() do
        task.spawn(function()
			self:SetupPlayer(Player)
		end)
    end
end

function GlobalTurnToMoveDirection:SetupPlayer(Player: Player)
    local Conn
    Player.CharacterAdded:Connect(function(Char: Model)
        if Conn then
            Conn:Disconnect()
        end
        Conn = self:SetupCharacter(Char)
    end)
    if Player.Character then
        Conn = self:SetupCharacter(Player.Character)
    end
end

function GlobalTurnToMoveDirection:SetupCharacter(Char: Model): RBXScriptConnection?
    local Humanoid = Utils:FindFirstChild(Char, "Humanoid")
    if Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
    	return
    end
    local HumanoidRootPart = Utils:FindFirstChild(Char, "HumanoidRootPart")
    local Torso = Utils:FindFirstChild(Char, "Torso")
    local Head = Utils:FindFirstChild(Char, "Head")
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

    local function UpdateNeckDirection()
	    if Updating and #self.HeadPreventionFactors <= 0 then
	    	local p = Head.CFrame.p
	    	local lookAt = p + workspace.CurrentCamera.CFrame.LookVector * 10
	    	NeckCF = NeckCF:Lerp(CFrame.Angles(math.atan((Head.CFrame.Y - lookAt.Y) / (p - lookAt).magnitude) * 0.5, 0, -((p - lookAt).Unit:Cross(Torso.CFrame.lookVector).Y * -1)), deltaVal)
	    	Neck.C0 = NeckC0 * NeckCF
	    else
	    	Neck.C0 = NeckC0
	    end
    end

    return RunService.PreRender:Connect(function(_delta: number)
		--failsafe
		if not Char or not HumanoidRootPart or not Torso or not Humanoid or Humanoid.Health <= 0 then
			return
		end
        if Humanoid.WalkSpeed <= 0.1 or HumanoidRootPart.Anchored or Char:GetAttribute("Ragdolling") then
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

                if Players.LocalPlayer.Character and Char == Players.LocalPlayer.Character then
	    		    task.spawn(UpdateNeckDirection)
                end

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
    end)
end

function GlobalTurnToMoveDirection:AddHeadPreventionFactor(Factor: string)
	table.insert(self.HeadPreventionFactors, Factor)
end
function GlobalTurnToMoveDirection:RemoveHeadPreventionFactor(Factor: string)
	table.remove(self.HeadPreventionFactors, table.find(self.HeadPreventionFactors, Factor))
end

return GlobalTurnToMoveDirection
