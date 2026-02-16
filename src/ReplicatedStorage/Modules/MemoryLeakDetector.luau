--[[
	MemoryLeakDetector - Identifies potential memory leaks
	Tracks objects and connections for cleanup
]]

local MemoryLeakDetector = {}

local tracked = {}
local currentId = 0

--- Track an object for memory leak detection
---@param obj any The object to track
---@param name string? A name for this object
---@return string The tracking ID
function MemoryLeakDetector.Track(obj: any, name: string?): string
	currentId += 1
	local id = tostring(currentId)
	
	tracked[id] = {
		Object = obj,
		Name = name or typeof(obj),
		CreatedAt = os.clock(),
		IsAlive = true,
	}
	
	return id
end

--- Untrack an object
---@param id string The tracking ID
function MemoryLeakDetector.Untrack(id: string): ()
	if tracked[id] then
		tracked[id].IsAlive = false
	end
end

--- Find abandoned connections (memory leak candidates)
---@return table List of potentially leaked connections
function MemoryLeakDetector.FindAbandonedConnections(): {any}
	local abandoned = {}
	local now = os.clock()
	
	for id, data in pairs(tracked) do
		if data.IsAlive and typeof(data.Object) == "RBXScriptConnection" then
			-- If connection is older than 10 minutes and still alive, it might be leaked
			if now - data.CreatedAt > 600 then
				table.insert(abandoned, {
					Id = id,
					Name = data.Name,
					Age = now - data.CreatedAt,
				})
			end
		end
	end
	
	return abandoned
end

--- Generate memory leak report
---@return string Report text
function MemoryLeakDetector.GenerateReport(): string
	local report = "[Memory Leak Report]\n"
	local abandoned = MemoryLeakDetector.FindAbandonedConnections()
	
	if #abandoned > 0 then
		report = report .. "Found " .. #abandoned .. " potentially abandoned connections:\n"
		for _, item in ipairs(abandoned) do
			report = report .. "  - " .. item.Name .. " (Age: " .. math.round(item.Age) .. "s)\n"
		end
	else
		report = report .. "No abandoned connections detected.\n"
	end
	
	local aliveCount = 0
	for _, data in pairs(tracked) do
		if data.IsAlive then
			aliveCount += 1
		end
	end
	
	report = report .. "\nActive objects: " .. aliveCount
	return report
end

return MemoryLeakDetector
