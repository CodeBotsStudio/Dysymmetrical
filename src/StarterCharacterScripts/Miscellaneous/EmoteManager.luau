--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

local EmoteManager = {
	EmotesAvailable = {},
	CurrentlyPlayingEmote = nil,
	Connections = {},
}

function EmoteManager:Init()
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local EquippedEmotes = Utils:FindFirstChild(LocalPlayer, "PlayerData.Equipped.Emotes")

	self.Char = Players.LocalPlayer.Character
	self.Char:SetAttribute("Emoting", false)
	self.Hum = Utils:FindFirstChild(self.Char, "Humanoid")
	self.Head = Utils:FindFirstChild(self.Char, "Head")

	self.Animator = self.Char:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")

	table.insert(self.Connections, EquippedEmotes.DescendantAdded:Connect(function(_descendant: ObjectValue)
		self:ReloadAvailableContent(EquippedEmotes)
	end))

	table.insert(self.Connections, EquippedEmotes.DescendantRemoving:Connect(function(_descendant: ObjectValue)
		self:ReloadAvailableContent(EquippedEmotes)
	end))

	for _, i in EquippedEmotes:GetChildren() do
		table.insert(self.Connections, i.Changed:Connect(function()
			self:ReloadAvailableContent(EquippedEmotes)
		end))
	end

	table.insert(self.Connections, require(LocalPlayer.PlayerScripts.InputManager).Miscellaneous.StopEmote.Pressed:Connect(function()
		if self.CurrentlyPlayingEmote then
			self:StopEmote(self.CurrentlyPlayingEmote)
		end
	end))

	table.insert(self.Connections, Utils:FindFirstChild(self.Char, "Humanoid").Died:Connect(function()
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
	if not self.EmotesAvailable[name] or not self.Hum or self.Hum.Health <= 0 then return end

	for _, i in self.EmotesAvailable do
		self:StopEmote(i.Config.Name or i)
	end

	self.CurrentlyPlayingEmote = self.EmotesAvailable[name]
	workspace.CurrentCamera.CameraSubject = self.Head
	self.CurrentlyPlayingEmote:BaseBehaviour()
end

function EmoteManager:StopEmote(name: string | {})
	if not self.Hum then
		return
	end

	if typeof(name) == "string" then
		if not self.EmotesAvailable[name] or not self.EmotesAvailable[name].TrackPlaying then
			return
		end

		Network:FireServerConnection("StopEmote", "REMOTE_EVENT", name)
		self.CurrentlyPlayingEmote = nil

		return
	end

	if self.Hum.Health > 0 then
		workspace.CurrentCamera.CameraSubject = self.Hum
	end

	Network:FireServerConnection("StopEmote", "REMOTE_EVENT", name.Config.Name)
	self.Char:SetAttribute("Emoting", false)
	self.CurrentlyPlayingEmote = nil
end

function EmoteManager:ReloadAvailableContent(EquippedEmotes: Folder)
	for _, emote: StringValue in EquippedEmotes:GetChildren() do
		if self.EmotesAvailable[emote.Value] then
			return
		end
		if not emote:IsA("StringValue") or #emote.Value <= 0 then
			continue
		end

		local Module = Utils:GetEmoteModule(emote.Value)
		if not Module then
			return
		end

		self.EmotesAvailable[emote.Value] = Utils:CopyTable(require(Module))
		Network:FireServerConnection("InitEmote", "REMOTE_EVENT", Module.Name)
		self.EmotesAvailable[emote.Value]:Init(Players.LocalPlayer, self.Animator)
	end
end

return EmoteManager
