local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Utils = require(ReplicatedStorage.Modules.Utils)

local SaveManager = {
	PlayerDatas = {},
	PlayerLeaderstatConns = {},
}

local Storage
local Attempt = 0

-- Will retry retrieving data again and again until it finally succeeds. Datastores are too unreliable to be one-and-done, and may otherwise corrupt data.
repeat 
    Attempt += 1

    _, Storage = pcall(function()
        return DataStoreService:GetDataStore("DriftwoodThing") -- PLACE YOUR DATASTORE HERE
    end)
until Storage or Attempt > 50

local StoreKey = "driftwooding77" -- PLACE YOUR DATASTORE KEY HERE

--- Organizes a hiearchy of instances and valueobjects into a table
local function ConvertInstanceTreeToTable(TargetInstance: Instance, Depth: number?): ({[string]: {any}}) -- Can return a table of string-value pairs which can be arbitrarily deep, dont quite know how to define that for the typechecker, so just do your best (as always!).

	local tree = {}

    -- A cap for maximum allowed depth– leaving it arbitrary feels like a recipe for disaster 
    if not Depth then 
        Depth = 0
        else
        Depth += 1
    end

    -- Iterate through all of the instance's children
	for _index, value in ipairs(TargetInstance:GetChildren()) do

        -- If the child is a folder, run this function again on it to create another nest.
		if value:IsA("Folder") and Depth < 50 then -- Customize the depth cap as you please. Realistically, nothing will ever go this deep, but you can never be too sure...

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

    --- Initial wave of setting up playerdata, fired on an individual player when they join the game.
	local function LoadPlayer(Player: Player)

        -- Grab the player's data from the datastore, place it into a table for later use 
		self.PlayerDatas[Player.UserId] = self:Load(Player)
        local ThisPlayerData = self.PlayerDatas[Player.UserId] -- Gets its own variable to make things easier to read. Done in this way so this variable points to the entry in the table and not to the data itself.

        -- Go through all achievements, set them up in folders for the player in question.
		for AchievementGroupCodeName, AchievementGroup in Achievements do

            -- If the specific achievement group doesnt exist, make it.
			if not ThisPlayerData.Achievements:FindFirstChild(AchievementGroupCodeName) then

				local Group = Instance.new("Folder")
				Group.Name = AchievementGroupCodeName
				Group.Parent = ThisPlayerData.Achievements

			end

            -- Go by achievement group, check for achievement-tracking valueobjects.
			for AchievementCodeName, Achievement in AchievementGroup do

                -- If the valueobject for tracking this achievement's progress doesn't exist, make it.
				if Achievement.Requirement and not ThisPlayerData.Achievements[AchievementGroupCodeName]:FindFirstChild(AchievementCodeName) then

					local AchievementProgress = Instance.new("NumberValue")
					AchievementProgress.Name = AchievementCodeName
					AchievementProgress.Value = 0
					AchievementProgress.Parent = ThisPlayerData

				end

			end

		end
	end

    -- Load a player's data when they join, and additionally retrieve and load all players that may have been in the game before this runs. Feels like that'd be rare, but I suppose one never knows...
	Players.PlayerAdded:Connect(LoadPlayer)
	for _, i in Players:GetPlayers() do
		LoadPlayer(i)
	end

    -- Save a player's data when they leave the game.
	Players.PlayerRemoving:Connect(function(Player: Player)
		if self.PlayerLeaderstatConns[Player.UserId] then
			self.PlayerLeaderstatConns[Player.UserId]:Disconnect()
		end
		self:Save(Player, self.PlayerDatas[Player.UserId])
	end)

    -- Mark some global saving code to be run if the server gets manually closed for one reason or another.
	game:BindToClose(function()
		for _, i in Players:GetPlayers() do
			self:Save(i, self.PlayerDatas[i.UserId])
		end
	end)

end

--- Sets up a display leaderstat folder for any data that has the `DisplayInLeaderstats` attribute.
function SaveManager:_SetupLeaderStats(DataFolder, parent) --just for display, won't save
	for _, data in DataFolder:GetDescendants() do
		if data:IsA("ValueBase") and data:GetAttribute("DisplayInLeaderstats") then
			local LeaderStat = Instance.new("IntValue")
			LeaderStat.Name = data.Name
			LeaderStat.Value = data.Value
			LeaderStat.Parent = parent

			self.PlayerLeaderstatConns[DataFolder.Parent.UserId] = data.Changed:Connect(function()
				if LeaderStat then
					LeaderStat.Value = data.Value
				end
			end)
		end

	end
