--[[
	MapConfig - Per-map configuration system
	Stores custom settings like LMS thresholds, spawn points, weather, music, etc.
	Supports both map-level and character-level LMS overrides
]]

local MapConfig = {}

--- Map-specific configurations
local MapConfigurations = {
	["Example_Map"] = {
		DisplayName = "Example",
		LastManStanding = {
			Enabled = true,
			SurvivorsThreshold = 1,  -- Trigger LMS when this many survivors remain
			MusicAssetId = "rbxassetid://0",  -- LMS music ID - duration is calculated from this
			TakeOverTimeLimit = 180,  -- Fallback timeout in seconds if music unavailable
		},
		SpawnPoints = {
			Killers = {
				Position = Vector3.new(0, 10, 0),
				CFrame = CFrame.new(0, 10, 0),
			},
			Survivors = {
				{Position = Vector3.new(-20, 5, 0)},
				{Position = Vector3.new(20, 5, 0)},
				{Position = Vector3.new(0, 5, -20)},
				{Position = Vector3.new(0, 5, 20)},
			},
		},
		Weather = {
			Fog = 0.5,
			Lighting = "Day",
			TimeOfDay = "12:00:00",
		},
		Level = 1,
	},
}

--- Character-specific LMS overrides
--- Format: CharacterName -> { Duration = seconds, MusicAssetId = "id" }
local CharacterLMSOverrides = {
	-- Examples:
	-- ["Killer1"] = { Duration = 120, MusicAssetId = "rbxassetid://123" },
	-- ["Killer2"] = { Duration = 150 },
}

local musicDurationCache = {}

--- Get configuration for a map
---@param mapName string The name of the map
---@return table? The map configuration, or nil if not found
function MapConfig.GetMapConfig(mapName: string): any
	return MapConfigurations[mapName]
end

--- Get LMS settings for a map
---@param mapName string The name of the map
---@return table LMS configuration
function MapConfig.GetLMSConfig(mapName: string): any
	local config = MapConfigurations[mapName]
	if not config then
		return {
			Enabled = true,
			SurvivorsThreshold = 1,
			MusicAssetId = nil,
			TakeOverTimeLimit = 180,
		}
	end
	return config.LastManStanding or {
		Enabled = true,
		SurvivorsThreshold = 1,
		MusicAssetId = nil,
		TakeOverTimeLimit = 180,
	}
end

--- Get LMS duration based on character, map, or fallback
---@param mapName string The name of the map
---@param characterName string? Character name to check for overrides
---@param characterConfig {LastManStandingTheme: string}? Character config with LastManStandingTheme
---@return number Duration in seconds
function MapConfig.GetLMSDuration(mapName: string, characterName: string?, characterConfig: any?): number
	-- Check character-level override first
	if characterName then
		local charOverride = CharacterLMSOverrides[characterName]
		if charOverride and charOverride.Duration then
			return charOverride.Duration
		end
		-- Check character-level music
		if charOverride and charOverride.MusicAssetId then
			return MapConfig._GetMusicDuration(charOverride.MusicAssetId)
		end
	end
	
	-- Check map-level LMS
	local lmsConfig = MapConfig.GetLMSConfig(mapName)
	if lmsConfig.MusicAssetId then
		return MapConfig._GetMusicDuration(lmsConfig.MusicAssetId, lmsConfig.TakeOverTimeLimit or 180)
	end
	
	-- Check character's LastManStandingTheme
	if characterConfig and characterConfig.LastManStandingTheme then
		return MapConfig._GetMusicDuration(characterConfig.LastManStandingTheme, 180)
	end
	
	-- Fallback
	return lmsConfig.TakeOverTimeLimit or 180
end

--- Internal: Get music duration with caching
---@param musicAssetId string The music asset ID
---@param fallback number? Fallback duration if music fails to load
---@return number Duration in seconds
function MapConfig._GetMusicDuration(musicAssetId: string, fallback: number?): number
	fallback = fallback or 180
	
	-- Check cache first
	if musicDurationCache[musicAssetId] then
		return musicDurationCache[musicAssetId]
	end
	
	-- Try to load music and get duration
	local success, duration = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = musicAssetId
		sound.Parent = workspace
		
		-- Wait for sound to load
		local timeout = 0
		while sound.TimeLength == 0 and timeout < 10 do
			task.wait(0.1)
			timeout += 0.1
		end
		
		local length = sound.TimeLength
		sound:Destroy()
		return length > 0 and length or fallback
	end)
	
	local finalDuration = (success and duration) or fallback
	musicDurationCache[musicAssetId] = finalDuration
	
	return finalDuration
