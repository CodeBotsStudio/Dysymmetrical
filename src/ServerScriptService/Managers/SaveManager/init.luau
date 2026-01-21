local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeItemGranter = require(script.BadgeItemGranter)
local DevItemGranter = require(script.DevItemGranter)
local Achievements = require(ReplicatedStorage.Content.Achievements)
local Utils = require(ReplicatedStorage.Modules.Utils)
local TypeUtils = require(ReplicatedStorage.Modules.Utils.TypeUtils)

local SaveManager = {
	PlayerDatas = {},
	PlayerLeaderstatConns = {},
}

local DataStoreName = script:FindFirstChild("DataStoreName").Value
if DataStoreName == "DATA_STORE_NAME_HERE" then
    warn("[SaveManager] Data store name hasn't been changed! Defaulting to \"Dysymmetrical\"...")
    DataStoreName = "Dysymmetrical"
end

local DataStoreKey = script:FindFirstChild("DataStoreKey").Value
if DataStoreKey == "DATA_STORE_KEY_HERE" then
    warn("[SaveManager] Data store key hasn't been changed! Defaulting to \"dysym\"...")
    DataStoreKey = "dysym"
end

local Storage
do
    local Attempt = 0
    repeat
        Attempt += 1

        --attempt to get the data store
        _, Storage = pcall(function()
            return DataStoreService:GetDataStore(DataStoreName)
        end)
    until Storage or Attempt >= 50 --leave breathing room but stop if it can't be found for any reason in particular
end

