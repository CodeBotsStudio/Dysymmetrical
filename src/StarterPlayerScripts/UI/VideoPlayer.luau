--credits to PirosMacska for this since i was too lazy to write it myself -Dyscarn (Driftwood thing)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)

local module = {}

local Player = game:GetService("Players").LocalPlayer
local ScreenGUI

local frames = {}
local frame_threads = {}

local music: Sound

function module:Init()
	frames = {}
	frame_threads = {}
	ScreenGUI = Utils.Instance.FindFirstChild(Player.PlayerGui, "VideoPlayer")
end

function module:LoadVideo(assetids: {string})
	self:Reset()

	local threads = {}

	for _, rbxassetid in assetids do
		local label = Instance.new("ImageLabel")
		label.Size = Utils.UDim.Full
		label.Parent = ScreenGUI:FindFirstChild("Frames")
		label.BackgroundTransparency = 0.999
		label.ImageTransparency = 0.999
		label.Image = rbxassetid

		table.insert(frames, label)
		local thread = task.spawn(function()
			--Wait until loaded
			if not label.IsLoaded then
				repeat task.wait()
				until label.IsLoaded
			end

			label.BackgroundTransparency = 1
			label.ImageTransparency = 1
			Utils.Misc.Print("loaded")
		end)
		table.insert(threads, thread)
	end

	--Wait for all frames to load
	if #frame_threads > 0 then
		while #threads > 0 do
			if coroutine.status(threads[1]) == "dead" then
				table.remove(threads, 1)
			else
				task.wait()
			end
		end
	end

	Utils.Misc.Print("loaded")
end

function module:Reset()
	--Wait for all frames to load
	if #frame_threads > 0 then
		while #frame_threads > 0 do
			if coroutine.status(frame_threads[1]) == "dead" then
				table.remove(frame_threads, 1)
			else
				task.wait()
			end
		end
	end
	frame_threads = {}

	--Delete All Frames
	for _, frame in frames do
		frame:Destroy()
	end
	frames = {}
end

function module:AddFrame(rbxassetid: string)
	Utils.Misc.Print("loading video...")

	local label = Instance.new("ImageLabel")
	label.Size = Utils.UDim.Full
	label.Parent = ScreenGUI.Frames
	label.BackgroundTransparency = 0.999
	label.ImageTransparency = 0.999
	label.Image = rbxassetid

	table.insert(frames, label)

	local thread = task.spawn(function()
		if not label.IsLoaded then
			while not label.IsLoaded do
				task.wait(0.01)
			end
		end

		label.Parent = game:GetService("ReplicatedStorage")
		label.BackgroundTransparency = 1
		label.ImageTransparency = 1

		Utils.Misc.Print("loaded")
	end)

	table.insert(frame_threads, thread)
end

function module:SetAudio(assetid: string)
	music = Instance.new("Sound")
	music.Parent = workspace
	music.SoundId = assetid
	music.Looped = false
	music.PlaybackSpeed = 1

	Utils.Misc.Print(music.TimeLength)

	if not music.IsLoaded then
		while not music.IsLoaded do
			task.wait()
		end
	end
end

function module:Play(fps: number)
	Utils.Misc.Print("Play")

	--Wait for individualualy added frames to load
	if #frame_threads > 0 then
		while #frame_threads > 0 do
			if coroutine.status(frame_threads[1]) == "dead" then
				table.remove(frame_threads, 1)
			else
				task.wait()
			end
		end
	end

	fps = fps or 30

	local spf = 1 / fps

	ScreenGUI.Enabled = true
	Utils.Misc.Print("Play")

	local startTime = time()

	if music then 
		music:Play() 
		while not music.IsPlaying do
			task.wait()
		end
	end
	
	for frameIndex = 1, #frames do
		frames[frameIndex].Parent = ScreenGUI.Frames
		frames[frameIndex].BackgroundTransparency = 0
		frames[frameIndex].ImageTransparency = 0
		local targetTime = spf * (frameIndex - 1)
		local actualTime = time() - startTime
		local timeDelay =  actualTime - targetTime
		if timeDelay > 0 then
			task.wait(spf - timeDelay)
		end
	end

	if music then
		while music and music.IsPlaying do
			task.wait()
		end
	end

	Utils.Misc.Print(time() - startTime)

	if music then
		music:Stop()
	end

	for _, frame in frames do
		frame:Destroy()
	end
	
	ScreenGUI.Enabled = false
end

return module