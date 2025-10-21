--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KillerIntro = require(ReplicatedStorage.Classes.KillerIntro)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)

local IntroFolder = ReplicatedStorage.Assets.KillerIntros
local function GetIntroModule(name: string, skin: string?)
	local Intro

	if skin ~= nil and #skin > 0 then
		Intro = IntroFolder.Skins:FindFirstChild(name)
		if Intro then
			Intro = Intro:FindFirstChild(skin)
		end
	end

	if not Intro then
		Intro = IntroFolder:FindFirstChild(name)
	end

	return Intro
end

local IntroContainer = CommonUtils:FindFirstChild(Players.LocalPlayer.PlayerGui, "KillerIntros")
local ToastPrefab = GetIntroModule("KillerNameToast")

return function()
	Network:SetConnection("PlayIntro", "REMOTE_EVENT", function(KillerName: string, KillerPlayerName: string, KillerSkin: string?)
		local RootKillerModule = require(CommonUtils:GetCharacterModule("Killer", KillerName))

		if CommonUtils:GetPlayerSetting(Players.LocalPlayer, "Miscellaneous.DisableKillerIntros") then
			task.spawn(require(ToastPrefab), IntroContainer, RootKillerModule.Config.Name, KillerPlayerName)

			CommonUtils:Fade(Players.LocalPlayer, "Out", 0.6)
			return
		end
		
		local IntroInfo: KillerIntro.IntroSettings = {
			KillerName = KillerName,
			SkinName = KillerSkin,
			PlayerName = KillerPlayerName,
		}

		local Intro2D = GetIntroModule(KillerName, KillerSkin)

		local Intro = Intro2D and KillerIntro:New2DIntro(IntroInfo, Intro2D) or KillerIntro:New3DIntro(IntroInfo)

		Intro:Init()

		task.spawn(require(ToastPrefab), IntroContainer, RootKillerModule.Config.Name, KillerPlayerName)

		CommonUtils:Fade(Players.LocalPlayer, "Out", 0.6)

		Intro:Play()
		task.wait(2.5)

		CommonUtils:Fade(Players.LocalPlayer, "In", 0.6, true)
		Intro:Destroy()
		CommonUtils:Fade(Players.LocalPlayer, "Out", 0.6)
	end)
end