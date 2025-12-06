--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local G = script:FindFirstChild("KillerNameToast")
local PlayerLabelPrefab = script:FindFirstChild("PlayerName")

return function(Parent: ScreenGui, plrNames: {string})
	local Group = G:Clone()
    Group.Parent = Parent

	for _, Item in Group:GetDescendants() do
		if Item:IsA("Frame") then
			Item.BackgroundTransparency = 1
		elseif Item:IsA("TextLabel") then
			Item.TextTransparency = 1
		end
	end

	local Frame = Group.Container.Frame

	for _, name in plrNames do
		local Char = workspace.Players:FindFirstChild(name)
		local CharName = Char:GetAttribute("CharacterName")
		local KillerName = require(Utils.Instance.GetCharacterModule("Killer", CharName)).Config.Name

		local PlayerLabel = PlayerLabelPrefab:Clone()
		PlayerLabel.Name = name
		PlayerLabel.KillerName.Text = KillerName
		PlayerLabel.PlayerName.Text = "("..name..")"
		PlayerLabel.Parent = Frame

		for _, Item in PlayerLabel:GetDescendants() do
			if Item:IsA("Frame") then
				Item.BackgroundTransparency = 1
			elseif Item:IsA("TextLabel") then
				Item.TextTransparency = 1
			end
		end
	end

	if #plrNames > 1 then
		Group.Container.Label.Text = "The killers are..."
	end

	task.wait(1)

	for _, Item in Group:GetDescendants() do
		if Item:HasTag("Transparent") then
			continue
		end
		if Item:IsA("Frame") then
			TweenService:Create(Item, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		elseif Item:IsA("TextLabel") then
			TweenService:Create(Item, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		end
	end

	task.wait(3)

	for _, Item in Group:GetDescendants() do
		if Item:IsA("Frame") then
			TweenService:Create(Item, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		elseif Item:IsA("TextLabel") then
			TweenService:Create(Item, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		end
	end

	task.wait(1.5)
	Group:Destroy()
end