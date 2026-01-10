local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeItemGrantingManager = require(script.BadgeItemGrantingManager)
local DevItemGrantingManager = require(script.DevItemGrantingManager)
local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Utils = require(ReplicatedStorage.Modules.Utils)


-- The module has two tables inherently:
--	PlayerDatas holds the unmodified tables that are grabbed from the datastore and turned into a tree of valueobjects. 
-- 	PlayerLeaderstatConns holds references to the event listeners watching over certain stats that are tracked by the leaderboard, so they can be disconnected when the player leaves, to avoid a memory leak.
local SaveManager = {
	PlayerDatas = {},
	PlayerLeaderstatConns = {},
}


local Storage
local Attempt = 0

-- An attempt to fix constantly having to go back to this script and re-set your datastore name and key whenever the SaveManager updates.
-- These objects are parented to the SaveManager script. Place your datastore name and key in them, and it should never require you to go back and set them again, since those objects will not be updated as frequently as this script here.
-- If Rojo is being used, the values for these objects MUST be changed by going into their .model.json files adjacent to this script.
-- If not, then they can just be changed through Studio in this script's children.
local DataStoreHolder = script:FindFirstChild("DataStoreRef")
local DataStoreKeyHolder = script:FindFirstChild("DataStoreKey")

local DataStoreRef = DataStoreHolder.Value 
if not DataStoreRef or DataStoreRef == "DATA_STORE_NAME_HERE" then
	warn("\n[SaveManager] – WARNING: Datastore name not set!"
		.."\nPlace the name of your datastore in ServerScriptService/Managers/SaveManager/DataStoreRef in Roblox Studio, or in src/ServerScriptService/Managers/SaveManager/DataStoreRef.model.json in Visual Studio Code."
		.."\nYou should only need to do this once – if this happens frequently, contact a Dysymmetrical developer.")
	DataStoreRef = "Dysymmetrical" -- Dysymmetrical default datastore for testing purposes.
end

local DataStoreKey = DataStoreKeyHolder.Value
if not DataStoreKey or DataStoreKey == "DATA_STORE_KEY_HERE" then
	warn("\n[SaveManager] – WARNING: Key for datastore '"..DataStoreRef.."' not set!"
		.."\nMake sure you have the key of your datastore in ServerScriptService/Managers/SaveManager/DataStoreKey in Roblox Studio, or in src/ServerScriptService/Managers/SaveManager/DataStoreKey.model.json in Visual Studio Code."
		.."\nHopefully, you should only need to do this once – if this message appears frequently, contact a Dysymmetrical developer.")
	DataStoreKey = "dysymmetrical" -- Dysymmetrical default datastore for testing purposes.
end


-- Will retry retrieving data again and again until it finally succeeds. Datastores are too unreliable to be one-and-done, and may otherwise corrupt data.
-- We don't want to defer this– if files are attempted to be grabbed from the datastore before the datastore loads... That'll be, ah, not good.
repeat 
	Attempt += 1

	_, Storage = pcall(function()
		return DataStoreService:GetDataStore(DataStoreRef) 
	end)
until Storage or Attempt > 50 

--[[
	Function for converting a ValueObject tree into a table.

	Used to turn the valueobjects used to store playerdata into a format we can save to the datastore.

	Eventually, this will probably be made two-way, and more functionality may be added to it.
]]--
local function ConvertInstanceTreeToTable(TargetInstance: Instance, Depth: number?): ({[string]: {any}}) -- Can return a table of string-value pairs which can be arbitrarily deep, dont quite know how to define that for the typechecker, so just do your best (as always!).

	local tree = {}

	-- A cap for maximum allowed depth– leaving it arbitrary feels like a recipe for disaster 
	Depth = (Depth or -1) + 1

	-- Iterate through all of the instance's children
	for _index, value in ipairs(TargetInstance:GetChildren()) do

		-- If the child is a folder, run this function again on it to create another nest.
		if value:IsA("Folder") and Depth < 50 then -- Customize the depth cap as you please. Realistically, nothing will ever go this deep, but to avoid a permanant hang or an infinite loop, you can never be too sure...

			tree[value.Name] = ConvertInstanceTreeToTable(value, Depth)

			-- If the child is a valueobject, grab its value and add it to the table.
		elseif value:IsA("ValueBase") then
			tree[value.Name] = value.Value
		end

	end

	-- Return the completed table to whatever called the function.
	return tree
