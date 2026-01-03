local HitmarkerCreator = {}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local AppearTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local DisappearTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local FinalBillboardSize = UDim2.fromScale(0.7, 0.7)

local HitmarkerPrefab = Utils.Instance.FindFirstChild(script, "Hitmarker")
local HitmarkerFolder = workspace.TempObjectFolders.Hitmarkers

local SoundGroup: SoundGroup = SoundService.SoundGroups.Master.UI

function HitmarkerCreator.new(position: Vector3, dmgAmount: number, playSound: boolean?): Part
	playSound = playSound or true

	local Hitmarker = HitmarkerPrefab:Clone()
	Hitmarker.Position = position
	Hitmarker.BillboardGui.TextLabel.Text = tostring(math.floor(dmgAmount * 100) / 100)
	Hitmarker.Parent = HitmarkerFolder
	--
	if playSound then
		local SoundID = Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer, "Miscellaneous.HitsoundID")
		if SoundID and #SoundID > 0 then
			task.spawn(function()
				Sounds.PlaySound(SoundID, {Volume = 0.5, SoundGroup = SoundGroup})
			end)
		end
	end
    Debris:AddItem(Hitmarker, 5)
	task.spawn(function()
		TweenService:Create(Hitmarker.BillboardGui.TextLabel, AppearTweenInfo, {Size = FinalBillboardSize}):Play()
		task.wait(4)
		if Hitmarker then
			TweenService:Create(Hitmarker.BillboardGui.TextLabel, DisappearTweenInfo, {TextTransparency = 1}):Play()
		end
	end)

	return Hitmarker
end

return HitmarkerCreator
