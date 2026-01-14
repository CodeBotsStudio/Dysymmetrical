local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local EmoteManager = {
	EmotesAvailable = {},
	CurrentlyPlayingEmote = nil,
	Janitor = Janitor.new(),
}

function EmoteManager:Init()
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local EquippedEmotes = Utils.Instance.FindFirstChild(LocalPlayer, "PlayerData.Equipped.Emotes")

	self.Char = Players.LocalPlayer.Character
	self.Char:SetAttribute("Emoting", false)
	self.Hum = self.Char:FindFirstChildWhichIsA("Humanoid")
	self.Head = self.Char:FindFirstChild("Head")

	self.Animator = self.Char:FindFirstChildWhichIsA("Humanoid"):FindFirstChildWhichIsA("Animator")

	self.Janitor:LinkToInstance(self.Char)

	self.Janitor:Add(EquippedEmotes.DescendantAdded:Connect(function(_descendant: ObjectValue)
		self:ReloadAvailableContent(EquippedEmotes)
	end))

	self.Janitor:Add(EquippedEmotes.DescendantRemoving:Connect(function(_descendant: ObjectValue)
		self:ReloadAvailableContent(EquippedEmotes)
	end))

	for _, Emote in EquippedEmotes:GetChildren() do
		self.Janitor:Add(Emote.Changed:Connect(function()
			self:ReloadAvailableContent(EquippedEmotes)
		end))
	end

	self.Janitor:Add(require(LocalPlayer.PlayerScripts.InputManager):GetInputAction("Miscellaneous.StopEmote").Pressed:Connect(function()
		if self.CurrentlyPlayingEmote then
			self:StopEmote(self.CurrentlyPlayingEmote)
		end
	end), "Disconnect")

	self.Janitor:Add(self.Hum.Died:Connect(function()
		if self.CurrentlyPlayingEmote then
			self:StopEmote(self.CurrentlyPlayingEmote)
		end
	end))

	self.Janitor:Add(function()
		for _, Emote in self.EmotesAvailable do
			self:StopEmote(Emote.Config.Name)
		end
		if self.Char then
			self.Char:SetAttribute("Emoting", false)
		end
	end, true)

	self:ReloadAvailableContent(EquippedEmotes)
end

function EmoteManager:PlayEmote(name: string)
	if not self.EmotesAvailable[name] or not self.Hum or self.Hum.Health <= 0 then return end

	for _, Emote in self.EmotesAvailable do
		self:StopEmote(Emote.Config.Name or Emote)
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

		local Module = Utils.Instance.GetEmoteModule(emote.Value)
		if not Module then
			return
		end

		self.EmotesAvailable[emote.Value] = Utils.Type.CopyTable(require(Module))
		Network:FireServerConnection("InitEmote", "REMOTE_EVENT", Module.Name)
		self.EmotesAvailable[emote.Value]:Init(Players.LocalPlayer)
	end
end

return EmoteManager