end



--- Sets up save data handlers, listens for players joining and leaving to read, write, retrieve, and store save data.
function SaveManager:Init()

	-- Validate the default values for playerdata, and make sure they point to killers/survivors that exist. If killers/survivors are moved and this isn't updated, new players could otherwise get an invalid killer/survivor, and become softlocked.
	-- We *want* the game to hang for a bit to check these, since new players wont be able to join the game if it's malformed.

	-- First, check to make sure the valueobjects which these would be stored in exist.

	local Playerdata = script:FindFirstChild("PlayerData")

	-- Quickly flip through and make sure the valueobjects we need exist. Eventually may create them on its own, to make things easier.
	if not (
			Playerdata
			and Playerdata:FindFirstChild("Equipped")
			and Playerdata.Equipped:FindFirstChild("Killer")
			and Playerdata.Equipped:FindFirstChild("Survivor")
			and Playerdata:FindFirstChild("Purchased") and
			Playerdata.Purchased:FindFirstChild("Killers")
			and Playerdata.Purchased:FindFirstChild("Skins")
			and Playerdata.Purchased:FindFirstChild("Survivors")
			and Playerdata:FindFirstChild("Achievements")
		) then

		error("[SaveManager:Init()] – ERROR: Default playerdata may be missing important pieces, or entirely absent! Check for a folder in ServerScriptService/Managers/SaveManager/PlayerData. If you know what you're doing, you can silence this message in ServerScriptService/Managers/SaveManager.")
	end

	for AchievementGroup, _ in Achievements do
		local GroupFolder = Instance.new("Folder")
		GroupFolder.Name = AchievementGroup
		GroupFolder.Parent = Playerdata.Achievements
	end

	local EquippedFolder = Playerdata.Equipped
	local PurchasedFolder = Playerdata.Purchased

	-- Check if the listed default killer still exists
	local DefaultKiller = EquippedFolder.Killer.Value
	local KillerModule = Utils.Instance.GetCharacterModule("Killer", DefaultKiller, nil, false)

	-- If the default killer points to a killer who doesn't exist anymore, grab the first one the game can find and use that as the default instead.
	if not KillerModule then

		local AllKillers = ReplicatedStorage:FindFirstChild("Characters"):FindFirstChild("Killers"):GetChildren()

		-- Set the default equipped killer to the first killer found in this list as a temporary, non-error-prone solution. This can be changed by the user to another killer, and the game wont try to do this again unless the killer this value points to doesn't exist again.
		EquippedFolder.Killer.Value = AllKillers[1].Name

		-- "This could technically error if no killers are found, but if such is the case, I think the developer has bigger errors to worry about, so I think its fine to leave it as-is" – Itred

		warn("[SaveManager:Init()] – INFO: Default (template) playerdata points to a killer which no longer exists. Substituting with '"..AllKillers[1].Name.."' for now. \nModify the value in 'ServerScriptService/Managers/SaveManager/PlayerData/Equipped/Killer' if you wish to set a different default killer.")

	end


	-- Check if the listed default survivors still exists
	local DefaultSurvivor = EquippedFolder.Survivor.Value
	local SurvivorModule = Utils.Instance.GetCharacterModule("Survivor", DefaultSurvivor, nil, false)

	-- Same deal for survivors– If the default survivor points to one whom doesn't exist anymore, grab the first one the game can find and use that as the default instead.
	if not SurvivorModule then

		local AllSurvivors = ReplicatedStorage:FindFirstChild("Characters"):FindFirstChild("Survivors"):GetChildren()

		-- Similarly, set the default equipped survivor to the first survivor found in this list as a temporary, non-error-prone solution. This can be changed by the user to another survivor, and the game wont try to do this again unless the survivor this value points to doesn't exist again.
		EquippedFolder.Survivor.Value = AllSurvivors[1].Name

		-- "This, too, could technically error if no survivors are found, but if such is the case, what are you even doing." – Itred

		warn("[SaveManager:Init()] – INFO: Default (template) playerdata points to a survivor which no longer exists. Substituting with '"..AllSurvivors[1].Name.."' for now. \nModify the value in 'ServerScriptService/Managers/SaveManager/PlayerData/Equipped/Survivor' if you wish to set a different default survivor.")

	end


	-- Also check for the default purchased killer/survivor. Note, however, that this will only apply to the template data, so bought killers by players that are to be replaced later will also be unaffected.

	-- Default purchased killers:
	for index, purchasedkiller in PurchasedFolder.Killers:GetChildren() do

		-- Find its module.
		local PurchasedKillerModule = Utils.Instance.GetCharacterModule("Killer", purchasedkiller.Name, nil, false)

		-- If it doesn't exist, set its name to the default killer instead after just one more check.
		if not PurchasedKillerModule then

			-- Check to see if theres already a valueobject tied to the default killer. If there isn't, then assume that the sole default purchased killer should match the default killer.
			if not PurchasedFolder.Killers:FindFirstChild(DefaultKiller) then 

				purchasedkiller.Name = EquippedFolder.Killer.Value -- Re-read from the newly-updated killer value
				warn("[SaveManager:Init()] – INFO: Default (template) purchased killer doesn't exist. Modifying to match default equipped killer... Change this in 'ServerScriptService/Managers/SaveManager/PlayerData/Purchased/Killer' if you wish to set your own default purchased killer.")

			else

				warn("[SaveManager:Init()] – WARNING: More than one default purchased killer pointed to a character which didn't exist! For stability reasons, these will be temporarily destroyed. Check 'ServerScriptService/Managers/SaveManager/PlayerData/Purchased/Killer' to diagonose any issues.")
				purchasedkiller:Destroy()

			end
		end
	end


	-- Default purchased survivors:
	for index, purchasedsurvivor in PurchasedFolder.Survivors:GetChildren() do

		-- Find its module.
		local PurchasedSurvivorModule = Utils.Instance.GetCharacterModule("Survivor", purchasedsurvivor.Name, nil, false)

		-- If it doesn't exist, set its name to the default survivor instead after just one more check.
		if not PurchasedSurvivorModule then

			-- Same deal as with the killer– Check to see if theres already a valueobject tied to the default survivor. If there isn't, then assume that the sole default purchased survivor should match the default survivor.
			if not PurchasedFolder.Survivors:FindFirstChild(DefaultSurvivor) then 

				purchasedsurvivor.Name = EquippedFolder.Survivor.Value -- Re-read from the newly-updated survivor value
				warn("[SaveManager:Init()] – INFO: Default purchased killer doesn't exist. Modifying to match default equipped killer... Change this in 'ServerScriptService/Managers/SaveManager/PlayerData/Purchased/Killer' if you wish to set your own default purchased killer.")

			else

				warn("[SaveManager:Init()] – WARNING: More than one default purchased killer pointed to a character which didn't exist! For stability reasons, these will be temporarily destroyed. Check 'ServerScriptService/Managers/SaveManager/PlayerData/Purchased/Killer' to diagonose any issues.")
				purchasedsurvivor:Destroy()

			end
		end
	end



	-- Watches for players joining the game through a custom version of Players.PlayerAdded. See in Utils.Player for more information.
	Utils.Player.ObservePlayers(function(Player: Player)
		
		-- Go through players in parallel, rather than one-by-one.
		task.defer(function()

			-- Grab the player's data from the datastore, place it into a table for later use 
			SaveManager.PlayerDatas[Player.UserId] = SaveManager.Load(Player)
			local ThisPlayerData = SaveManager.PlayerDatas[Player.UserId] -- Gets its own variable to make things easier to read. Done in this way so this variable points to the entry in the table and not to the data itself.

			-- Go through all achievements, set them up in folders for the player in question.
			for AchievementGroupCodeName, AchievementGroup in Achievements do

				local Group = ThisPlayerData.Achievements:FindFirstChild(AchievementGroupCodeName)

				-- If the specific achievement group doesnt exist, make it.
				if not Group then

					Group = Instance.new("Folder")
					Group.Name = AchievementGroupCodeName
					Group.Parent = ThisPlayerData.Achievements

				end

				-- Go by achievement group, check for achievement-tracking valueobjects.
				for AchievementCodeName, Achievement in AchievementGroup.Achievements do

					if Group:FindFirstChild(AchievementCodeName) then
						continue
					end

					-- If the valueobject for tracking this achievement's progress doesn't exist, make it.
					local AchievementProgress

					if Achievement.Requirement then
						AchievementProgress = Instance.new("NumberValue")
						AchievementProgress.Value = 0
					else
						AchievementProgress = Instance.new("BoolValue")
						AchievementProgress.Value = false
					end

					AchievementProgress.Name = AchievementCodeName
					AchievementProgress.Parent = Group

				end

			end

		end)
		
	end)


	-- Save a player's data when they leave the game.
	Players.PlayerRemoving:Connect(function(Player: Player)
		-- Deferred so it'll save playerdata parallel, instead of doing so one-at-a-time.
		task.defer(function()

			if SaveManager.PlayerLeaderstatConns[Player.UserId] then
				SaveManager.PlayerLeaderstatConns[Player.UserId]:Disconnect()
			end

		end)
		
		SaveManager.Save(Player, SaveManager.PlayerDatas[Player.UserId])
	end)


	-- Mark some global saving code to be run if the server gets manually closed for one reason or another.
	game:BindToClose(function()
		for _, Player in Players:GetPlayers() do

			SaveManager.Save(Player, SaveManager.PlayerDatas[Player.UserId])

		end
	end)

