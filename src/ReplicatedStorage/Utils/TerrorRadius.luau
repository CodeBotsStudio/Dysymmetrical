-- im not documenting this it isnt mine lol

local Radiuses = {
	["L4Upcoming"] = -1e10, ["L4"] = 15,
	["L3Upcoming"] = 15, ["L3"] = 30,
	["L2Upcoming"] = 30, ["L2"] = 45,
	["L1Upcoming"] = 45, ["L1"] = 60,
}

local Player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Terror = {}
Terror.__index = Terror

local function calcSound(distance)
	return 4.96 / (distance + 10.26)
end

function Terror.New(LayerFolder, Killer: Model)
	if game["Run Service"]:IsServer() then
		warn("Terror module should only run on client -", script.Name)
		return
	end

	local self = setmetatable({}, Terror)
	self.Layers = LayerFolder
	self.Killer = Killer
	self.LayerMagnitudes = {}
	self.Connections = {}
	self.InChase = false
	self.PlayerClose = false
	self.alreadyPlaying = false

	-- Create theme sounds folder
	local themeFolder = Instance.new("Folder")
	themeFolder.Name = "KillerThemes"
	themeFolder.Parent = SoundService
	self.ThemeFolder = themeFolder

	for layerName, id in LayerFolder do
		local sound = Instance.new("Sound")
		sound.Name = layerName
		sound.SoundId = id
		sound.Volume = 0
		sound.Looped = true
		if layerName ~= "L4" then
			sound:Play()
		end
		sound.SoundGroup = SoundService.SoundGroups.Master.Music
		sound.Parent = themeFolder

		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end

		self:SetLayerMag(sound, Radiuses[sound.Name])
	end

	self:Initialize()

	-- Handle killer logic
	if Killer == Player.Character then
		self.Connections.TerrorCheck = RunService.PreRender:Connect(function()
			self:RadiusCheckIfSelfIsKiller()
		end)
	else
		self.Connections.TerrorCheck = RunService.PreRender:Connect(function()
			self:RadiusCheck()
		end)
	end

	Killer.Destroying:Connect(function()
		self:Delete()
	end)

	return self
end

function Terror:Initialize()
	local hum = self.Killer:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			self:Delete()
		end)
	end
end

function Terror:Delete()
	if self.ThemeFolder then
		self.ThemeFolder:Destroy()
	end
	for _, conn in self.Connections do
		conn:Disconnect()
	end
end

function Terror:SetLayerMag(sound: Sound, radius: number)
	table.insert(self.LayerMagnitudes, {sound, radius})
end

function Terror:RadiusCheck()
	local playerHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	local playerHumanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	local killerHRP = self.Killer and self.Killer:FindFirstChild("HumanoidRootPart")
	if not (playerHRP and killerHRP) then return end

	local dist = playerHumanoid and playerHumanoid.Health > 0 and (playerHRP.Position - killerHRP.Position).Magnitude or 1e999

	for _, data in ipairs(self.LayerMagnitudes) do
		local sound, radius = data[1], data[2]
		local upcoming = Radiuses[sound.Name .. "Upcoming"] or -1e10

		print(dist, radius, upcoming, self.InChase)

		if self.InChase then
			if dist < 60 and not killerHRP.Parent.Effects:FindFirstChild("Undetectable") then
				if sound.Name == "L4" then
					local volume = (dist < 55) and 1.05 or calcSound(dist)
					self:TweenVolume(sound, volume)
				else
					self:TweenVolume(sound, 0)
				end
			else
				self.InChase = false
				if sound.Name == "L4" then
					self:TweenVolume(sound, 0)
				end
			end
		else
			if dist <= radius and dist > upcoming and not killerHRP.Parent.Effects:FindFirstChild("Undetectable") then
				if sound.Name == "L4" then
					self.InChase = true
					self:PlayL4()
				else
					self:TweenVolume(sound, calcSound(dist))
				end
			else
				self:TweenVolume(sound, 0)
			end
		end
	end
end

function Terror:TweenVolume(sound: Sound, targetVolume: number)
	if math.abs(sound.Volume - targetVolume) > 0.01 then
		TweenService:Create(sound, TweenInfo.new(0.25), {Volume = targetVolume}):Play()
	end
end

function Terror:PlayL4()
	if self.alreadyPlaying then return end
	self.alreadyPlaying = true

	for _, data in ipairs(self.LayerMagnitudes) do
		local sound = data[1]
		if sound.Name == "L4" then
			sound:Play()
			self:TweenVolume(sound, 0.2)
			sound.Changed:Connect(function()
				if sound.Volume <= 0 then
					self.alreadyPlaying = false
				end
			end)
		else
			self:TweenVolume(sound, 0)
		end
	end
end

function Terror:RadiusCheckIfSelfIsKiller()
	local killerHRP = self.Killer and self.Killer:FindFirstChild("HumanoidRootPart")
	if not killerHRP then return end

	local playersFolder = workspace:FindFirstChild("Players")
	if not playersFolder then return end

	for _, char in playersFolder:GetChildren() do
		if char ~= Player.Character and char:FindFirstChild("Role") and char.Role.Value == "Survivor" and char:FindFirstChildOfClass("Humanoid").Health > 0 then
			local charHRP = char:FindFirstChild("HumanoidRootPart")
			if not charHRP then continue end

			local dist = (charHRP.Position - killerHRP.Position).Magnitude
			self.PlayerClose = dist <= 60
			self.InChase = dist <= 25 or self.InChase and dist <= 35

			for _, data in ipairs(self.LayerMagnitudes) do
				local sound = data[1]
				if sound.Name == "L4" then
					self:TweenVolume(sound, (self.PlayerClose and self.InChase) and 0.5 or 0)
				end
			end

			if self.InChase then
				self:PlayL4()
			end
		end
	end
end

return Terror
