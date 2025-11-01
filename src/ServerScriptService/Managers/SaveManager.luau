local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Utils = require(ReplicatedStorage.Modules.Utils)

local SaveManager = {
    PlayerDatas = {},
}

local _, Storage = pcall(function()
    return DataStoreService:GetDataStore("DriftwoodThing")
end)
local StoreKey = "driftwooding77"

local function ConvertInstanceTreeToTable(obj)
    local tree = {}

    for _, v in ipairs(obj:GetChildren()) do
        if v:IsA("Folder") then
            tree[v.Name] = ConvertInstanceTreeToTable(v)
        elseif v:IsA("ValueBase") then
            tree[v.Name] = v.Value
        end
    end

    return tree
end

function SaveManager:Init()
    local function LoadPlayer(Player: Player)
		self.PlayerDatas[Player.UserId] = self:Load(Player)
        
        for AchievementGroupCodeName, AchievementGroup in Achievements do
            if not self.PlayerDatas[Player.UserId].Achievements:FindFirstChild(AchievementGroupCodeName) then
                local Group = Instance.new("Folder")
                Group.Name = AchievementGroupCodeName
                Group.Parent = self.PlayerDatas[Player.UserId].Achievements
            end

            for AchievementCodeName, Achievement in AchievementGroup do
                if Achievement.Requirement and not self.PlayerDatas[Player.UserId].Achievements[AchievementGroupCodeName]:FindFirstChild(AchievementCodeName) then
                    local AchievementProgress = Instance.new("NumberValue")
                    AchievementProgress.Name = AchievementCodeName
                    AchievementProgress.Value = 0
                    AchievementProgress.Parent = self.PlayerDatas[Player.UserId]
                end
            end
        end
    end

    Players.PlayerAdded:Connect(LoadPlayer)
	for _, i in Players:GetPlayers() do
		LoadPlayer(i)
	end

    Players.PlayerRemoving:Connect(function(Player: Player)
        self:Save(Player, self.PlayerDatas[Player.UserId])
    end)

    game:BindToClose(function()
        for _, i in Players:GetPlayers() do
            self:Save(i, self.PlayerDatas[i.UserId])
        end
    end)
end

--- Sets up a display leaderstat folder for any data that has the `DisplayInLeaderstats` attribute.
function SaveManager:_SetupLeaderStats(DataFolder, parent) --just for display, won't save
    for _, i in DataFolder:GetDescendants() do
        if i:IsA("ValueBase") and i:GetAttribute("DisplayInLeaderstats") == true then
            local LeaderStat = Instance.new("IntValue")
            LeaderStat.Name = i.Name
            LeaderStat.Value = i.Value
            LeaderStat.Parent = parent

            i.Changed:Connect(function()
                if LeaderStat then
                    LeaderStat.Value = i.Value
                end
            end)
        end
    end
end

function SaveManager:_CheckSaveIntegrity(DataFolder, parent)
    for _, i in DataFolder.Equipped.Emotes:GetChildren() do
        if Utils:GetEmoteModule(i.Name) == nil then
            i:Destroy()
        end
	end
    for _, i in DataFolder.Equipped.Skins:GetChildren() do
        if Utils:GetCharacterModule("Killer", i.Name, i.Value) == nil and Utils:GetCharacterModule("Survivor", i.Name, i.Value) == nil then
            i:Destroy()
        end
    end

    local EquippedKiller = DataFolder.Equipped.Killer
    local EquippedSurvivor = DataFolder.Equipped.Survivor

    if not Utils:GetCharacterModule("Killer", EquippedKiller.Value) then
        EquippedKiller.Value = script.PlayerData.Equipped.Killer
    end
    if not Utils:GetCharacterModule("Survivor", EquippedSurvivor.Value) then
        EquippedSurvivor.Value = script.PlayerData.Equipped.Survivor
    end

    for _, lvl in DataFolder.Purchased.Killers:GetChildren() do
        if Utils:GetCharacterModule("Killer", lvl.Name) == nil then
            lvl:Destroy()
        end
    end
    for _, lvl in DataFolder.Purchased.Survivors:GetChildren() do
        if Utils:GetCharacterModule("Survivor", lvl.Name) == nil then
            lvl:Destroy()
        end
    end

	for _, i in DataFolder.Purchased.Skins:GetChildren() do
        local IsSurvivor = Utils:GetCharacterModule("Survivor", i.Name) ~= nil
        if not IsSurvivor then
            if Utils:GetCharacterModule("Killer", i.Name) == nil then
                i:Destroy()
                continue
            end
        end

		for ve, ie in i:GetChildren() do
            if Utils:GetCharacterModule(if IsSurvivor then "Survivor" else "Killer", i.Name, ie.Name) == nil then
                ie:Destroy()
                continue
            end
		end
    end
end

