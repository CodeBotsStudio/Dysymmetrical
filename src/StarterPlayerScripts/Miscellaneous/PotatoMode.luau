--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local GameSettings = UserSettings():GetService("UserGameSettings")

local POTATO_MAX_QUALITY = 3

local function isPotato(): boolean
	local level = GameSettings.SavedQualityLevel.Value
	return level > 0 and level <= POTATO_MAX_QUALITY
end

local function apply(detail: Instance)
	local on = not isPotato()
	if detail:IsA("BasePart") then
		detail.LocalTransparencyModifier = if on then 0 else 1
	elseif detail:IsA("ParticleEmitter") or detail:IsA("Beam") or detail:IsA("PostEffect") then
		detail.Enabled = on
	end
end

local function applyAll()
	Players.LocalPlayer:SetAttribute("Potato", isPotato())
	for _, detail in CollectionService:GetTagged("Detail") do
		apply(detail)
	end
end

return {
	Init = function(_)
		CollectionService:GetInstanceAddedSignal("Detail"):Connect(apply)
		GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(applyAll)
		applyAll()
	end,
}
