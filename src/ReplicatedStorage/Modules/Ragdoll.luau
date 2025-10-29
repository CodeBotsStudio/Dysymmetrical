--!nocheck

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ragdoll = {
	HandledHumanoids = {},
}

local Utils = require(script.Parent.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

function Ragdoll:Init()
	if RunService:IsServer() then
		local function AddHumRagdoll(Desc: Instance)
			local Parent = Desc.Parent
			if Parent and Parent:IsA("Model") and Parent.PrimaryPart and Desc:IsA("Humanoid") then
				if table.find(self.HandledHumanoids, Desc) then
					return
				end

				Parent.Archivable = true
				
				table.insert(self.HandledHumanoids, Desc)
				Desc.Died:Connect(function()
					Debris:AddItem(Parent, 30)
				end)
			end
		end

		workspace.DescendantAdded:Connect(AddHumRagdoll)
		for _, i in workspace:GetDescendants() do
			AddHumRagdoll(i)
		end
		Players.PlayerAdded:Connect(function(Player: Player)
			Player.CharacterAdded:Connect(function(Char: Model)
				AddHumRagdoll(Utils:FindFirstChild(Char, "Humanoid"))
			end)
		end)
		for _, Player: Player in Players:GetPlayers() do
			Player.CharacterAdded:Connect(function(Char: Model)
				AddHumRagdoll(Utils:FindFirstChild(Char, "Humanoid"))
			end)
			if Player.Character then
				AddHumRagdoll(Utils:FindFirstChild(Player.Character, "Humanoid"))
			end
		end
	else
		Network:SetConnection("Ragdoll", "REMOTE_EVENT", function(Character: Model, WaitTime: number?, Force: string, Position: CFrame?)
			if WaitTime then
				repeat task.wait()
				until workspace:GetServerTimeNow() >= WaitTime or 0
			end
			local rag = Ragdoll:Enable(Character, true)
			if rag and rag.PrimaryPart then
				if Position then
					rag:PivotTo(Position)
				end
				if Force then
					local Silly = Utils:GetPlayerSetting(Players.LocalPlayer, "Advanced.SillyRagdolls")
					local ForceArr = Force:split("|")
					rag.PrimaryPart.Velocity = Vector3.new(ForceArr[1], ForceArr[2], ForceArr[3]) * (Silly and 10 or 1)
				end
			end
		end)

		local function AddHumRagdoll(Desc: Instance, Primary: BasePart?)
			local Parent = Desc.Parent
			Primary = Primary or (Parent and Parent:IsA("Model") and (Parent.PrimaryPart or Utils:FindFirstChild(Parent, "HumanoidRootPart", false)))
			if Primary and Desc:IsA("Humanoid") then
				if table.find(self.HandledHumanoids, Desc) then
					return
				end

				Parent.Archivable = true
				
				table.insert(self.HandledHumanoids, Desc)
				Desc.BreakJointsOnDeath = false
				Desc.Died:Connect(function()
					task.wait()
					if not Primary.Anchored then
						Ragdoll:Enable(Parent, true)
					end
				end)
			end
		end
		workspace.DescendantAdded:Connect(AddHumRagdoll)
		for _, i in workspace:GetDescendants() do
			AddHumRagdoll(i)
		end
		Players.PlayerAdded:Connect(function(Player: Player)
			Player.CharacterAdded:Connect(function(Char: Model)
				AddHumRagdoll(Utils:FindFirstChild(Char, "Humanoid"), Utils:FindFirstChild(Char, "HumanoidRootPart"))
			end)
		end)
		Network:SetConnection("SetupLocalRagdoll", "REMOTE_EVENT", function(p: Player)
			if p.Character then
				AddHumRagdoll(Utils:FindFirstChild(p.Character, "Humanoid"), Utils:FindFirstChild(p.Character, "HumanoidRootPart"))
			end
		end)
	end
end

--- Makes a character ragdoll.
--- If `Dupe` is true, it'll make a dupe of the character and use that as a ragdoll, useful to DEATH.
--- Used when people die. Of death. I'm funny.
function Ragdoll:Enable(Character: Model, Dupe: boolean)
	if Character:GetAttribute("CantRagdoll") or Character:GetAttribute("Ragdolling") then
		return
	end

	Character:SetAttribute("Ragdolling", true)

	local Char = Character
	if Dupe then
		local function HideOriginal()
			for _, i in Character:GetDescendants() do
				local isPart = i:IsA("BasePart")
				if i:IsA("Decal") or isPart then
					if isPart then
						i.CollisionGroup = "DeadPlayers"
					end
					i.Transparency = 1
				end
			end
		end
		local RagdollFolder = workspace.Ragdolls
		if not RagdollFolder then
			return
		end
		local Silly = Utils:GetPlayerSetting(Players.LocalPlayer, "Advanced.SillyRagdolls")
		--handle ragdoll limit option
		Char = Character:Clone()
		Char.Parent = RagdollFolder
		if Char.PrimaryPart then
			Char.PrimaryPart.Anchored = false
		end
		HideOriginal()
		for _, i in Char:GetDescendants() do
			if i:IsA("Sound") or i:IsA("ParticleEmitter") or i:IsA("Light") or i:IsA("Beam") or i:IsA("Highlight") then
                i:Destroy()
            end
		end
		for index, i in pairs({
			"BodyVelocity",
			"LinearVelocity",
			"Highlight"
		}) do
			local First = Char:FindFirstChild(i, true)
			while First and (index > 2 or not Silly) do
				First.Name = "ded"
				First:Destroy()
				First = Char:FindFirstChild(i, true)
			end
		end
		task.spawn(function()
			local Humanoid = Utils:FindFirstChild(Char, "Humanoid")
			if Humanoid then
				Humanoid.Health = 1
				Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				if RunService:IsClient() and Players.LocalPlayer.Character == Character then
					if Humanoid and Humanoid.BreakJointsOnDeath then
						workspace.CurrentCamera.CameraSubject = Char:FindFirstChild("Head") or Humanoid
					else
						workspace.CurrentCamera.CameraSubject = Humanoid
					end
				end
			end
		end)
		task.delay(30, function()
			if Char.Parent then
				Debris:AddItem(Char, 10)
				for _, i in Char:GetDescendants() do
					if i:IsA("BasePart") or i:IsA("Decal") then
                        game.TweenService:Create(i, TweenInfo.new(10, Enum.EasingStyle.Linear), {
                            Transparency = 1
                        }):Play()
                    end
				end
			end
		end)
	end

	for _, i in Char:GetDescendants() do
		if i:IsA("Motor6D") and i.Parent.Name ~= "HumanoidRootPart" and i.Parent.Name ~= "Head" then
        	local BallSocketConstraint = Instance.new("BallSocketConstraint")
        	BallSocketConstraint.Name = "TemporaryRagdollInstance"
        	local Attachment = Instance.new("Attachment")
        	Attachment.Name = "TemporaryRagdollInstance"
        	local Attachment1 = Instance.new("Attachment")
        	Attachment1.Name = "TemporaryRagdollInstance"
        	Attachment.Parent = i.Part0
        	Attachment1.Parent = i.Part1
        	BallSocketConstraint.Parent = i.Parent
        	BallSocketConstraint.Attachment0 = Attachment
        	BallSocketConstraint.Attachment1 = Attachment1
        	Attachment.CFrame = i.C0
        	Attachment1.CFrame = i.C1
        	BallSocketConstraint.LimitsEnabled = true
        	BallSocketConstraint.TwistLimitsEnabled = true
        	i.Enabled = false
        end
	end
	local Humanoid = Char:FindFirstChildOfClass("Humanoid")
	if Humanoid then
        Char:SetAttribute("OriginalJumpInfo", ("%*|%*"):format(Humanoid.JumpPower, Humanoid.JumpHeight))
        Humanoid.RequiresNeck = false
        Humanoid.PlatformStand = true
        Humanoid.JumpPower = 0
        Humanoid.JumpHeight = 0
	end
	for _, i in Char:GetDescendants() do
        if i:IsA("BasePart") then
            if not i:GetAttribute("OriginalCollision") then
                i:SetAttribute("OriginalCollision", i.CanCollide)
            end
            i.CanCollide = false
        end
    end

	local function MakeFakeLimb(Limb, Y)
        local Part = Instance.new("Part")
        Part.Transparency = 1
        Part.CFrame = Limb.CFrame * CFrame.new(0, Y, 0)
        Part.Size = Limb.Size - Vector3.new(0.05, 0.05 + Y, 0.05)
        Part.Name = "RagdollPart"
        Part.CollisionGroup = "Ragdolls"
        Part.Shape = Enum.PartType.Ball
        Part.Parent = Char
        local WeldConstraint = Instance.new("WeldConstraint")
    	WeldConstraint.Parent = Part
    	WeldConstraint.Part1 = Part
    	WeldConstraint.Part0 = Limb
    end

	local Limbs = {
        Head = true, 
        Torso = true, 
        ["Left Arm"] = true, 
        ["Left Leg"] = true, 
        ["Right Arm"] = true, 
        ["Right Leg"] = true
    }
	for _, i in Char:GetChildren() do
        if i:IsA("BasePart") and (Limbs[i.Name] or i.Transparency < 0.25 and i.Name ~= "HumanoidRootPart" and i.Name ~= "CollisionHitbox") then
            task.delay(0.125, function()
                i.CanCollide = false
            end)
            if i.Name == "Head" then
                MakeFakeLimb(i, 0)
            else
                MakeFakeLimb(i, -0.3)
                MakeFakeLimb(i, 0.3)
            end
        end
    end

	return Char
end

--- Unragdolls a specific character if they're ragdolling.
function Ragdoll:Disable(Character: Model)
	if Character:GetAttribute("CantRagdoll") or not Character.Parent or not Character:FindFirstChildOfClass("Humanoid") then
		return
	end

	Character:SetAttribute("Ragdolling", false)
	for _, i in Character:GetDescendants() do
		if i.Name == "TemporaryRagdollInstance" then
            i:Destroy()
        elseif i:IsA("Motor6D") then
            i.Enabled = true
        end
	end

	for _, i in Character:GetChildren() do
		if i.Name == "RagdollPart" then
			i:Destroy()
		else
			i.CanCollide = i:GetAttribute("OriginalCollision")
			i:SetAttribute("OriginalCollision", nil)
		end
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Attr = Character:GetAttribute("OriginalJumpInfo")
	if Attr then
        Attr = string.split(Attr, "|")
        Humanoid.JumpPower = Attr[1]
        Humanoid.JumpHeight = Attr[2]
    elseif not Character:FindFirstChild("Role") or Character.Role.Value == "Spectator" then
        Humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower
        Humanoid.JumpHeight = game.StarterPlayer.CharacterJumpHeight
    else
        Humanoid.JumpPower = 0
        Humanoid.JumpHeight = 0
    end
    Humanoid.PlatformStand = false
end

return Ragdoll
