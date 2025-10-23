--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local Utils = require(ReplicatedStorage.Modules.Utils)

--ORDER GUI HERE INSTEAD OF USING "DisplayOrder" SINCE IT'S AUTOMATICALLY APPLIED HERE
StarterGui = script.Parent

local GUIs = {
	"TemporaryUI",
	"EmotePanel",
	"Time",
	"PlayerStats",
	"Effects",
	"RoundPlayerList",
	"CharacterGUI",
	"VideoPlayer",
	"KillerIntros",
	"PlayerList",
	"Menus",
	"SideBar",
	"MoneyXPRewards",
	"RewardNotifications",
	"AFKLabel",
}

for index, name in GUIs do
	Utils:FindFirstChild(StarterGui, name).DisplayOrder = index
end