end

--- Attempt to validate save data and/or salvage it if needed.
function SaveManager:_CheckSaveIntegrity(DataFolder, parent)
    -- If the player has an emote that doesn't exist, destroy it.
	for _index, emote in DataFolder.Equipped.Emotes:GetChildren() do
		if Utils:GetEmoteModule(emote.Name) == nil then
			emote:Destroy()
		end
	end

    -- If the player has a skin that doesn't exist for neither killers nor survivors, wipe it.
	for _index, skin in DataFolder.Equipped.Skins:GetChildren() do
		if Utils:GetCharacterModule("Killer", skin.Name, skin.Value) == nil and Utils:GetCharacterModule("Survivor", skin.Name, skin.Value) == nil then
			skin:Destroy()
		end
	end

    -- Retrieve currently equipped killer and survivor
	local EquippedKiller = DataFolder.Equipped.Killer
	local EquippedSurvivor = DataFolder.Equipped.Survivor

    -- If the player has an invalid killer equipped, restore it to a default(?).
	if not Utils:GetCharacterModule("Killer", EquippedKiller.Value) then
		EquippedKiller.Value = script.PlayerData.Equipped.Killer
	end

    -- If the player has an invalid survivor equipped, restore it to a default(?).
	if not Utils:GetCharacterModule("Survivor", EquippedSurvivor.Value) then
		EquippedSurvivor.Value = script.PlayerData.Equipped.Survivor
	end

    -- If the player somehow has an invalid survivor or killer level for their purchased survivors or killers, wipe it.
	for _killer, level in DataFolder.Purchased.Killers:GetChildren() do
		if Utils:GetCharacterModule("Killer", level.Name) == nil then
			level:Destroy()
		end
	end
	for _survivor, level in DataFolder.Purchased.Survivors:GetChildren() do
		if Utils:GetCharacterModule("Survivor", level.Name) == nil then
			level:Destroy()
		end
	end

    -- If the player has invalid skins, destroy them.
	for index, skin in DataFolder.Purchased.Skins:GetChildren() do

        -- Check if the skin is for survivors or killers.
		local IsSurvivor = Utils:GetCharacterModule("Survivor", skin.Name) ~= nil

		if not IsSurvivor then
            -- If its a killer skin that doesn't exist, destroy it and go to the next one in line.
			if Utils:GetCharacterModule("Killer", skin.Name) == nil then
				skin:Destroy()
				continue
			end
		end

        -- Otherwise do a broader search(?); if it still doesn't exist, destroy it and go to the next one in line.
		for index, value in skin:GetChildren() do
			if Utils:GetCharacterModule(if IsSurvivor then "Survivor" else "Killer", skin.Name, value.Name) == nil then -- "I didn't even know you could do that with conditions. Wow." – Itred
				value:Destroy()
				continue
			end
		end

	end
end

