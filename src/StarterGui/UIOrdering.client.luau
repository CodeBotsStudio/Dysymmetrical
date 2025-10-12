--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

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
	"Menus",
	"SideBar",
	"RewardNotifications",
}

for index, name in GUIs do
	CommonUtils:FindFirstChild(StarterGui, name).DisplayOrder = index
end
