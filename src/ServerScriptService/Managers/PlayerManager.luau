--!nocheck

local PlayerManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local TimeManager = require(ServerScriptService.Managers.TimeManager)

local AntiFly = require(ServerScriptService.Security.AntiFly)
local CommonFunctions = require(ServerScriptService.System.CommonFunctions)

local Network = require(ReplicatedStorage.Modules.Network)

local threads: {thread} = {}

local Folder = ReplicatedStorage.LoadedPlayers
local Hitboxes = ServerStorage.Assets.Hitboxes

local CharFolder = ServerStorage.Assets.Characters
local StarterCharacterScripts = game:GetService("StarterPlayer").StarterCharacterScripts
local PlayerFolder = workspace.Players

local StunSPPrefab = Utils:FindFirstChild(script, "StunSpawnProtection")

function PlayerManager:Init()
	local TimePlayedThreads = {}

	ReplicatedStorage.PlaceVersion.Value = game.PlaceVersion

	Players.PlayerAdded:Connect(function(plr: Player)
		plr.CharacterAdded:Connect(function(char)
			AntiFly:_SetupCharacter(plr, char)
			
			local Role = char:FindFirstChild("Role")
			if not Role then
				Role = Instance.new("StringValue")
				Role.Name = "Role"
				Role.Value = "Spectator"
				Role.Parent = char
			end

			if char:GetAttribute("BaseSpeed") == nil then
				char:SetAttribute("BaseSpeed", 10.5)
			end

			char.Parent = PlayerFolder
			
        	Utils:FindFirstChild(char, "Humanoid").BreakJointsOnDeath = false

			local KillerValue
			if Role.Value ~= "Spectator" then
				self:_SetupHitboxes(char)

				local CollisionGroup = Role.Value

				for _, i in char:GetDescendants() do
					if not i:IsA("BasePart") or i:IsDescendantOf(char.Hitboxes) then
						continue
					end
					
					i.CollisionGroup = CollisionGroup
				end

				if Role.Value ~= "Killer" then
					KillerValue = Instance.new("ObjectValue")
					KillerValue.Name = "Killer"
					KillerValue.Parent = char
					local KillerValueThread
					KillerValue.Changed:Connect(function(value: Instance?)
						if KillerValueThread then
							task.cancel(KillerValueThread)
						end

						if not value then
							return
						end

						KillerValueThread = task.delay(15, function()
							KillerValue.Value = nil
						end)
					end)
				else
					StunSPPrefab:Clone().Parent = Utils:FindFirstChild(char, "HumanoidRootPart")
				end
			else
				for _, i in char:GetDescendants() do
					if not i:IsA("BasePart") then
						continue
					end
					
					i.CollisionGroup = "Spectator"
				end
			end

			local LeaveConn
			if KillerValue then
				LeaveConn = Players.PlayerRemoving:Connect(function(p: Player)
					if p ~= plr then
						return
					end

					LeaveConn:Disconnect()
					if KillerValue and KillerValue.Value then
						if not char:GetAttribute("Dead") then
                			Network:FireClientConnection(KillerValue.Value, "KilledPlayer", "REMOTE_EVENT", plr)
                			Network:FireConnection("KilledPlayer", KillerValue.Value, plr)
						end

            	    	CommonFunctions:GrantRewardToPlayer(KillerValue.Value, 7, 20, "making a Survivor ragequit")

						--i'm leaving this because it's funny to have double the extra time when someone ragequits lol -Dyscarn
						TimeManager:SetTime(TimeManager.CurrentTime + 35)
					end
				end)
			end

        	char.Humanoid.Died:Connect(function()
				char:SetAttribute("Dead", true)

				if LeaveConn then
					LeaveConn:Disconnect()
				end

				if KillerValue and KillerValue.Value then
                	Network:FireClientConnection(KillerValue.Value, "KilledPlayer", "REMOTE_EVENT", plr)
                	Network:FireConnection("KilledPlayer", KillerValue.Value, plr)

					CommonFunctions:UpdatePlayerStat(KillerValue.Value, "KillerStats.Kills", 1)
                	CommonFunctions:GrantRewardToPlayer(KillerValue.Value, 20, 60, "killing a Survivor")

					TimeManager:SetTime(TimeManager.CurrentTime + 35)
				end
				
        	    threads[plr.UserId] = task.delay(3, function()
        	        plr:LoadCharacter()
        	        threads[plr.UserId] = nil
        	    end)
        	end)
		end)

		task.delay(2, function()
			plr:LoadCharacter()
		end)
		
		task.spawn(function()
			local TimePlayed = Utils:FindFirstChild(plr, "PlayerData.Stats.General.TimePlayed")
			TimePlayedThreads[plr.UserId] = RunService.Heartbeat:Connect(function(delta: number)
				TimePlayed.Value += delta
			end)
		end)
	end)

	Network:SetConnection("AddLoadedPlayer", "REMOTE_EVENT", function(plr: Player)
		if not Folder:FindFirstChild(plr.Name) then
			local Value = Instance.new("ObjectValue")
			Value.Name = plr.Name
			Value.Value = plr
			Value.Parent = Folder
		end
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		if Folder:FindFirstChild(plr.Name) then
			Folder[plr.Name]:Destroy()
		end

		if TimePlayedThreads[plr.UserId] then
			TimePlayedThreads[plr.UserId]:Disconnect()
		end
	end)

    Network:SetConnection("CancelAutoRespawn", "REMOTE_EVENT", function(plr: Player)
        self:CancelAutoRespawn(plr)
    end)
