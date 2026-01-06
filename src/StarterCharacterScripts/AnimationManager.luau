local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local AnimationManager = {
    FadeTime = 0.1,
    AnimationTracks = {},
	CurrentCoreAnimation = nil,
	Character = nil,
}

function AnimationManager:Init()
	local DefaultAnimations: {[string]: string} = {
		Climb = "rbxassetid://180436334",
		Fall = "rbxassetid://180436148",
		Idle = "rbxassetid://180435571",
		Walk = "rbxassetid://180426354",
		Sit = "rbxassetid://178130996",
	}

	self.Character = Players.LocalPlayer.Character
	local Humanoid = Utils.Instance.WaitForChildWhichIsA(self.Character, "Humanoid") :: Humanoid

	for Name, ID in DefaultAnimations do
		self:LoadAnimation(Name, ID, false, Enum.AnimationPriority.Core)
	end

	local function onClimbing(speed: number)
		self:PlayAnimation("Climb")

		self:AdjustAnimationSpeed("Climb", speed / 11)
	end

	local function onFreeFalling(active: boolean)
		if active then
			self:PlayAnimation("Fall", self.FadeTime * 5)
		end
	end

	local function onRunning(speed: number)
		if speed > 0.01 then
			self:PlayAnimation("Walk")

			self:AdjustAnimationSpeed("Walk", speed / 16)
		else
			self:PlayAnimation("Idle")
		end
	end

	local function onSeated(active: boolean)
		if active then
			self:PlayAnimation("Sit")
		end
	end

	Humanoid.Climbing:Connect(onClimbing)
	Humanoid.FreeFalling:Connect(onFreeFalling)
	Humanoid.Running:Connect(onRunning)
	Humanoid.Seated:Connect(onSeated)

	self:PlayAnimation("Idle")
end

function AnimationManager:LoadAnimation(Name: string, ID: string, YieldUntilLoad: boolean?, PriorityOverride: Enum.AnimationPriority?): AnimationTrack
	--removes the animation if it exists
	self:RemoveAnimation(Name)
	
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

	if AnimationTrack.Priority == Enum.AnimationPriority.Core then
		if self.CurrentCoreAnimation then
			self.CurrentCoreAnimation:Stop(fadeTime or self.FadeTime)
		end
		AnimationTrack:Play(fadeTime or self.FadeTime)
		self.CurrentCoreAnimation = AnimationTrack

		return
	end

	AnimationTrack:Play(fadeTime or self.FadeTime)
end

function AnimationManager:StopAnimation(Name: string, fadeTime: number?)
	local AnimationTrack: AnimationTrack = self.AnimationTracks[Name]
	if not AnimationTrack or not AnimationTrack.IsPlaying then
		return
	end

	if self.CurrentCoreAnimation == AnimationTrack then
		self.CurrentCoreAnimation = nil
	end

	AnimationTrack:Stop(fadeTime or self.FadeTime)
end

function AnimationManager:AdjustAnimationSpeed(Name: string, Speed: number)
	local AnimationTrack = self.AnimationTracks[Name]
	if not AnimationTrack then
		return
	end

	AnimationTrack:AdjustSpeed(Speed)
end

return AnimationManager