--- Loads a player's savedata and generates a heirarchy of folders and valuebase objects for storing, reading, and writing to and from it in-game.
function SaveManager:Load(Player: Player): Folder
    -- Retrieve playerdata
    local PlayerData
    if Storage then
        -- Try retrieving data again and again until something is sent back, as datastores arent always reliable.

        local Attempt = 0
        repeat
            Attempt += 1

            pcall(function() 
                PlayerData = Storage:GetAsync(`{StoreKey}_{Player.UserId}`)
            end)
        until PlayerData or Attempt > 50 

    else    
        warn("[ServerScriptService/Managers/SaveManager:Load()]: WARNING – ENTIRE DATASTORE failed to load. Handling player data from here is extremely hazardous. Here be dragons!")
    end

	local ClonedData = script.PlayerData:Clone()

	local Leaderstats = Instance.new("Folder")
	Leaderstats.Name = "leaderstats"

    -- If we're able to properly retrieve the data, parse through it and make valueobjects for expressing it in-game.
	if PlayerData then

		if not PlayerData.Achievements then
			-- self:_CheckSaveIntegrity(ClonedData)
			ClonedData.Parent = Player
			self:_SetupLeaderStats(ClonedData, Leaderstats)
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
			if Utils:GetEmoteModule(emotename) == nil then
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
				Utils:GetCharacterModule("Killer", skinname, skin) == nil
				and Utils:GetCharacterModule("Survivor", skinname, skin) == nil
			then
				continue
			end

			local V = Instance.new("StringValue")
			V.Name = skinname
			V.Value = skin
			V.Parent = ClonedData.Equipped.Skins
		end

        -- Find their equipped killer and survivor
		ClonedData.Equipped.Killer.Value = Utils:GetCharacterModule("Killer", PlayerData.Equipped.Killer) ~= nil and PlayerData.Equipped.Killer or ""
        ClonedData.Equipped.Survivor.Value = Utils:GetCharacterModule("Survivor", PlayerData.Equipped.Survivor) ~= nil and PlayerData.Equipped.Survivor or ""

        -- Not sure what this does, likely to do with the update log appearing.
		ClonedData.Misc.LastSeenLog.Value = PlayerData.Misc.LastSeenLog


        -- Finally, make valueobjects for all purchased emotes,
		for emotename, emotedata in PlayerData.Purchased.Emotes do
            
            -- If the emote doesn't exist, skip it for now. It'll likely cleaned up later.
			if not Utils:GetEmoteModule(emotename) then
				continue
			end

			local int = Instance.new("IntValue")
			int.Parent = ClonedData.Purchased.Emotes
			int.Name = emotename
		end

        -- killers,
		for killer, level in PlayerData.Purchased.Killers do

            -- If the killer doesn't exist, skip it for now. It'll also likely be cleaned up later.
			if Utils:GetCharacterModule("Killer", killer) == nil then
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
			if Utils:GetCharacterModule("Survivor", survivor) == nil then
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
		for skinname, skindata in PlayerData.Purchased.Skins do

            -- Check whether its a survivor or killer skin
			local IsSurvivor = Utils:GetCharacterModule("Survivor", skinname) ~= nil

			if not IsSurvivor then
				if Utils:GetCharacterModule("Killer", skinname) == nil then
					continue
				end
			end

			local Folder = Instance.new("Folder")
			Folder.Name = skinname
			Folder.Parent = ClonedData.Purchased.Skins

			for index, value in skindata do

				if Utils:GetCharacterModule(if IsSurvivor then "Survivor" else "Killer", skinname, index) == nil then
					continue
				end

				local int = Instance.new("IntValue")
				int.Parent = Folder
				int.Name = index
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
	-- self:_CheckCheckSaveIntegrity(ClonedData)

    -- Finally, nest all these instances neatly in the player for easy reference.
	ClonedData.Parent = Player
	self:_SetupLeaderStats(ClonedData, Leaderstats)
	Leaderstats.Parent = Player

	return ClonedData
end


--- Saves a given player's data.
function SaveManager:Save(Player: Player, Data: Folder)
	local SaveFile = ConvertInstanceTreeToTable(Data)

	--i just figured out pairs and ipairs are fucking useless as generalized iteration had been implemented fairly long ago. 
	--i want to die.

    -- "Oh, thats good to know, actually." – Itred

    -- Grab the currently equipped killer and survivor.
	for target, equipped in { Killer = SaveFile.Equipped.Killer, Survivor = SaveFile.Equipped.Survivor } do

		local Module = Utils:GetCharacterModule(target, equipped)

		if not Module or Module:HasTag("PreventSave") then
			SaveFile["Equipped"][target] = script:FindFirstChild("Equipped"):FindFirstChild(target).Value --if it's smth like a dev item it doesn't save in publics
		end

	end

    -- Give a readout if needed.
	if workspace:GetAttribute("DebugAllowed") then
		print("Saving data for: " .. Player.Name, SaveFile)
	end

    -- Give storing data a few tries until it goes through, as datastores are too unreliable to be one-and-done.
    local success
    local Attempt = 0
    repeat 
        Attempt += 1

        success, _ = pcall(function()
            Storage:UpdateAsync(`{StoreKey}_{Player.UserId}`, function(_old)
                return SaveFile
            end)
        end)
    
    until success or Attempt > 99

    -- Some kind of handling for if the player's data cant be saved would be epic, to prevent total corruption of savedata. Attempt cap is high to try and mitigate this, but it'd still be good practice.
	-- i believe that if it fails, the previous data remains so it doesn't get corrupted; i'll be unmarking this as a todo but correct me if i'm wrong

end

return SaveManager