end

--- Cancels a player's automatic respawn if they died.
function PlayerManager:CancelAutoRespawn(plr: Player)
    if threads[plr.UserId] then
        task.cancel(threads[plr.UserId])
        threads[plr.UserId] = nil
    end
end

--- Internal: Creates all hitboxes available for a character.
function PlayerManager:_SetupHitboxes(Character)
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local HitboxFolder = Instance.new("Folder")
	HitboxFolder.Name = "Hitboxes"
	HitboxFolder.Parent = Character

	for _, hitbox in Hitboxes:GetChildren() do
		local Weld = Instance.new("Weld")
		Weld.Name = hitbox.Name
		Weld.Parent = HumanoidRootPart
		local h = hitbox:Clone()
		h.Parent = HitboxFolder
		h.CFrame = HumanoidRootPart.CFrame
		Weld.Part0 = HumanoidRootPart
		Weld.Part1 = h
		Weld.C0 *= CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
	end

	Character.Humanoid.Died:Connect(function()
		for _, i in HitboxFolder:GetDescendants() do
			i:Destroy()
		end
		HitboxFolder:Destroy()
	end)
end

--- Internal: Respawns a player with a possibility to add a custom character rig from `ServerStorage.Assets.Characters`.
function PlayerManager:_RespawnPlayer(plr: Player, RigName: string?, RigType: "Killer"? | "Survivor"?, skinName: string?) --: Model
	self:CancelAutoRespawn(plr)
	if plr.Character then
		plr.Character:Destroy()
	end

	--loads the default char if there's none to load already
	if not RigName or not RigType then
		plr:LoadCharacter()
		return plr.Character
	end

	local char

	--gets the skin if queued to
	if skinName ~= nil and #skinName > 0 then
		char = Utils:FindFirstChild(CharFolder.Skins[RigType], RigName.."."..skinName, false)
	end

	--if there's a skin then it gets cloned and used
	if char then
		char = char:Clone()
		char:SetAttribute("CharacterSkinName", skinName)
	--if not it just gets the default one for the character
	else
		char = CharFolder[RigType][RigName]:Clone()
	end
	char:SetAttribute("CharacterName", RigName)

	char.Name = plr.Name
	
	plr.Character = char
	
	--clones all scripts
	for _, i in StarterCharacterScripts:GetChildren() do
		i:Clone().Parent = char
	end

	--creates the role before `PlayerManager` can create it with the Spectator value
	local Role = Instance.new("StringValue")
	Role.Name = "Role"
	Role.Value = RigType
	Role.Parent = char

	--adds the char to `Players` in `workspace`
	char.Parent = PlayerFolder

	--failsafe
	self:CancelAutoRespawn(plr)

	Network:FireAllClientConnection("SetupLocalRagdoll", "REMOTE_EVENT", plr)

	return char
end

return PlayerManager
