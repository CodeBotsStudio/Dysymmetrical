--!nocheck

local TypeUtils = {}

local Rand = Random.new()

--- Splits a path into multiple strings.
function TypeUtils.SplitStringPath(path: string): {string}
    return path:split(".")
end

--- Makes a copy of an entire table.
function TypeUtils.CopyTable<T>(CloneThis: T & {}) : T & {}
	local MetaTable = getmetatable(CloneThis)
	local NewTable = (MetaTable and setmetatable({}, MetaTable) or {}) :: typeof(CloneThis)

	for Key, Value in CloneThis do
		if typeof(Value) == "table" then
			NewTable[Key] = TypeUtils.CopyTable(Value)
		else
			NewTable[Key] = Value
		end
	end

	return NewTable
end

--- Checks if a table is either a dictionary or a numeric table.
--- 
--- Mixed tables (containing numbers and others as keys) will be treated as dictionaries as well.
--- 
--- This util is useless if the table is empty for obvious reasons.
function TypeUtils.IsTableADictionary<T>(Target: T & {}): boolean
    for key, _ in Target do
        if typeof(key) ~= "number" then
            return true
        end
    end
    
    return false
end

--- Shuffles a table to make it have a random order.
--- 
--- Dictionaries won't be accepted in this function as they already don't have a specific order.
function TypeUtils.ShuffleTable<T>(TableToShuffle: T & {}): T & {}
    if TypeUtils.IsTableADictionary(TableToShuffle) then
        warn("[TypeUtils.ShuffleTable()]: Can't shuffle table! A dictionary, which can't be reordered, has been passed!")

        return TableToShuffle
    end

    local currentShuffledIndex, shufflingItem

	for index = #TableToShuffle, 1, -1 do
		currentShuffledIndex = Rand:NextInteger(1, index)
		shufflingItem = TableToShuffle[index]
		TableToShuffle[index] = TableToShuffle[currentShuffledIndex]
		TableToShuffle[currentShuffledIndex] = shufflingItem
	end
	
	return TableToShuffle
end

--- Turns a dictionary into a table, removing the keys and making them numbers.
--- 
--- Primarily used for randomness as it isn't ordered in any way.
function TypeUtils.DictToTable<T>(Dictionary: {[any]: T}): {T}
    if TypeUtils.IsTableADictionary(Dictionary) then
        return Dictionary
    end

    local NewTable = {}

    for _, item in Dictionary do
        table.insert(NewTable, item)
    end

    return NewTable
end

--- Returns the amount of items there are in a dictionary.
--- 
--- Also works with tables but you can just do `#TableName` instead.
function TypeUtils.GetCountOfDict(dictionary: {[any]: any}): number
    local Count = 0

    if dictionary then
        for _, _ in dictionary do
            Count += 1
        end
    end
    
    return Count
end

--- Attempts to find a certain key or value in a dictionary.
--- 
--- May also work with numeric tables.
function TypeUtils.FindInDictionary<K, V>(Dictionary: {[K]: V}, Item: K | V, Type: "Key" | "Value"): (K, V)
    if Type == "Key" then
        for Key, Value in Dictionary do
            if Key == Item then
                return Key, Value
            end
        end
    elseif Type == "Value" then
        for Key, Value in Dictionary do
            if Value == Item then
                return Key, Value
            end
        end
    end

    return
end

--- Replaces or copies any values from `Source` into `Target`.
--- If you pass in a table variable, you don't have to get anything as it'll be replaced in that variable directly.
function TypeUtils.DeepTableOverwrite<T>(Target: T & {}, Source: {[any]: any}): T & {}
    if not Target or not Source then
        return
    end

	for key, value in Source do
		if typeof(value) == "table" then
			if typeof(Target[key]) ~= "table" then
				Target[key] = {}
			end
			TypeUtils.DeepTableOverwrite(Target[key], value)
            continue
		end
		Target[key] = value
	end

    return Target
end

--- Copies any values from `Source` into `Target`.
--- If you pass in a table variable, you don't have to get anything as it'll be replaced in that variable directly.
--- Differs from `Utils:DeepTableOverwrite` in that it doesn't overwrite existing values.
function TypeUtils.DeepTableWrite<T>(Target: T & {}, Source: {[any]: any}): T & {}
    if not Target or not Source then
        return
    end

	for key, value in Source do
		if typeof(value) == "table" then
			if typeof(Target[key]) ~= "table" then
				Target[key] = {}
			end
			TypeUtils.DeepTableWrite(Target[key], value)
            continue
		end
        if Target[key] == nil then
		    Target[key] = value
        end
	end

    return Target
end

--- Gets a random item from the provided table.
--- 
--- This also works with dictionaries.
function TypeUtils.GetRandomItemFromTable<T>(Target: T & {}): any
    -- turn into a table if it's a dictionary
    local UsedTable = TypeUtils.DictToTable(Target)

    -- if it's empty return nothing
    if #UsedTable <= 0 then
        return
    end

    -- if it only has one item just return the item
    if #UsedTable == 1 then
        return UsedTable[1]
    end

    -- return a random index from the table
    return UsedTable[Rand:NextInteger(1, #UsedTable)]
end

return TypeUtils