end


--- Sets up folder for any data that has the `DisplayInLeaderstats` attribute, to display them on the leaderboard.
function SaveManager._SetupLeaderStats(DataFolder, parent) -- Uses its own function, so it doesn't save. 

	for _, data in DataFolder:GetDescendants() do

		if data:IsA("ValueBase") and data:GetAttribute("DisplayInLeaderstats") == true then

			local LeaderStat = Instance.new("IntValue")
			LeaderStat.Name = data.Name
			LeaderStat.Value = data.Value
			LeaderStat.Parent = parent

			SaveManager.PlayerLeaderstatConns[DataFolder.Parent.UserId] = data.Changed:Connect(function()
				if LeaderStat then
					LeaderStat.Value = data.Value
				end
			end)
		end

	end
end


--- Loads a player's savedata and generates a heirarchy of folders and valuebase objects for storing, reading, and writing to and from it in-game.
--- 
--- ### DEFER ANY CALLS TO THIS FUNCTION, IT MAY TAKE A WHILE.
function SaveManager.Load(Player: Player): Folder

	-- Retrieve playerdata
	local PlayerData
	if Storage then
		-- Try retrieving data again and again until something is sent back, as datastores arent always reliable.

		local Attempt = 0
		repeat
			Attempt += 1

			pcall(function() 
				PlayerData = Storage:GetAsync(`{DataStoreKey}_{Player.UserId}`)
			end)
			
			task.wait()
		-- do few attempts just in case it's a new player
		until PlayerData or Attempt > 10

	else    
		warn("[SaveManager.Load()]: FATAL ERROR – ENTIRE DATASTORE failed to load. Handling playerdata from here is extremely hazardous. Here be dragons!")
	end

	local ClonedData = script.PlayerData:Clone()

	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"

	-- If we're able to properly retrieve the data, parse through it and make valueobjects for expressing it in-game.
	if PlayerData then

		if not PlayerData.Achievements then
			ClonedData.Parent = Player
			SaveManager._SetupLeaderStats(ClonedData, Leaderstats)
			Leaderstats.Parent = Player

			return ClonedData

		end

		-- Iterate through achievementgroups and achievements
		for index, achievementgroup in PlayerData.Achievements do
			for subindex, achievement in achievementgroup do
				if not ClonedData.Achievements:FindFirstChild(subindex, true) then
					continue 
				end
				ClonedData.Achievements:FindFirstChild(subindex, true).Value = achievement
			end
		end

		-- Iterate through equipped emotes
		for emotename, emote in PlayerData.Equipped.Emotes do
			if Utils.Instance.GetEmoteModule(emote) == nil then
				continue
			end

			local Emote = Instance.new("StringValue")
			Emote.Name = emotename
			Emote.Value = emote
			Emote.Parent = ClonedData.Equipped.Emotes
		end

		-- Iterate through equipped skins
		for skinname, skin in PlayerData.Equipped.Skins do
			if
				Utils.Instance.GetCharacterModule("Killer", skinname, skin, false) == nil
				and Utils.Instance.GetCharacterModule("Survivor", skinname, skin, false) == nil
			then
				continue
			end

			local Value = Instance.new("StringValue")
			Value.Name = skinname
			Value.Value = skin
			Value.Parent = ClonedData.Equipped.Skins
		end

		-- Find their equipped killer and survivor
		ClonedData.Equipped.Killer.Value = Utils.Instance.GetCharacterModule("Killer", PlayerData.Equipped.Killer, nil, false) ~= nil and PlayerData.Equipped.Killer or ""
		ClonedData.Equipped.Survivor.Value = Utils.Instance.GetCharacterModule("Survivor", PlayerData.Equipped.Survivor, nil, false) ~= nil and PlayerData.Equipped.Survivor or ""

		-- Not sure what this does, likely to do with the update log appearing.
		ClonedData.Misc.LastSeenLog.Value = PlayerData.Misc.LastSeenLog


		-- Finally, make valueobjects for all purchased emotes,
		for emotename, emotedata in PlayerData.Purchased.Emotes do

			-- If the emote doesn't exist, skip it for now. It'll likely cleaned up later.
			if not Utils.Instance.GetEmoteModule(emotename) then
				continue
			end

			local int = Instance.new("IntValue")
			int.Parent = ClonedData.Purchased.Emotes
			int.Name = emotename
		end


		-- killers,
		for killer, level in PlayerData.Purchased.Killers do

			-- If the killer doesn't exist, skip it for now. It'll also likely be cleaned up later.
			if Utils.Instance.GetCharacterModule("Killer", killer, nil, false) == nil then
				continue
			end

			local int = Instance.new("IntValue")
			int.Parent = ClonedData.Purchased.Killers
			-- If theres a stored level for the killer, set the object to that value. Otherwise, keep it at 0.
			if level then
				int.Value = level
			end
			int.Name = killer

		end


		-- survivors,
		for survivor, level in PlayerData.Purchased.Survivors do

			-- If the survivor doesn't exist, skip it as well. It'll likely be cleaned up later, too.
			if Utils.Instance.GetCharacterModule("Survivor", survivor, nil, false) == nil then
				continue
			end

			local int = Instance.new("IntValue")
			int.Parent = ClonedData.Purchased.Survivors
			-- If theres a stored level for the survivor, set the object to that value. Otherwise, keep it at 0.
			if level then
				int.Value = level
			end
			int.Name = survivor
		end


		-- skins,
		for rootname, skindata in PlayerData.Purchased.Skins do

			-- Check whether its a survivor or killer skin
			local IsSurvivor = Utils.Instance.GetCharacterModule("Survivor", rootname, nil, false) ~= nil

			if not IsSurvivor then
				if Utils.Instance.GetCharacterModule("Killer", rootname, nil, false) == nil then
					continue
				end
			end

			local Folder = Instance.new("Folder")
			Folder.Name = rootname
			Folder.Parent = ClonedData.Purchased.Skins

			for skinname, value in skindata do

				if Utils.Instance.GetCharacterModule(if IsSurvivor then "Survivor" else "Killer", rootname, skinname, false) == nil then
					continue
				end

				local int = Instance.new("IntValue")
				int.Parent = Folder
				int.Name = skinname
				int.Value = value
			end

		end


		-- applied settings,
		for _index, setting in PlayerData.Settings do

			for settingname, settingdata in setting do
				if not ClonedData.Settings:FindFirstChild(settingname, true) then
					continue --break
				end
				ClonedData.Settings:FindFirstChild(settingname, true).Value = settingdata
			end

		end


		-- and tracked stats.
		for _index, stat in PlayerData.Stats do

			for statname, statvalue in stat do
				if not ClonedData.Stats:FindFirstChild(statname, true) then
					continue --break
				end
				ClonedData.Stats:FindFirstChild(statname, true).Value = statvalue
			end

		end


	end
	-- SaveManager._CheckCheckSaveIntegrity(ClonedData)

	-- Finally, nest all these instances neatly in the player for easy reference.
	ClonedData.Parent = Player
	SaveManager._SetupLeaderStats(ClonedData, Leaderstats)
	Leaderstats.Parent = Player

	DevItemGrantingManager.CheckPlayer(Player, ClonedData)
	BadgeItemGrantingManager.CheckPlayer(Player, PlayerData)

	return ClonedData
