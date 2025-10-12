local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

local SaveManager = {
    PlayerDatas = {},
}

local _, Storage = pcall(function()
    return DataStoreService:GetDataStore("DriftwoodThing")
end)
local StoreKey = "driftwooding71"

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
    Players.PlayerAdded:Connect(function(Player: Player)
        self.PlayerDatas[Player.UserId] = self:Load(Player)
	end)
	
	for _, i in Players:GetPlayers() do
		self.PlayerDatas[i.UserId] = self:Load(i)
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

        for v, i in GetAsync.AchievementsData do
            if not ClonedData.AchievementsData:FindFirstChild(v, true) then
                continue --break
            end
            ClonedData.AchievementsData:FindFirstChild(v, true).Value = i
        end

		for v, i in GetAsync.Equipped.Emotes do
			local Emote = Instance.new("NumberValue")
			Emote.Name = v
			Emote.Value = i
			Emote.Parent = ClonedData.Equipped.Emotes
		end
        for v, i in GetAsync.Equipped.Skins do
            local V = Instance.new("StringValue")
            V.Name = v
            V.Value = i
            V.Parent = ClonedData.Equipped.Skins
        end
		ClonedData.Equipped.Killer.Value = GetAsync.Equipped.Killer
		ClonedData.Equipped.Survivor.Value = GetAsync.Equipped.Survivor

		ClonedData.Misc.LastSeenLog.Value = GetAsync.Misc.LastSeenLog

        for v, _ in GetAsync.Purchased.Emotes do
            local int = Instance.new("IntValue")
            int.Parent = ClonedData.Purchased.Emotes
            int.Name = v
        end
        for v, lvl in GetAsync.Purchased.Killers do
            local int = Instance.new("IntValue")
            int.Parent = ClonedData.Purchased.Killers
            if lvl then
                int.Value = lvl
            end
            int.Name = v
        end
        for v, lvl in GetAsync.Purchased.Survivors do
            local int = Instance.new("IntValue")
            int.Parent = ClonedData.Purchased.Survivors
            if lvl then
                int.Value = lvl
            end
            int.Name = v
        end
		for v, i in GetAsync.Purchased.Skins do
			local Folder = Instance.new("Folder")
			Folder.Name = v
			Folder.Parent = ClonedData.Purchased.Skins
			for ve, ie in i do
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
        local Module = CommonUtils:GetCharacterModule(t, i)
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
