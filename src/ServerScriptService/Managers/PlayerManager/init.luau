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

local Hitboxes = ServerStorage.Assets.Hitboxes

local StarterCharacterScripts = game:GetService("StarterPlayer").StarterCharacterScripts
local PlayerFolder = workspace.Players

local StunSPPrefab = Utils.Instance.FindFirstChild(script, "StunSpawnProtection")

function PlayerManager:Init()
	local TimePlayedThreads = {}

	ReplicatedStorage.PlaceVersion.Value = game.PlaceVersion

	if #game.PrivateServerId > 0 then
		table.insert(CommonFunctions.AdminPerms, {
			Name = Players:GetPlayerByUserId(game.PrivateServerOwnerId).Name,
			UserId = game.PrivateServerOwnerId,
			Rank = "ServerOwner",
		})
	end

	Network:SetConnection("AddLoadedPlayer", "REMOTE_EVENT", function(plr: Player)
		PlayerManager.OnPlayerLoad(plr)
	end)

	Utils.Player.ObservePlayers(function(plr: Player)
		if RunService:IsStudio() then
			table.insert(CommonFunctions.AdminPerms, {
				Name = plr.Name,
				UserId = plr.UserId,
				Rank = "Owner",
			})
		end

		Utils.Character.ObserveCharacter(plr, function(char)
			task.spawn(function()
				require(char:FindFirstChild("Server"):FindFirstChild("ScriptInitter")):Init()
			end)

			AntiFly:_SetupCharacter(plr, char)
			
			local Role = char:FindFirstChild("Role")

			if char:GetAttribute("BaseSpeed") == nil then
				char:SetAttribute("BaseSpeed", 10.5)
			end

			char.Parent = PlayerFolder
			
			local Humanoid = char:FindFirstChildWhichIsA("Humanoid")
        	Humanoid.BreakJointsOnDeath = false

			local KillerValue
			if Role.Value ~= "Spectator" then
				PlayerManager._SetupHitboxes(char)

				local CollisionGroup = Role.Value

				for _, Part in char:GetDescendants() do
					if not Part:IsA("BasePart") or Part:IsDescendantOf(char.Hitboxes) then
						continue
					end
					
					Part.CollisionGroup = CollisionGroup
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
					local HRP = Utils.Character.GetRootPart(char)
					local StunSP = StunSPPrefab:Clone()
					StunSP.Parent = HRP
					local Weld = Instance.new("Weld")
					Weld.Name = "StunProtectionWeld"
					Weld.Parent = HRP
					Weld.Part0 = HRP
					Weld.Part1 = StunSP
				end
			else
				for _, Part in char:GetDescendants() do
					if not Part:IsA("BasePart") then
						continue
					end
					
					Part.CollisionGroup = "Spectator"
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

            	    	CommonFunctions.GrantRewardToPlayer(KillerValue.Value, {Money = 7, EXP = 20, Reason = "making a Survivor ragequit"})

						--i'm leaving this because it's funny to have double the extra time when someone ragequits lol -Dyscarn
						TimeManager:SetTime(TimeManager.CurrentTime + 35)
					end
				end)
			end

			Utils.Character.ObserveOnDeath(Humanoid, function()
				char:SetAttribute("Dead", true)

				if LeaveConn then
					LeaveConn:Disconnect()
				end

				if KillerValue and KillerValue.Value then
                	Network:FireClientConnection(KillerValue.Value, "KilledPlayer", "REMOTE_EVENT", plr)
                	Network:FireConnection("KilledPlayer", KillerValue.Value, plr)

					CommonFunctions.UpdatePlayerStat(KillerValue.Value, "KillerStats.Kills", 1)
                	CommonFunctions.GrantRewardToPlayer(KillerValue.Value, {Money = 20, EXP = 60, Reason = "killing a Survivor"})

					TimeManager:SetTime(TimeManager.CurrentTime + 35)
				end
				
        	    threads[plr.UserId] = task.delay(3, function()
					PlayerManager._RespawnPlayer(plr)
        	        threads[plr.UserId] = nil
        	    end)
        	end)
		end)

		task.delay(2, function()
			PlayerManager._RespawnPlayer(plr)
		end)
		
		task.defer(function()
			--saving this before hand just in case there's a leave
			local name = plr.NameDisplayDistance
			local TimePlayed = Utils.Instance.FindFirstChild(plr, "PlayerData.Stats.General.TimePlayed", 10)
			if not TimePlayed then
				warn("[PlayerManager:Init()] TimePlayed not found for player "..name.."!")
				return
			end
			TimePlayedThreads[plr.UserId] = RunService.Heartbeat:Connect(function(delta: number)
				TimePlayed.Value += delta
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(plr: Player)
		if ReplicatedStorage.LoadedPlayers:FindFirstChild(plr.Name) then
			ReplicatedStorage.LoadedPlayers[plr.Name]:Destroy()
		end

		if TimePlayedThreads[plr.UserId] then
			TimePlayedThreads[plr.UserId]:Disconnect()
		end
	end)

    Network:SetConnection("CancelAutoRespawn", "REMOTE_EVENT", function(plr: Player)
        PlayerManager.CancelAutoRespawn(plr)
    end)
end

--- Cancels a player's automatic respawn if they died.
function PlayerManager.CancelAutoRespawn(plr: Player)
    if threads[plr.UserId] then
		pcall(function()
        	task.cancel(threads[plr.UserId])
        	threads[plr.UserId] = nil
		end)
    end
end

--- Internal: Creates all hitboxes available for a character.
function PlayerManager._SetupHitboxes(Character: Model)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	local HumanoidRootPart = Utils.Character.GetRootPart(Character)
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

	Utils.Character.ObserveOnDeath(Humanoid, function()
		for _, Descendant in HitboxFolder:GetDescendants() do
			Descendant:Destroy()
		end
		HitboxFolder:Destroy()
	end)
end

--- Internal: Respawns a player with a possibility to add a custom character rig from `ServerStorage.Assets.Characters`.
function PlayerManager._RespawnPlayer(plr: Player, RigName: string?, RigType: ("Killer" | "Survivor")?, skinName: string?) --: Model
	PlayerManager.CancelAutoRespawn(plr)
	if plr.Character then
		plr.Character:Destroy()
	end

	local function LoadEmpty()
		plr:LoadCharacterAsync()

		--creates the role asap
		local Role = Instance.new("StringValue")
		Role.Name = "Role"
		Role.Value = "Spectator"
		Role.Parent = plr.Character

		return plr.Character
	end

	--loads the default char if there's none to load already
	if not RigName or not RigType then
		return LoadEmpty()
	end

	local char

	local function FindChar(Service: "ServerStorage" | "ReplicatedStorage", Name: string, Type: ("Killer" | "Survivor")?, Skin: string?)
		--gets the skin if queued to
		if Skin ~= nil and #Skin > 0 then
			char = Utils.Instance.FindFirstChild(game:GetService(Service).Assets.Characters.Skins[RigType], RigName.."."..Skin, false)
		end

		--if there's a skin then it gets cloned and used
		if char then
			char = char:Clone()
			char:SetAttribute("CharacterSkinName", Skin)
			return
		end

		--if not it just gets the default one for the character
		char = game:GetService(Service).Assets.Characters[RigType][RigName]:Clone()

		if not char then
			if Service == "ReplicatedStorage" then
				FindChar("ServerStorage", Name, Type, Skin)
				return
			end
			
			plr:LoadCharacterAsync()
			return
		end

		char = char:Clone()
	end
	FindChar("ReplicatedStorage", RigName, RigType, skinName)

	if not char then
		warn("[PlayerManager._RespawnPlayer()]: Can't find character rig! Loading player character instead...")
		warn(debug.traceback())

		return LoadEmpty()
	end
	
	char:SetAttribute("CharacterName", RigName)

	char.Name = plr.Name

	--creates the role asap
	local Role = Instance.new("StringValue")
	Role.Name = "Role"
	Role.Value = RigType
	Role.Parent = char
	
	char:PivotTo(plr.Character and plr.Character.WorldPivot or CFrame.new(0, 10, 0))
	
	plr.Character = char
	
	--clones all scripts
	for _, Child in StarterCharacterScripts:GetChildren() do
		Child:Clone().Parent = char
	end

	--adds the char to `Players` in `workspace`
	char.Parent = PlayerFolder

	--failsafe
	PlayerManager.CancelAutoRespawn(plr)

	Network:FireAllClientConnection("SetupLocalRagdoll", "REMOTE_EVENT", plr)

	return char
end

function PlayerManager._AttemptWelcomeAchievementGranting(Player: Player)
	if not Player:IsA("Player") then
		return
	end

	if not RunService:IsStudio() then
		task.defer(CommonFunctions.CompleteAchievement, Player, "General.Welcome")
	end
end

function PlayerManager.OnPlayerLoad(Player: Player)
	PlayerManager._AttemptWelcomeAchievementGranting(Player)

	task.wait(3)

	if Player then
		if not ReplicatedStorage.LoadedPlayers:FindFirstChild(Player.Name) then
			local Value = Instance.new("ObjectValue")
			Value.Name = Player.Name
			Value.Value = Player
			Value.Parent = ReplicatedStorage.LoadedPlayers
		end

		local Log = Utils.Instance.FindFirstChild(Player, "PlayerData.Misc.LastSeenLog")
		Log.Value = game.PlaceVersion
	end
end

return PlayerManager
