--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)

local EmoteManager = {
	EmotesAvailable = {},
	CurrentlyPlayingEmote = nil,
	Connections = {},
}

function EmoteManager:Init()
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local EquippedEmotes = CommonUtils:FindFirstChild(LocalPlayer, "PlayerData.Equipped.Emotes")

	self.Char = Players.LocalPlayer.Character
	self.Char:SetAttribute("Emoting", false)

	self.Animator = self.Char:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")

	table.insert(self.Connections, EquippedEmotes.DescendantAdded:Connect(function(_descendant: ObjectValue)
		self:ReloadAvailableContent(EquippedEmotes)
	end))

	table.insert(self.Connections, EquippedEmotes.DescendantRemoving:Connect(function(_descendant: ObjectValue)
		self:ReloadAvailableContent(EquippedEmotes)
	end))

	table.insert(self.Connections, require(LocalPlayer.PlayerScripts.InputManager).Miscellaneous.StopEmote.Pressed:Connect(function()
		print(self.CurrentlyPlayingEmote)
		if self.CurrentlyPlayingEmote then
			self:StopEmote(self.CurrentlyPlayingEmote)
		end
	end))

	table.insert(self.Connections, LocalPlayer.CharacterAdded:Connect(function()
		for _, i in self.EmotesAvailable do
			self:StopEmote(i.Config.Name)
		end
		self.Char:SetAttribute("Emoting", false)
		for _, i in self.Connections do
			i:Disconnect() --ends the script's execution
		end
	end))

	self:ReloadAvailableContent(EquippedEmotes)
end

function EmoteManager:PlayEmote(name: string)
	if not self.EmotesAvailable[name] then return end

	for _, i in self.EmotesAvailable do
		self:StopEmote(i.Config.Name or i)
	end

	self.Char:SetAttribute("Emoting", true)

	self.CurrentlyPlayingEmote = self.EmotesAvailable[name]
	self.CurrentlyPlayingEmote:BaseBehaviour()
end

function EmoteManager:StopEmote(name: string | {})
	if typeof(name) == "string" then
		if not self.EmotesAvailable[name] or not self.EmotesAvailable[name].TrackPlaying then return end

		Network:FireServerConnection("StopEmote", "REMOTE_EVENT", name)
		if self.EmotesAvailable[name] == self.CurrentlyPlayingEmote then
			self.CurrentlyPlayingEmote = nil
		end

		self.Char:SetAttribute("Emoting", false)

		return
	end

	Network:FireServerConnection("StopEmote", "REMOTE_EVENT", name.Config.Name)
	self.CurrentlyPlayingEmote = nil
end

function EmoteManager:ReloadAvailableContent(EquippedEmotes: Folder)
	table.clear(self.EmotesAvailable)
	for _, emote: IntValue in EquippedEmotes:GetChildren() do
		if not emote:IsA("IntValue") then continue end

		local Module = CommonUtils:GetEmoteModule(emote.Name)
		self.EmotesAvailable[emote.Name] = CommonUtils:CopyTable(require(Module))
		if not self.EmotesAvailable[emote.Name].Initted then
			Network:FireServerConnection("InitEmote", "REMOTE_EVENT", Module.Name)
			self.EmotesAvailable[emote.Name]:Init(Players.LocalPlayer, self.Animator)
		end
	end
end

return EmoteManager
