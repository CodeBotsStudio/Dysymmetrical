--[[
	NetworkErrorHandler - Provides user-friendly error messages for network failures
	Prevents dump of raw errors to players
]]

local NetworkErrorHandler = {}

local ErrorMessages = {
	["Network timeout"] = "Connection lost. Please try again.",
	["Unable to fulfill request"] = "Server is busy. Please try again.",
	["invalid request"] = "Something went wrong with your request.",
	["player offline"] = "Player is no longer connected.",
	["inhibited"] = "This action is not allowed right now.",
}

--- Get a user-friendly error message
---@param rawError string The raw error from the server
---@return string A user-friendly message
function NetworkErrorHandler.GetFriendlyMessage(rawError: string): string
	local lowerError = string.lower(rawError or "")
	
	for pattern, message in pairs(ErrorMessages) do
		if string.find(lowerError, string.lower(pattern)) then
			return message
		end
	end
	
	-- Default fallback
	return "An error occurred. Contact support if the problem persists."
end

--- Log a network error safely
---@param errorType string Type of error (e.g., "RemoteEvent", "RemoteFunction")
---@param remoteName string Name of the remote
---@param rawError string The error message
function NetworkErrorHandler.LogError(errorType: string, remoteName: string, rawError: string): ()
	local friendlyMsg = NetworkErrorHandler.GetFriendlyMessage(rawError)
	warn(`[NetworkError] {errorType} '{remoteName}': {friendlyMsg}`)
end

return NetworkErrorHandler