end

--- Check if a map has LMS enabled
---@param mapName string The name of the map
---@return boolean Whether LMS is enabled
function MapConfig.IsLMSEnabled(mapName: string): boolean
	local lmsConfig = MapConfig.GetLMSConfig(mapName)
	return lmsConfig.Enabled ~= false
end

--- Get survivors threshold for LMS
---@param mapName string The name of the map
---@return number Survivors remaining before LMS triggers
function MapConfig.GetLMSThreshold(mapName: string): number
	local lmsConfig = MapConfig.GetLMSConfig(mapName)
	return lmsConfig.SurvivorsThreshold or 1
end

--- Get spawn point for a role on the map
---@param mapName string The name of the map
---@param role string "Killer" or "Survivor"
---@param spawnIndex number? Index for survivor (default 1)
---@return CFrame The spawn location
function MapConfig.GetSpawnPoint(mapName: string, role: string, spawnIndex: number?): CFrame
	local config = MapConfigurations[mapName]
	if not config or not config.SpawnPoints then
		return CFrame.new(0, 5, 0)  -- Fallback
	end
	
	if role == "Killer" then
		local killer = config.SpawnPoints.Killers
		if killer and killer.CFrame then
			return killer.CFrame
		elseif killer and killer.Position then
			return CFrame.new(killer.Position)
		end
	else
		local survivors = config.SpawnPoints.Survivors
		if survivors and #survivors > 0 then
			spawnIndex = spawnIndex or 1
			local spawn = survivors[((spawnIndex - 1) % #survivors) + 1]
			if spawn.CFrame then
				return spawn.CFrame
			elseif spawn.Position then
				return CFrame.new(spawn.Position)
			end
		end
	end
	
	return CFrame.new(0, 5, 0)
end

--- Get weather settings for a map
---@param mapName string The name of the map
---@return table Weather configuration
function MapConfig.GetWeatherConfig(mapName: string): any
	local config = MapConfigurations[mapName]
	if not config or not config.Weather then
		return {
			Fog = 0,
			Lighting = "Day",
			TimeOfDay = "12:00:00",
		}
	end
	return config.Weather
end

--- Register custom map configuration
---@param mapName string The name of the map
---@param config table The configuration table
function MapConfig.RegisterMap(mapName: string, config: any): ()
	MapConfigurations[mapName] = config
end

--- Get all registered maps
---@return table List of map names
function MapConfig.GetAllMaps(): {string}
	local maps = {}
	for name, _ in pairs(MapConfigurations) do
		table.insert(maps, name)
	end
	return maps
end

--- Set character-level LMS override
---@param characterName string The character name
---@param duration number? LMS duration in seconds
---@param musicAssetId string? Music asset ID for this character's LMS
function MapConfig.SetCharacterLMSOverride(characterName: string, duration: number?, musicAssetId: string?)
	if not CharacterLMSOverrides[characterName] then
		CharacterLMSOverrides[characterName] = {}
	end
	
	if duration then
		CharacterLMSOverrides[characterName].Duration = duration
	end
	if musicAssetId then
		CharacterLMSOverrides[characterName].MusicAssetId = musicAssetId
	end
end

--- Get character-level LMS override
---@param characterName string The character name
---@return table? Character LMS override or nil if none set
function MapConfig.GetCharacterLMSOverride(characterName: string): any
	return CharacterLMSOverrides[characterName]
end

--- Remove character-level LMS override
---@param characterName string The character name
function MapConfig.RemoveCharacterLMSOverride(characterName: string)
	CharacterLMSOverrides[characterName] = nil
end

--- Get all character LMS overrides
---@return table All character overrides
function MapConfig.GetAllCharacterLMSOverrides(): {[string]: any}
	return CharacterLMSOverrides
end

return MapConfig

