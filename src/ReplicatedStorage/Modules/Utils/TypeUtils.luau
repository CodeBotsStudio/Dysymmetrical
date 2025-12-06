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
	local NewTable = (MetaTable and setmetatable({}, MetaTable :: {}?) or {}) :: typeof(CloneThis)

	for i, v in CloneThis do
		if typeof(v) == "table" then
			NewTable[i] = TypeUtils.CopyTable(v)
		else
			NewTable[i] = v
		end
	end

	return NewTable
end

--- Shuffles a table to make it have a random order.
function TypeUtils.ShuffleTable<T>(t: T & {}): T & {}
    local j, temp

	for i = #t, 1, -1 do
		j = Rand:NextInteger(1, i)
		temp = t[i]
		t[i] = t[j]
		t[j] = temp
	end
	
	return t
end

--- Turns a dictionary into a table, removing the keys and making them numbers.
--- Primarily used for randomness as it isn't ordered in any way.
function TypeUtils.DictToTable<T>(Dictionary: {[any]: T}): {T}
    local NewTable = {}

    for _, item in Dictionary do
        table.insert(NewTable, item)
    end

    return NewTable
end

--- Returns the amount of items there are in a dictionary.
function TypeUtils.GetCountOfDict(dictionary: {[any]: any}): number
    local Count = 0

    if dictionary then
        for _, _ in dictionary do
            Count += 1
        end
    end
    
    return Count
end

function TypeUtils.FindInDictionary<K, V>(Dictionary: {[K]: V}, Item: K | V, Type: "Key" | "Value"): (K, V)
    if Type == "Key" then
        for v, i in Dictionary do
            if v == Item then
                return v, i
            end
        end
    elseif Type == "Value" then
        for v, i in Dictionary do
            if i == Item then
                return v, i
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

return TypeUtils
