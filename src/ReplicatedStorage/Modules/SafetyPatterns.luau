--[[
    SafetyPatterns - Stability helper module
    Provides safe patterns for common operations to prevent crashes and memory leaks
]]

local SafetyPatterns = {}

--- Safely call a function and handle errors
--- Returns success, result
function SafetyPatterns.SafeCall(func: () -> any, ...: any): (boolean, any)
    if not func or type(func) ~= "function" then
        return false, "Invalid function"
    end
    
    return pcall(func, ...)
end

--- Safely spawn a coroutine with error handling
function SafetyPatterns.SafeSpawn(func: () -> any, ...: any): thread
    if not func or type(func) ~= "function" then
        warn("SafetyPatterns.SafeSpawn: Invalid function provided")
        return nil
    end
    
    local args = {...}
    return task.spawn(function()
        local success, result = pcall(func, unpack(args))
        if not success then
            warn("SafetyPatterns: Error in spawned task:", result)
        end
    end)
end

--- Safely delay a function with error handling and timeout
function SafetyPatterns.SafeDelay(delay: number, func: () -> any, timeout: number?, ...: any)
    if not func or type(func) ~= "function" then
        warn("SafetyPatterns.SafeDelay: Invalid function provided")
        return nil
    end
    
    delay = math.max(0, delay or 0)
    timeout = math.min(timeout or 300, 300) -- Max 5 minute timeout
    
    local args = {...}
    return task.delay(delay, function()
        local startTime = os.clock()
        if os.clock() - startTime > timeout then
            warn("SafetyPatterns.SafeDelay: Function timed out")
            return
        end
        
        local success, result = pcall(func, unpack(args))
        if not success then
            warn("SafetyPatterns: Error in delayed task:", result)
        end
    end)
end

--- Connection wrapper that auto-disconnects on nil target
local SafeConnection = {}
SafeConnection.__index = SafeConnection

function SafeConnection.new(targetCheck: () -> boolean, connection: RBXScriptConnection)
    local self = setmetatable({}, SafeConnection)
    self._targetCheck = targetCheck
    self._connection = connection
    self._connected = true
    return self
end

function SafeConnection:Disconnect()
    if self._connected and self._connection then
        pcall(function()
            self._connection:Disconnect()
        end)
    end
    self._connected = false
end

function SafeConnection:IsConnected()
    if self._targetCheck and not self._targetCheck() then
        self:Disconnect()
        return false
    end
    return self._connected and self._connection and self._connection.Connected
end

--- Wraps a connection to auto-disconnect if target becomes nil
function SafetyPatterns.WrapConnection(target: any, connection: RBXScriptConnection): typeof(SafeConnection)
    if not connection then return nil end
    
    local targetCheck = function()
        if target == nil then
            return false
        end
        if typeof(target) == "Instance" then
            return target and target.Parent ~= nil
        end
        return true
    end
    
    return SafeConnection.new(targetCheck, connection)
end

--- Safely get a value from a table without errors
function SafetyPatterns.SafeGet(tbl: any, key: any, default: any): any
    if type(tbl) ~= "table" then
        return default
    end
    
    local success, result = pcall(function()
        return tbl[key]
    end)
    
    return success and result or default
end

--- Safely set a value in a table
function SafetyPatterns.SafeSet(tbl: any, key: any, value: any): boolean
    if type(tbl) ~= "table" then
        return false
    end
    
    local success, result = pcall(function()
        tbl[key] = value
    end)
    
    return success
end

--- Safely access instance properties
function SafetyPatterns.SafeGetProperty(instance: Instance, property: string, default: any): any
    if not instance or not instance.Parent then
        return default
    end
    
    local success, result = pcall(function()
        return instance[property]
    end)
    
    return success and result or default
end

--- Safely set instance properties
function SafetyPatterns.SafeSetProperty(instance: Instance, property: string, value: any): boolean
    if not instance or not instance.Parent then
        return false
    end
    
    local success = pcall(function()
        instance[property] = value
    end)
    
    return success
end

--- Safely find a descendant with timeout
function SafetyPatterns.SafeWaitForChild(parent: Instance, name: string, timeout: number?, recursive: boolean?): Instance | nil
    if not parent or not parent.Parent then
        return nil
    end
    
    timeout = math.min(timeout or 10, 60) -- Max 60 second timeout
    
    local startTime = os.clock()
    while parent and parent.Parent do
        local child: Instance | nil
        if recursive then
            child = parent:FindFirstChild(name, true)
        else
            child = parent:FindFirstChild(name)
        end
        
        if child then
            return child
        end
        
        if os.clock() - startTime > timeout then
            return nil
        end
        
        task.wait(0.05)
    end
    
    return nil
end

--- Thread pool for managed async operations
SafetyPatterns.ThreadPool = {}
SafetyPatterns.ThreadPool.__index = SafetyPatterns.ThreadPool

function SafetyPatterns.ThreadPool.new()
    local self = setmetatable({}, SafetyPatterns.ThreadPool)
    self._threads = {}
    self._cleanup_fn = nil
    return self
end

function SafetyPatterns.ThreadPool:Add(threadId: string, thread: thread): boolean
    if self._threads[threadId] then
        self:Cancel(threadId)
    end
    
    self._threads[threadId] = {
        thread = thread,
        createdAt = os.clock()
    }
    return true
end

function SafetyPatterns.ThreadPool:Cancel(threadId: string): boolean
    local entry = self._threads[threadId]
    if not entry then return false end
    
    pcall(function()
        task.cancel(entry.thread)
    end)
    self._threads[threadId] = nil
    return true
end

function SafetyPatterns.ThreadPool:CancelAll()
    for id, _ in pairs(self._threads) do
        self:Cancel(id)
    end
end

function SafetyPatterns.ThreadPool:Size(): number
    return #({pairs(self._threads)})
end

--- Create a managed connection list
SafetyPatterns.ConnectionPool = {}
SafetyPatterns.ConnectionPool.__index = SafetyPatterns.ConnectionPool

function SafetyPatterns.ConnectionPool.new()
    local self = setmetatable({}, SafetyPatterns.ConnectionPool)
    self._connections = {}
    return self
end

function SafetyPatterns.ConnectionPool:Add(connection: RBXScriptConnection, id: string?): boolean
    if not connection then return false end
    
    id = id or tostring(#self._connections + 1)
    
    if self._connections[id] and self._connections[id].Connected then
        pcall(function()
            self._connections[id]:Disconnect()
        end)
    end
    
    self._connections[id] = connection
    return true
end

function SafetyPatterns.ConnectionPool:Disconnect(id: string): boolean
    local conn = self._connections[id]
    if not conn then return false end
    
    pcall(function()
        if conn.Connected then
            conn:Disconnect()
        end
    end)
    
    self._connections[id] = nil
    return true
end

function SafetyPatterns.ConnectionPool:DisconnectAll()
    for id, _ in pairs(self._connections) do
        self:Disconnect(id)
    end
end

function SafetyPatterns.ConnectionPool:Size(): number
    return #({pairs(self._connections)})
end

return SafetyPatterns
