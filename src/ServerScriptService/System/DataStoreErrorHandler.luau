--[[
	DataStoreErrorHandler - Graceful fallback for DataStore failures
	Prevents crashes when DataStore is deleted or unavailable
]]

local DataStoreErrorHandler = {}

local errorCounts = {}
local MAX_RETRIES = 3
local BACKOFF_TIME = 2

--- Wrap a DataStore operation with error handling and retries
---@param operation fun(): any The operation to perform
---@param key string The operation key for logging
---@param retries number? Number of retries (default: MAX_RETRIES)
---@return boolean success Whether the operation succeeded
---@return any result The result or error message
function DataStoreErrorHandler.SafeOperation(operation: () -> any, key: string, retries: number?): (boolean, any)
	retries = retries or MAX_RETRIES
	
	for attempt = 1, retries do
		local success, result = pcall(operation)
		
		if success then
			errorCounts[key] = 0
			return true, result
		end
		
		local errorMsg = tostring(result)
		print(`[DataStoreErrorHandler] Operation '{key}' failed (attempt {attempt}/{retries}): {errorMsg}`)
		
		if attempt < retries then
			task.wait(BACKOFF_TIME * attempt)  -- Exponential backoff
		end
	end
	
	errorCounts[key] = (errorCounts[key] or 0) + 1
	
	-- Return fallback empty data structure
	return false, "DataStore operation failed after retries"
end

--- Check if DataStore is available
---@return boolean Whether DataStore is accessible
function DataStoreErrorHandler.IsAvailable(): boolean
	local success, _ = pcall(function()
		game:GetService("DataStoreService"):GetDataStore("_TEST_")
	end)
	return success
end

--- Get current error count for a key
---@param key string The operation key
---@return number Number of consecutive errors
function DataStoreErrorHandler.GetErrorCount(key: string): number
	return errorCounts[key] or 0
end

--- Check if we should stop trying (too many errors)
---@param key string The operation key
---@param threshold number? Error count threshold (default: 5)
---@return boolean Whether we've exceeded threshold
function DataStoreErrorHandler.HasExceededThreshold(key: string, threshold: number?): boolean
	threshold = threshold or 5
	return DataStoreErrorHandler.GetErrorCount(key) >= threshold
end

--- Clear error count for a key
---@param key string The operation key
function DataStoreErrorHandler.ClearErrors(key: string): ()
	errorCounts[key] = 0
end

return DataStoreErrorHandler
