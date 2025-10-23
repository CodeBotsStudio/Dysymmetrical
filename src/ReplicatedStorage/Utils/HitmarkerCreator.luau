local HitmarkerCreator = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local AppearTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local DisappearTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local FinalBillboardSize = UDim2.fromScale(0.7, 0.7)

local HitmarkerPrefab = Utils:FindFirstChild(script, "Hitmarker")
local HitmarkerFolder = workspace.TempObjectFolders.Hitmarkers

local SoundGroup: SoundGroup = SoundService.SoundGroups.Master.UI

function HitmarkerCreator:ShowHitmarker(position: Vector3, dmgAmount: number, playSound: boolean?)
	playSound = playSound or true

	local Hitmarker = HitmarkerPrefab:Clone()
	Hitmarker.Position = position
	Hitmarker.BillboardGui.TextLabel.Text = tostring(dmgAmount)
	Hitmarker.Parent = HitmarkerFolder
	--
	if playSound then
		local SoundID = Utils:GetPlayerSetting(Players.LocalPlayer, "Miscellaneous.HitsoundID")
		if SoundID and #SoundID > 0 then
			task.spawn(function()
				Sounds:PlaySound(SoundID, {Volume = 0.5, SoundGroup = SoundGroup})
			end)
		end
	end
	--
	TweenService:Create(Hitmarker.BillboardGui.TextLabel, AppearTweenInfo, {Size = FinalBillboardSize}):Play()
	task.wait(4)
	TweenService:Create(Hitmarker.BillboardGui.TextLabel, DisappearTweenInfo, {TextTransparency = 1}):Play()
	task.wait(1)
	Hitmarker:Destroy()
end

return HitmarkerCreator
