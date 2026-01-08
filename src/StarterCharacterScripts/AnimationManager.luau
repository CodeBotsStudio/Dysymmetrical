local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local AnimationManager = {
    AnimationTracks = {},
	CurrentCoreAnimation = nil,
	Character = nil,
	Janitor = nil,
	AnimationTransitionTime = nil,
}

local DefaultAnimations: {[string]: string} = {
	Climb = "rbxassetid://180436334",
	Fall = "rbxassetid://180436148",
	Idle = "rbxassetid://180435571",
	Walk = "rbxassetid://180426354",
	Sit = "rbxassetid://178130996",
}

function AnimationManager:Init()
	self.Character = Players.LocalPlayer.Character
	local Humanoid = Utils.Instance.WaitForChildWhichIsA(self.Character, "Humanoid") :: Humanoid
	local HumanoidRootPart = Utils.Character.GetRootPart(self.Character)

	local Sprinting = self.Character.PlayerAttributes.Sprinting

	self.AnimationTransitionTime = Utils.Instance.FindFirstChild(self.Character, "PlayerAttributes.AnimationTransitionTime")

	for Name, ID in DefaultAnimations do
		if self.AnimationTracks[Name] then
			continue
		end
		
		self:LoadAnimation(Name, ID, false, Enum.AnimationPriority.Core)
	end

	local function onClimbing(speed: number)
		self:PlayAnimation("Climb")

		self:AdjustAnimationSpeed("Climb", speed / 11)
	end

	local function onFreeFalling(active: boolean)
		if active then
			self:PlayAnimation("Fall", self.AnimationTransitionTime.Value * 5)
		end
	end

	local Speed = 0
	local function onRunning(speed: number?)
		Speed = (speed ~= nil and typeof(speed) == "number") and speed or Speed
		
		print(Speed)
		if Speed > 0.01 then
			self:PlayAnimation(if (self.AnimationTracks.Sprint and Sprinting.Value) then "Sprint" else "Walk")
			print(if (self.AnimationTracks.Sprint and Sprinting.Value) then "Sprint" else "Walk")
		else
			self:PlayAnimation("Idle")
			print("Idle")
		end
	end

	local function onSeated(active: boolean)
		if active then
			self:PlayAnimation("Sit")
		end
	end

	self.Janitor = Janitor.new()
	self.Janitor:LinkToInstance(self.Character)

	self.Janitor:Add(Humanoid.Climbing:Connect(onClimbing))
	self.Janitor:Add(Humanoid.FreeFalling:Connect(onFreeFalling))
	self.Janitor:Add(Humanoid.Running:Connect(onRunning))
	self.Janitor:Add(Humanoid.Seated:Connect(onSeated))
	self.Janitor:Add(Sprinting.Changed:Connect(onRunning))

	self.Janitor:Add(RunService.PreAnimation:Connect(function()
		if (self.AnimationTracks.Walk and self.AnimationTracks.Walk.IsPlaying) or (self.AnimationTracks.Sprint and self.AnimationTracks.Sprint.IsPlaying) then
			local DirectionOfMovement = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.AssemblyLinearVelocity)
			DirectionOfMovement = Vector3.new(DirectionOfMovement.X / Humanoid.WalkSpeed, 0, DirectionOfMovement.Z / Humanoid.WalkSpeed)
			if DirectionOfMovement.Z > 0.1 then
				self:AdjustAnimationSpeed("Walk", -(Humanoid.WalkSpeed / 16))
				self:AdjustAnimationSpeed("Sprint", -(Humanoid.WalkSpeed / 30))
			else
				self:AdjustAnimationSpeed("Walk", Humanoid.WalkSpeed / 16)
				self:AdjustAnimationSpeed("Sprint", Humanoid.WalkSpeed / 30)
			end
		end
	end))

	self:PlayAnimation("Idle")
end

function AnimationManager:LoadAnimation(Name: string, ID: string, YieldUntilLoad: boolean?, PriorityOverride: Enum.AnimationPriority?): AnimationTrack
	--removes the animation if it exists
	self:RemoveAnimation(Name)

	while not self.Character do
		task.wait(0.1)
	end
	
	--loads the new one
	local AnimationTrack = Utils.Character.LoadAnimationFromID(self.Character, ID, YieldUntilLoad)

	if PriorityOverride then
		AnimationTrack.Priority = PriorityOverride
	end

	self.AnimationTracks[Name] = AnimationTrack

	return AnimationTrack
end

function AnimationManager:RemoveAnimation(Name: string)
	local AnimationTrack = self.AnimationTracks[Name]
	if AnimationTrack then
		AnimationTrack:Stop(0)
		AnimationTrack:Destroy()
	end
end

function AnimationManager:PlayAnimation(Name: string, fadeTime: number?)
	local AnimationTrack: AnimationTrack = self.AnimationTracks[Name]
	if not AnimationTrack or AnimationTrack.IsPlaying then
		return
	end

	if AnimationTrack.Priority == Enum.AnimationPriority.Core or DefaultAnimations[Name] or Name == "Sprint" then
		if self.CurrentCoreAnimation then
			self.CurrentCoreAnimation:Stop(fadeTime or self.AnimationTransitionTime.Value)
		end
		AnimationTrack:Play(fadeTime or self.AnimationTransitionTime.Value)
		self.CurrentCoreAnimation = AnimationTrack

		return
	end

	AnimationTrack:Play(fadeTime or self.AnimationTransitionTime.Value)
end

function AnimationManager:StopAnimation(Name: string, fadeTime: number?)
	local AnimationTrack: AnimationTrack = self.AnimationTracks[Name]
	if not AnimationTrack or not AnimationTrack.IsPlaying then
		return
	end

	if self.CurrentCoreAnimation == AnimationTrack then
		self.CurrentCoreAnimation = nil
	end

	AnimationTrack:Stop(fadeTime or self.AnimationTransitionTime.Value)
end

function AnimationManager:AdjustAnimationSpeed(Name: string, Speed: number)
	local AnimationTrack = self.AnimationTracks[Name]
	if not AnimationTrack then
		return
	end

	AnimationTrack:AdjustSpeed(Speed)
end

return AnimationManager
