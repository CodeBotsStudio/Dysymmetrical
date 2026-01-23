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
	Initted = false,
}

local DefaultAnimations: {[string]: string} = {
	Climb = "rbxassetid://180436334",
	Fall = "rbxassetid://180436148",
	Idle = "rbxassetid://180435571",
	Walk = "rbxassetid://180426354",
	Sit = "rbxassetid://178130996",
}

local SpectatorOnly = {
	"Fall",
	"Climb",
	"Sit",
}

function AnimationManager:Init()
	if self.Initted then
		return
	end
	self.Initted = true

	--get needed instances
	self.Character = self.Character or Players.LocalPlayer.Character
	local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid")
	local HumanoidRootPart = Utils.Character.GetRootPart(self.Character)

	--load all default animations if there are no overrides in place
	for Name, ID in DefaultAnimations do
		--if there's an override already loaded, move on to the next animation
		if self.AnimationTracks[Name] then
			continue
		end

		--if this default animation should only be automatically loaded onto spectators, do so
		if self.Character:GetAttribute("Role") ~= "Spectator" and table.find(SpectatorOnly, Name) then
			continue
		end

		--load the anim with core priority
		self:LoadAnimation(Name, ID, false, Enum.AnimationPriority.Core)
	end

	--humanoid connections
	local function onClimbing(speed: number)
		self:PlayAnimation("Climb")

		self:AdjustAnimationSpeed("Climb", speed / 11)
	end

	local function onFreeFalling(active: boolean)
		if active then
			self:PlayAnimation("Fall", (self.Character:GetAttribute("AnimationTransitionTime") or 0.1) * 5)
		end
	end

	local Speed = 0
	local function onRunning(speed: number?)
		--setting speed like this to allow for backpedaling animations later
		Speed = (speed ~= nil and typeof(speed) == "number") and speed or Speed
		
		if Speed > 0.01 then
			--if the character is sprinting, sprint
			--if not, walk
			self:PlayAnimation((self.AnimationTracks.Sprint and self.Character:GetAttribute("Sprinting") == true) and "Sprint" or "Walk")
		else
			self:PlayAnimation("Idle")
		end
	end

	local function onSeated(active: boolean)
		if active then
			self:PlayAnimation("Sit")
		end
	end

	--create the janitor for the character
	self.Janitor = Janitor.new()
	self.Janitor:LinkToInstance(self.Character)

	--make all humanoid connections from before
	self.Janitor:Add(Humanoid.Climbing:Connect(onClimbing))
	self.Janitor:Add(Humanoid.FreeFalling:Connect(onFreeFalling))
	self.Janitor:Add(Humanoid.Running:Connect(onRunning))
	self.Janitor:Add(Humanoid.Seated:Connect(onSeated))
	--importantly also connect onRunning to when a sprint is fetched to update it accordingly
	Utils.Instance.ObserveAttribute(self.Character, "Sprinting", onRunning)

	--backpedaling, per frame, before animations are played
	self.Janitor:Add(RunService.PreAnimation:Connect(function()
		--sanity check
		--if neither the walk or the run animations are loaded or playing, halt
		if not ((self.AnimationTracks.Walk and self.AnimationTracks.Walk.IsPlaying) or (self.AnimationTracks.Sprint and self.AnimationTracks.Sprint.IsPlaying)) then
			return
		end

		--get horizontal movement direction based on velocity, without taking into account vertical velocity for obvious reasons
		local DirectionOfMovement = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.AssemblyLinearVelocity)
		DirectionOfMovement = Vector3.new(DirectionOfMovement.X / Humanoid.WalkSpeed, 0, DirectionOfMovement.Z / Humanoid.WalkSpeed)
		--0.1 threshold for walking backwards
		--if the character is indeed walking backwards, negate the speed to make the anims play on reverse
		local Mult = DirectionOfMovement.Z > 0.1 and -1 or 1
		--adjust as needed
		self:AdjustAnimationSpeed("Walk", (Humanoid.WalkSpeed / 16) * Mult)
		self:AdjustAnimationSpeed("Sprint", (Humanoid.WalkSpeed / 30) * Mult)
	end))

	--play idle by default
	self:PlayAnimation("Idle")