end


--okay so somehow deferring it fucks up the whole thing -dys

--- Saves a given player's data.
--- 
--- ### SPAWN ANY CALLS TO THIS FUNCTION, IT MAY TAKE A WHILE.
function SaveManager.Save(Player: Player, Data: Folder)
	task.spawn(function()
		local SaveFile = ConvertInstanceTreeToTable(Data)

		--i just figured out pairs and ipairs are fucking useless as generalized iteration had been implemented fairly long ago. 
		--i want to die. -dys

		-- "Oh, thats good to know, actually." – Itred

		-- fun fact: ipairs is still useful because of it being done in order for numeric tables! yippee!!!
		-- seriorusly though, remove pairs. -dys

		-- Grab the currently equipped killer and survivor.
		for target, equipped in { Killer = SaveFile.Equipped.Killer, Survivor = SaveFile.Equipped.Survivor } do

			local Module = Utils.Instance.GetCharacterModule(target, equipped, nil, false)

			if not Module or Module:HasTag("PreventSave") then
				SaveFile["Equipped"][target] = script:FindFirstChild("Equipped"):FindFirstChild(target).Value --if it's smth like a dev item it doesn't save in publics
			end

		end

		-- Give a readout if needed.
		if workspace:GetAttribute("DebugAllowed") == true then
			print("Saving data for: " .. Player.Name, SaveFile)
		end

		-- Give storing data a few tries until it goes through, as datastores are too unreliable to be one-and-done.
		local success
		local Attempt = 0
		repeat 
			Attempt += 1

			success, _ = pcall(function()
				Storage:UpdateAsync(`{DataStoreKey}_{Player.UserId}`, function(_old)
					return SaveFile
				end)
			end)

		until success or Attempt > 99

		-- Some kind of handling for if the player's data cant be saved would be epic, to prevent total corruption of savedata. Attempt cap is high to try and mitigate this, but it'd still be good practice.
		-- i believe that if it fails, the previous data remains so it doesn't get corrupted; i'll be unmarking this as a todo but correct me if i'm wrong
	end)
end

return SaveManager