function SaveManager:Init()
    SaveManager._CheckPrefabIntegrity()

    Utils.Player.ObservePlayers(function(Player: Player)
        task.defer(function()
            local SaveFile = SaveManager.Load(Player)
			SaveManager.PlayerDatas[Player.UserId] = SaveFile -- Gets its own variable to make things easier to read. Done in this way so this variable points to the entry in the table and not to the data itself.

			-- Go through all achievements, set them up in folders for the player in question.
			for AchievementGroupCodeName, AchievementGroup in Achievements do
				local Group = SaveFile.Achievements:FindFirstChild(AchievementGroupCodeName)

				-- If the specific achievement group doesnt exist, make it.
				if not Group then
					Group = Instance.new("Folder")
					Group.Name = AchievementGroupCodeName
					Group.Parent = SaveFile.Achievements
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

--- INTERNAL: Checks if the current PlayerData prefab is correctly set up and has everything needed to function properly.
function SaveManager._CheckPrefabIntegrity()
    local PlayerDataPrefab = script:FindFirstChild("PlayerData")

    --quick but deep sanity check to know everything is there
    if not (
			    PlayerDataPrefab
			and PlayerDataPrefab:FindFirstChild("Equipped")
			and PlayerDataPrefab.Equipped:FindFirstChild("Killer")
			and PlayerDataPrefab.Equipped:FindFirstChild("Survivor")
			and PlayerDataPrefab:FindFirstChild("Purchased")
            and PlayerDataPrefab.Purchased:FindFirstChild("Killers")
			and PlayerDataPrefab.Purchased:FindFirstChild("Skins")
			and PlayerDataPrefab.Purchased:FindFirstChild("Survivors")
			and PlayerDataPrefab:FindFirstChild("Achievements")
		) then
        
        error("[SaveManager:Init()]: Default playerdata may be missing important pieces, or entirely absent! "..
            "Check for a folder in ServerScriptService/Managers/SaveManager/PlayerData. "
            .."If you know what you're doing, you can silence this message in ServerScriptService/Managers/SaveManager.")
    end

	for AchievementGroup, _ in Achievements do
		local GroupFolder = Instance.new("Folder")
		GroupFolder.Name = AchievementGroup
		GroupFolder.Parent = PlayerDataPrefab.Achievements
	end

    --spawning to get connections set up as fast as possible since none of the warns actually halts the thread
    task.spawn(function()
        local EquippedFolder = PlayerDataPrefab.Equipped
        local PurchasedFolder = PlayerDataPrefab.Purchased

        -- Check if the listed default killer still exists
        local DefaultKiller = EquippedFolder.Killer.Value
        local KillerModule = Utils.Instance.GetCharacterModule("Killer", DefaultKiller, nil, false)

        -- If the default killer points to a killer who doesn't exist anymore, grab the first one the game can find and use that as the default instead.
        if not KillerModule then
            local AllKillers = ReplicatedStorage:FindFirstChild("Content"):FindFirstChild("Characters"):FindFirstChild("Killers"):GetChildren()

            -- Set the default equipped killer to the first killer found in this list as a temporary, non-error-prone solution.
            -- This can be changed by the user to another killer, and the game wont try to do this again unless the killer this value points to doesn't exist again.
            EquippedFolder.Killer.Value = AllKillers[1].Name

            -- "This could technically error if no killers are found, but if such is the case, I think the developer has bigger errors to worry about, so I think its fine to leave it as-is" – Itred

            print("[SaveManager:Init()]: Default (template) playerdata points to a killer which no longer exists. "..
                "Substituting with '"..AllKillers[1].Name.."' for now. \n"..
                "Modify the value in 'ServerScriptService/Managers/SaveManager/PlayerData/Equipped/Killer' if you wish to set a different default killer.")
        end

        -- Check if the listed default survivors still exists
        local DefaultSurvivor = EquippedFolder.Survivor.Value
        local SurvivorModule = Utils.Instance.GetCharacterModule("Survivor", DefaultSurvivor, nil, false)

        -- Same deal for survivors– If the default survivor points to one whom doesn't exist anymore, grab the first one the game can find and use that as the default instead.
        if not SurvivorModule then
            local AllSurvivors = ReplicatedStorage:FindFirstChild("Content"):FindFirstChild("Characters"):FindFirstChild("Survivors"):GetChildren()

            -- Similarly, set the default equipped survivor to the first survivor found in this list as a temporary, non-error-prone solution. This can be changed by the user to another survivor, and the game wont try to do this again unless the survivor this value points to doesn't exist again.
            EquippedFolder.Survivor.Value = AllSurvivors[1].Name

            -- "This, too, could technically error if no survivors are found, but if such is the case, what are you even doing." – Itred

            print("[SaveManager:Init()]: Default (template) playerdata points to a survivor which no longer exists. Substituting with '"..AllSurvivors[1].Name.."' for now. \nModify the value in 'ServerScriptService/Managers/SaveManager/PlayerData/Equipped/Survivor' if you wish to set a different default survivor.")
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
    end)
end

--- INTERNAL: Sets up folder for any data that has the `DisplayInLeaderstats` attribute, to display them on the leaderboard.
function SaveManager._SetupLeaderStats(DataFolder: Folder): Folder -- Uses its own function, so it doesn't save. 
    local Leaderstats = Instance.new("Folder")
    Leaderstats.Name = "leaderstats"

	for _, data in DataFolder:GetDescendants() do
		if data:IsA("ValueBase") and data:GetAttribute("DisplayInLeaderstats") == true then
			local LeaderStat = Instance.new("IntValue")
			LeaderStat.Name = data.Name
			LeaderStat.Value = data.Value
			LeaderStat.Parent = Leaderstats

			SaveManager.PlayerLeaderstatConns[DataFolder.Parent.UserId] = data.Changed:Connect(function()
				if LeaderStat then
					LeaderStat.Value = data.Value
				end
			end)
		end
	end

    return Leaderstats
end

function SaveManager.Load(Player: Player): Folder

	-- Retrieve playerdata
	local PlayerData
	if not Storage then
		warn("[SaveManager.Load()]: ENTIRE DATASTORE failed to load. Handling player data from here is extremely hazardous. Here be dragons!")
	end

    do
		local Attempt = 0
		repeat
			Attempt += 1

			pcall(function() 
				PlayerData = Storage:GetAsync(`{DataStoreKey}_{Player.UserId}`)
			end)
			
			task.wait()
		-- do few attempts just in case it's a new player
		until PlayerData or Attempt > 10
    end

	local ClonedData = script.PlayerData:Clone()

	-- If we're able to properly retrieve the data, parse through it and make valueobjects for expressing it in-game.
	if PlayerData then

        --check for achievements because it's the most basic shit to check for
		if not PlayerData.Achievements then
			DevItemGranter.CheckPlayer(Player, ClonedData)
			BadgeItemGranter.CheckPlayer(Player, ClonedData)

			ClonedData.Parent = Player
			SaveManager._SetupLeaderStats(ClonedData).Parent = Player

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

        local function CheckEmoteSection(Path: string, ValueType: string, Method: (any) -> any?)
            local IndexedTable = PlayerData
            local Data = ClonedData

            local Steps = Utils.Type.SplitStringPath(Path)

            for _, Step in ipairs(Steps) do
                IndexedTable = IndexedTable[Step]
                Data = Data[Step]
            end

            for name, item in IndexedTable do
                if Method(name) == nil then
                    continue
                end

                local Item = Instance.new(ValueType)
                Item.Name = name
                Item.Value = item
                Item.Parent = Data
            end
        end

		-- Iterate through equipped and purchased emotes
        CheckEmoteSection("Equipped.Emotes", "StringValue", Utils.Instance.GetEmoteModule)
        CheckEmoteSection("Purchased.Emotes", "StringValue", Utils.Instance.GetEmoteModule)

		-- Find their equipped killer and survivor
		ClonedData.Equipped.Killer.Value = Utils.Instance.GetCharacterModule("Killer", PlayerData.Equipped.Killer, nil, false) ~= nil and PlayerData.Equipped.Killer or ""
		ClonedData.Equipped.Survivor.Value = Utils.Instance.GetCharacterModule("Survivor", PlayerData.Equipped.Survivor, nil, false) ~= nil and PlayerData.Equipped.Survivor or ""

        local function CheckRoleSection(Path: string)
            local IndexedTable = PlayerData
            local Data = ClonedData

            local Steps = Utils.Type.SplitStringPath(Path)

            for _, Step in ipairs(Steps) do
                IndexedTable = IndexedTable[Step]
                Data = Data[Step]
            end

            for character, level in IndexedTable do
                local RoleName = Steps[#Steps]
                --removes the S at the end to get the proper role
                RoleName = RoleName:sub(1, #RoleName - 1)
                if Utils.Instance.GetCharacterModule(RoleName, character) == nil then
                    continue
                end

                local int = Instance.new("IntValue")
                int.Parent = Data
                -- If theres a stored level for the character, set the object to that value. Otherwise, keep it at 0.
                int.Value = level or 0
                int.Name = character
            end
        end

		-- killers,
        CheckRoleSection("Purchased.Killers")
		-- survivors,
        CheckRoleSection("Purchased.Survivors")

		-- equipped skins
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

		-- purchased skins,
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

        local function CheckMiscSection(Name: string)
            local Data = ClonedData[Name]

            for _, item in PlayerData[Name] do
                for name, value in item do
                    if not Data:FindFirstChild(name, true) then
                        continue --break
                    end
                    Data:FindFirstChild(name, true).Value = value
                end
            end
        end

		-- applied settings,
        CheckMiscSection("Settings")
		-- and tracked stats.
        CheckMiscSection("Stats")

        -- Used for changelogs.
		ClonedData.Misc.LastSeenLog.Value = PlayerData.Misc.LastSeenLog
	end

    --will grant any items related to badges or dev stuff assigned to this player
	DevItemGranter.CheckPlayer(Player, ClonedData)
	BadgeItemGranter.CheckPlayer(Player, ClonedData)

	-- Finally, nest all these instances neatly in the player for easy reference.
	ClonedData.Parent = Player
	SaveManager._SetupLeaderStats(ClonedData).Parent = Player

	return ClonedData
end

function SaveManager.Save(Player: Player, Data: Folder)
    task.spawn(function()
		local SaveFile = TypeUtils.ConvertInstanceTreeToTable(Data)

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

        do
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
        end

		-- Some kind of handling for if the player's data cant be saved would be epic, to prevent total corruption of savedata. Attempt cap is high to try and mitigate this, but it'd still be good practice.
		-- i believe that if it fails, the previous data remains so it doesn't get corrupted; i'll be unmarking this as a todo but correct me if i'm wrong
	end)
end

return SaveManager