--- Loads a player's saved data and returns its folder containing all `ValueBase`s instances with it.
function SaveManager:Load(Player: Player): Folder
    local _, GetAsync = pcall(function()
        return if Storage then Storage:GetAsync(`{StoreKey}_{Player.UserId}`) else nil
    end)
    local ClonedData = script.PlayerData:Clone()

    local Leaderstats = Instance.new("Folder")
    Leaderstats.Name = "leaderstats"

	if GetAsync then
        if not GetAsync.Achievements then
            -- self:_CheckSaveIntegrity(ClonedData)
            ClonedData.Parent = Player
            self:_SetupLeaderStats(ClonedData, Leaderstats)
            Leaderstats.Parent = Player

            return ClonedData
        end

        for _, i in GetAsync.Achievements do
            for n, v in i do
                if not ClonedData.Achievements:FindFirstChild(n, true) then
                    continue --break
                end
                ClonedData.Achievements:FindFirstChild(n, true).Value = v
            end
        end

		for v, i in GetAsync.Equipped.Emotes do
            if Utils:GetEmoteModule(v) == nil then
                continue
            end

			local Emote = Instance.new("StringValue")
			Emote.Name = v
			Emote.Value = i
			Emote.Parent = ClonedData.Equipped.Emotes
		end
        for v, i in GetAsync.Equipped.Skins do
            if Utils:GetCharacterModule("Killer", v, i) == nil and Utils:GetCharacterModule("Survivor", v, i) == nil then
                continue
            end

            local V = Instance.new("StringValue")
            V.Name = v
            V.Value = i
            V.Parent = ClonedData.Equipped.Skins
        end
		ClonedData.Equipped.Killer.Value = Utils:GetCharacterModule("Killer", GetAsync.Equipped.Killer) ~= nil and GetAsync.Equipped.Killer or ""
		ClonedData.Equipped.Survivor.Value = Utils:GetCharacterModule("Survivor", GetAsync.Equipped.Survivor) ~= nil and GetAsync.Equipped.Survivor or ""

		ClonedData.Misc.LastSeenLog.Value = GetAsync.Misc.LastSeenLog

        for v, _ in GetAsync.Purchased.Emotes do
            if not Utils:GetEmoteModule(v) then
                continue
            end

            local int = Instance.new("IntValue")
            int.Parent = ClonedData.Purchased.Emotes
            int.Name = v
        end
        for v, lvl in GetAsync.Purchased.Killers do
            if Utils:GetCharacterModule("Killer", v) == nil then
                continue
            end

            local int = Instance.new("IntValue")
            int.Parent = ClonedData.Purchased.Killers
            if lvl then
                int.Value = lvl
            end
            int.Name = v
        end
        for v, lvl in GetAsync.Purchased.Survivors do
            if Utils:GetCharacterModule("Survivor", v) == nil then
                continue
            end

            local int = Instance.new("IntValue")
            int.Parent = ClonedData.Purchased.Survivors
            if lvl then
                int.Value = lvl
            end
            int.Name = v
        end
		for v, i in GetAsync.Purchased.Skins do
            local IsSurvivor = Utils:GetCharacterModule("Survivor", v) ~= nil
            if not IsSurvivor then
                if Utils:GetCharacterModule("Killer", v) == nil then
                    continue
                end
            end

            local Folder = Instance.new("Folder")
			Folder.Name = v
			Folder.Parent = ClonedData.Purchased.Skins
			for ve, ie in i do
                if Utils:GetCharacterModule(if IsSurvivor then "Survivor" else "Killer", v, ve) == nil then
                    continue
                end

            	local int = Instance.new("IntValue")
            	int.Parent = Folder
				int.Name = ve
				int.Value = ie
			end
        end

		for _, i in GetAsync.Settings do
			for v, ie in i do
            	if not ClonedData.Settings:FindFirstChild(v, true) then
            	    continue --break
            	end
				ClonedData.Settings:FindFirstChild(v, true).Value = ie
			end
        end
		for _, i in GetAsync.Stats do
			for v, ie in i do
            	if not ClonedData.Stats:FindFirstChild(v, true) then
            	    continue --break
            	end
				ClonedData.Stats:FindFirstChild(v, true).Value = ie
			end
        end
    end
    -- self:_CheckCheckSaveIntegrity(ClonedData)
    ClonedData.Parent = Player
    self:_SetupLeaderStats(ClonedData, Leaderstats)
    Leaderstats.Parent = Player

    return ClonedData
end

--- Saves a player's data using `DataStoreService`.
function SaveManager:Save(Player: Player, Data: Folder)
    local SaveFile = ConvertInstanceTreeToTable(Data)

    --i just figured out pairs and ipairs are fucking useless as generalized iteration had been implemented fairly long ago.
    --i want to die.
    for t, i in {Killer = SaveFile.Equipped.Killer, Survivor = SaveFile.Equipped.Survivor} do
        local Module = Utils:GetCharacterModule(t, i)
        if not Module or Module:HasTag("PreventSave") then
            SaveFile["Equipped"][t] = script:FindFirstChild("Equipped"):FindFirstChild(t).Value --if it's smth like a dev item it doesn't save in publics
        end
    end

    if workspace:GetAttribute("DebugAllowed") == true then
        print("Saving data for: "..Player.Name, SaveFile)
    end

    pcall(function()
        Storage:UpdateAsync(`{StoreKey}_{Player.UserId}`, function(_old)
            return SaveFile
        end)
    end)
end

return SaveManager
