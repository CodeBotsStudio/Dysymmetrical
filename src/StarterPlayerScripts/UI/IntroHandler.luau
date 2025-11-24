local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local KillerIntro = require(ReplicatedStorage.Classes.KillerIntro)

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

local IntroContainer = Utils.Instance.FindFirstChild(Players.LocalPlayer.PlayerGui, "KillerIntros")
local ToastPrefab = GetIntroModule("KillerNameToast")

return {
    Init = function(_)
        local KillerPlayerNames = {}
		local CurrentIntro

        local function SetupCharacter(Char: Model)
            if not workspace:GetAttribute("ClientLoaded") then
                return
            end

            local Role = Utils.Instance.FindFirstChild(Char, "Role")
            if Role.Value ~= "Killer" then
                return
            end

            local KillerName = Char:GetAttribute("CharacterName")
            local KillerSkin = Char:GetAttribute("CharacterSkinName")

            --TODO: multi-killer toast support
            KillerPlayerNames[1] = Char.Name

		    if Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer, "Miscellaneous.DisableKillerIntros") then
		    	task.spawn(require(ToastPrefab), IntroContainer, KillerPlayerNames)

		    	Utils.Player.Fade(Players.LocalPlayer, "Out", 0.6)
		    	return
		    end

			if CurrentIntro then
				CurrentIntro:Destroy()
				CurrentIntro = nil
			end
        
		    local IntroInfo: KillerIntro.IntroSettings = {
		    	KillerName = KillerName,
		    	SkinName = KillerSkin,
		    	PlayerName = KillerPlayerNames[1],
		    }

            task.delay(7.5, function()
                table.clear(KillerPlayerNames)
            end)

		    local Intro2D = GetIntroModule(KillerName, KillerSkin)

		    local Intro = Intro2D and KillerIntro:New2DIntro(IntroInfo, Intro2D) or KillerIntro:New3DIntro(IntroInfo)
			CurrentIntro = Intro

		    Intro:Init()

		    task.spawn(require(ToastPrefab), IntroContainer, KillerPlayerNames)

		    Utils.Player.Fade(Players.LocalPlayer, "Out", 0.6)

		    Intro:Play()
		    task.wait(2.5)

		    Utils.Player.Fade(Players.LocalPlayer, "In", 0.6, true)
		    Intro:Destroy()
		    Utils.Player.Fade(Players.LocalPlayer, "Out", 0.6)
        end

        local function SetupPlayer(Player: Player)
            Player.CharacterAdded:Connect(SetupCharacter)
        end

        Players.PlayerAdded:Connect(SetupPlayer)
        for _, i in Players:GetPlayers() do
            SetupPlayer(i)
        end
    end,
}