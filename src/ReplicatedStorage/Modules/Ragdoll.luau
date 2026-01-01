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
		for _, Descendant in workspace:GetDescendants() do
			AddHumRagdoll(Descendant)
		end
		Utils.Player.ObservePlayers(function(Player: Player)
			Utils.Character.ObserveCharacter(Player, function(Char: Model)
				AddHumRagdoll(Char:FindFirstChildWhichIsA("Humanoid"))
			end)
		end)
	else
		Network:SetConnection("Ragdoll", "REMOTE_EVENT", function(Character: Model, WaitTime: number?, Force: string, Position: CFrame?)
			if WaitTime then
				while time() < WaitTime do
					task.wait()
				end
			end
			local rag = Ragdoll.Enable(Character, true)
			if rag and rag.PrimaryPart then
				if Position then
					rag:PivotTo(Position)
				end
				if Force then
					local Silly = Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer, "Advanced.SillyRagdolls")
					local ForceArr = Force:split("|")
					rag.PrimaryPart.Velocity = Vector3.new(ForceArr[1], ForceArr[2], ForceArr[3]) * (Silly and 10 or 1)
				end
			end
		end)

		local function AddHumRagdoll(Desc: Instance, Primary: BasePart?)
			local Parent = Desc.Parent
			Primary = Primary or (Parent and Parent:IsA("Model") and Utils.Character.GetRootPart(Parent))
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
						Ragdoll.Enable(Parent, true)
					end
				end)
			end
		end
		workspace.DescendantAdded:Connect(AddHumRagdoll)
		for _, Descendant in workspace:GetDescendants() do
			AddHumRagdoll(Descendant)
		end
		Utils.Player.ObservePlayers(function(Player: Player)
			Utils.Character.ObserveCharacter(Player, function(Char: Model)
				local Hum = Char:FindFirstChildWhichIsA("Humanoid")
				AddHumRagdoll(Hum, Hum.RootPart)
			end)
		end)
	end
end