end

function AnimationManager:LoadAnimation(Name: string, ID: string, YieldUntilLoad: boolean?, PriorityOverride: Enum.AnimationPriority?): AnimationTrack
	--removes the animation if it exists
	self:RemoveAnimation(Name)

	--init the module if not initted yet
	if not self.Initted then
		self:Init()
	end
	
	--loads the new one
	local AnimationTrack = Utils.Character.LoadAnimationFromID(self.Character, ID, YieldUntilLoad)

	--HOPEFULLY replaces the priority if an override is specified
	if PriorityOverride then
		AnimationTrack.Priority = PriorityOverride
	end

	--adds to the table
	self.AnimationTracks[Name] = AnimationTrack

	return AnimationTrack
end

--- If existent, removes the animation named `Name` from this character.
function AnimationManager:RemoveAnimation(Name: string)
	--index the animation by name
	local AnimationTrack = self.AnimationTracks[Name]
	--if the animation doesn't exist, halt
	if not AnimationTrack then
		return
	end

	--stop and destroy the animation
	AnimationTrack:Stop(0)
	AnimationTrack:Destroy()

	--just in case
	self.AnimationTracks[Name] = nil
end

--- If existent and if it isn't playing yet, plays an animation named `Name` in this character.
--- 
--- `fadeTime` defaults to `Character:GetAttribute("AnimationTransitionTime")`, which in itself defaults to `0.1`.
--- 
--- `fadeTime = 0` means that the animation will snap instantly.
function AnimationManager:PlayAnimation(Name: string, fadeTime: number?)
	--index the animation by name
	local AnimationTrack: AnimationTrack = self.AnimationTracks[Name]
	--if it doesn't exist or is playing, halt
	if not AnimationTrack or AnimationTrack.IsPlaying then
		return
	end

	--check if the animation is a core animation
	if AnimationTrack.Priority == Enum.AnimationPriority.Core or DefaultAnimations[Name] or Name == "Sprint" then
		--stop existing core animation if existent
		if self.CurrentCoreAnimation then
			self.CurrentCoreAnimation:Stop(fadeTime or self.Character:GetAttribute("AnimationTransitionTime") or 0.1)
		end
		--set this animation as the new core animation and play it
		AnimationTrack:Play(fadeTime or self.Character:GetAttribute("AnimationTransitionTime") or 0.1)
		self.CurrentCoreAnimation = AnimationTrack

		return
	end

	--play the animation
	AnimationTrack:Play(fadeTime or self.Character:GetAttribute("AnimationTransitionTime") or 0.1)
end

--- If existent and playing, stops the animation named `Name` in this character.
--- 
--- `fadeTime` defaults to `Character:GetAttribute("AnimationTransitionTime")`, which in itself defaults to `0.1`.
--- 
--- `fadeTime = 0` means that the animation will snap instantly.
function AnimationManager:StopAnimation(Name: string, fadeTime: number?)
	--index the animation by name
	local AnimationTrack: AnimationTrack = self.AnimationTracks[Name]
	--if it doesn't exist or it's already not playing, halt
	if not AnimationTrack or not AnimationTrack.IsPlaying then
		return
	end

	--if it's the current core animation, resign its role like so
	if self.CurrentCoreAnimation == AnimationTrack then
		self.CurrentCoreAnimation = nil
	end

	--stop the animation
	AnimationTrack:Stop(fadeTime or self.Character:GetAttribute("AnimationTransitionTime") or 0.1)
end

--- If existent, changes the animation named `Name`'s speed to `Speed`.
function AnimationManager:AdjustAnimationSpeed(Name: string, Speed: number)
	--index the animation by name
	local AnimationTrack = self.AnimationTracks[Name]
	--if it doesn't exist, halt
	if not AnimationTrack then
		return
	end

	--adjust the speed
	AnimationTrack:AdjustSpeed(Speed)
end

--this is useless but it's done for readability's sake
--- Gets an `AnimationTrack` by name if it exists in this `AnimationManager`.
function AnimationManager:GetAnimationTrack(Name: string): AnimationTrack
	return self.AnimationTracks[Name]
end

return AnimationManager