--- Makes a character ragdoll.
--- If `Dupe` is true, it'll make a dupe of the character and use that as a ragdoll, useful to DEATH.
--- Used when people die. Of death. I'm funny.
function Ragdoll.Enable(Character: Model, Dupe: boolean)
	if Character:GetAttribute("CantRagdoll") or Character:GetAttribute("Ragdolling") then
		return
	end

	Character:SetAttribute("Ragdolling", true)

	local Char = Character
	local Humanoid = Char:FindFirstChildWhichIsA("Humanoid")
	if Dupe then
		local function HideOriginal()
			for _, Descendant in Character:GetDescendants() do
				local isPart = Descendant:IsA("BasePart")
				if Descendant:IsA("Decal") or isPart then
					if isPart then
						Descendant.CollisionGroup = "DeadPlayers"
					end
					Descendant.Transparency = 1
				end
			end
		end
		local RagdollFolder = workspace.Ragdolls
		if not RagdollFolder then
			return
		end
		local Silly = Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer or Players:GetPlayerFromCharacter(Char), "Advanced.SillyRagdolls")
		--handle ragdoll limit option
		Char = Character:Clone()
		Char.Parent = RagdollFolder
		if Char.PrimaryPart then
			Char.PrimaryPart.Anchored = false
		end
		HideOriginal()
		for _, Descendant in Char:GetDescendants() do
			if Descendant:IsA("Sound") or Descendant:IsA("ParticleEmitter") or Descendant:IsA("Light") or Descendant:IsA("Beam") or Descendant:IsA("Highlight") then
                Descendant:Destroy()
            end
		end
		for index, blacklisted in {
			"LinearVelocity",
			"Highlight"
		} do
			local First = Char:FindFirstChild(blacklisted, true)
			while First and (index > 1 or not Silly) do
				First.Name = "ded"
				First:Destroy()
				First = Char:FindFirstChild(blacklisted, true)
			end
		end
		task.spawn(function()
			if Humanoid then
				Humanoid.Health = 1
				Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				if RunService:IsClient() and Players.LocalPlayer.Character == Character then
					workspace.CurrentCamera.CameraSubject = Humanoid.BreakJointsOnDeath and (Char:FindFirstChild("Head") or Humanoid) or Humanoid
				end
			end
		end)
		task.delay(30, function()
			if Char.Parent then
				Debris:AddItem(Char, 10)
				for _, Descendant in Char:GetDescendants() do
					if Descendant:IsA("BasePart") or Descendant:IsA("Decal") then
                        game.TweenService:Create(Descendant, TweenInfo.new(10, Enum.EasingStyle.Linear), {
                            Transparency = 1
                        }):Play()
                    end
				end
			end
		end)
	end

	for _, Joint in Char:GetDescendants() do
		if Joint:IsA("Motor6D") and Joint.Parent.Name ~= "HumanoidRootPart" and Joint.Parent.Name ~= "Head" then
        	local BallSocketConstraint = Instance.new("BallSocketConstraint")
        	BallSocketConstraint.Name = "TemporaryRagdollInstance"
        	local Attachment = Instance.new("Attachment")
        	Attachment.Name = "TemporaryRagdollInstance"
        	local Attachment1 = Instance.new("Attachment")
        	Attachment1.Name = "TemporaryRagdollInstance"
        	Attachment.Parent = Joint.Part0
        	Attachment1.Parent = Joint.Part1
        	BallSocketConstraint.Parent = Joint.Parent
        	BallSocketConstraint.Attachment0 = Attachment
        	BallSocketConstraint.Attachment1 = Attachment1
        	Attachment.CFrame = Joint.C0
        	Attachment1.CFrame = Joint.C1
        	BallSocketConstraint.LimitsEnabled = true
        	BallSocketConstraint.TwistLimitsEnabled = true
        	Joint.Enabled = false
        end
	end
	if Humanoid then
        Char:SetAttribute("OriginalJumpInfo", ("%*|%*"):format(Humanoid.JumpPower, Humanoid.JumpHeight))
        Humanoid.RequiresNeck = false
        Humanoid.PlatformStand = true
        Humanoid.JumpPower = 0
        Humanoid.JumpHeight = 0
	end
	for _, Part in Char:GetDescendants() do
        if Part:IsA("BasePart") then
            if not Part:GetAttribute("OriginalCollision") then
                Part:SetAttribute("OriginalCollision", Part.CanCollide)
            end
            Part.CanCollide = false
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
        "Head",
        "Torso",
        "Left Arm",
        "Left Leg",
        "Right Arm",
        "Right Leg",
    }
	for _, Part in Char:GetChildren() do
        if Part:IsA("BasePart") and (table.find(Limbs, Part.Name) or Part.Transparency < 0.25 and Part.Name ~= "HumanoidRootPart" and Part.Name ~= "CollisionHitbox") then
            task.delay(0.125, function()
                Part.CanCollide = false
            end)
            if Part.Name == "Head" then
                MakeFakeLimb(Part, 0)
            else
                MakeFakeLimb(Part, -0.3)
                MakeFakeLimb(Part, 0.3)
            end
        end
    end

	return Char
end

--- Unragdolls a specific character if they're ragdolling.
function Ragdoll.Disable(Character: Model)
	if Character:GetAttribute("CantRagdoll") or not Character.Parent or not Character:FindFirstChildOfClass("Humanoid") then
		return
	end

	Character:SetAttribute("Ragdolling", false)
	for _, Descendant in Character:GetDescendants() do
		if Descendant.Name == "TemporaryRagdollInstance" then
            Descendant:Destroy()
        elseif Descendant:IsA("Motor6D") then
            Descendant.Enabled = true
        end
	end

	for _, Descendant in Character:GetChildren() do
		if Descendant.Name == "RagdollPart" then
			Descendant:Destroy()
		else
			Descendant.CanCollide = Descendant:GetAttribute("OriginalCollision")
			Descendant:SetAttribute("OriginalCollision", nil)
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
