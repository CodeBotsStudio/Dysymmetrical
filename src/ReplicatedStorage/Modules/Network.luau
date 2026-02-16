--[[
	Thanks for using DysNetworking!
	Every bit of documentation is scattered through this same module.
	I tried to document it as well as I could to make it as understandable as possible.
	You'll still have to know some coding to work properly with this.
	Anyway, have fun making your games!
	
	
	
	To access this module's functions, just require it from anywhere, from any kind of script.
	For example:
	
		---CLIENT---
		local DysNetworking = require(game:GetService("ReplicatedStorage").DysNetworking)
		DysNetworking:SetConnection("EXAMPLE_1", "REMOTE_EVENT", function(param1: string)
			print(param1)
		end)
		
		DysNetworking:FireServerConnection("EXAMPLE_2", "REMOTE_EVENT", "printing from server!")
		
		---SERVER---
		local DysNetworking = require(game:GetService("ReplicatedStorage").DysNetworking)
		DysNetworking:FireAllClients("EXAMPLE_1", "REMOTE_EVENT", "printing!") --where `"printing!"` is `param1` in the client.
		--If you do `FireClient` instead, you'll have to specify the target player before anything.
		
		--When connecting from the server to a remote, the first parameter **MUST** always be the player that called the event, just like with Remote instances.
		DysNetworking:SetConnection("EXAMPLE_2", "REMOTE_EVENT", function(sourcePlayer: Player, param1: string)
			print(sourcePlayer.Name.." called this event!")
			print(param1)
		end)
		
	That's it, pretty simple.
	Everything works like your traditional Remote & Bindable instances.
	
	Though, this module will have to be initted in both sides before it can be properly used.
	For that, just create a script in `ServerScriptService` and another one in `StarterPlayerScripts` that requires it and calls `DysNetworking:Init()`.
	In the template there are two scripts that already do this and destroy themselves when they do so, so you can just use those. :p
	
	That's it! :>
]]

local RunService = game:GetService("RunService")

--- Simple signal class for event-driven initialization
local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._Connections = {}
	self._Fired = false
	return self
end

function Signal:Connect(callback)
	if self._Fired then
		task.spawn(callback)
		return {Disconnect = function() end}
	end
	
	local connection = {
		Connected = true,
		Disconnect = function(self)
			self.Connected = false
			for i, conn in ipairs(self._Signal._Connections) do
				if conn == self then
					table.remove(self._Signal._Connections, i)
					break
				end
			end
		end,
		_Signal = self
	}
	table.insert(self._Connections, connection)
	return connection
end

function Signal:Wait()
	if self._Fired then return end
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function()
		if connection and connection.Connected then
			connection:Disconnect()
		end
		task.spawn(thread)
	end)
	coroutine.yield()
end

function Signal:Fire()
	if self._Fired then return end
	self._Fired = true
	for _, connection in ipairs(self._Connections) do
		if connection.Connected then
			task.spawn(connection[1])
		end
	end
	self._Connections = {}
end

--- Class used to connect the server and the clients more efficiently by encapsulating everything in a single place.
local Network = {
    Folders = {
        REMOTE_EVENT = nil,
        REMOTE_FUNCTION = nil,
        UREMOTE_EVENT = nil,
        BINDABLE_EVENT = nil,
    },
    _FolderNames = {
        "REMOTE_EVENT",
        "REMOTE_FUNCTION",
        "UREMOTE_EVENT",
        "BINDABLE_EVENT",
    },
    InstanceCreator = nil,
    ServiceLive = false,
	_InitSignal = Signal.new(),
	_Connections = {},
}

--- Initializes the networking system in the current environment.
function Network:Init()
    if RunService:IsServer() then
        game:BindToClose(function()
            self:Destroy()
        end)

        for _, name in self._FolderNames do
            local Folder = Instance.new("Folder")
            Folder.Name = name
            self.Folders[name] = Folder
            Folder.Parent = script
        end

        self.InstanceCreator = Instance.new("RemoteFunction")
        self.InstanceCreator.Name = "InstanceCreator"
        self.InstanceCreator.Parent = script

        self.InstanceCreator.OnServerInvoke = function(_player: Player, name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION" | "BINDABLE_EVENT")
            local success, result = pcall(function()
                return self:_CreateInstance(name, Type)
            end)
            if not success then
                warn("Network: Failed to create instance", name, Type, result)
                return nil
            end
            return result
        end
    else
        local creatorFound = false
        for _, name in self._FolderNames do
            local folder = script:FindFirstChild(name)
            if not folder then
                folder = script:WaitForChild(name, 10)
            end
            if folder then
                self.Folders[name] = folder
            else
                warn("Network: Failed to find folder", name)
            end
        end

        local creator = script:FindFirstChild("InstanceCreator")
        if not creator then
            creator = script:WaitForChild("InstanceCreator", 10)
        end
        
        if creator then
            self.InstanceCreator = creator
            creatorFound = true
        else
            warn("Network: InstanceCreator not found - RemoteFunction creation will fail")
        end
    end

    self.ServiceLive = true
    self._InitSignal:Fire()
end

--- Wait for the network to be initialized with timeout
function Network:_WaitForInit(timeout: number?)
	timeout = timeout or 30
	if self:IsLive() then return true end
	
	local startTime = os.clock()
	while not self:IsLive() do
		if os.clock() - startTime > timeout then
			warn("Network: Initialization timeout after", timeout, "seconds")
			return false
		end
		task.wait(0.05)
	end
	return true
end

--- Creates an instance of a specific type for later usage.
--- @param name                                                                     (`string`): The name of the instance.
--- @param Type                                                                     (`string`): The desired type of the instance.
--- @return `RemoteEvent | UnreliableRemoteEvent | RemoteFunction | BindableEvent`              The instance that has been created.
function Network:_CreateInstance(name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION" | "BINDABLE_EVENT"): RemoteEvent | UnreliableRemoteEvent | RemoteFunction | BindableEvent
    if not RunService:IsServer() then return end
    
    local instance
    if Type == "REMOTE_EVENT" then
        instance = Instance.new("RemoteEvent")
    elseif Type == "UREMOTE_EVENT" then
        instance = Instance.new("UnreliableRemoteEvent")
    elseif Type == "REMOTE_FUNCTION" then
        instance = Instance.new("RemoteFunction")
    elseif Type == "BINDABLE_EVENT" then
        instance = Instance.new("BindableEvent")
    end

    if not instance then
        error("Invalid Type: " .. tostring(Type))
    end

    instance.Name = name
    instance.Parent = self.Folders[Type]
    return instance
end

--- Sets up a connection for an instance depending on the type.
--- @param instance (`RemoteEvent | UnreliableRemoteEvent | RemoteFunction | BindableEvent`):   The instance to set up the connection of.
--- @param Callback (`function`):                                                               The code that will execute when the connection fires.
function Network:_SetupConnection(instance: RemoteEvent | UnreliableRemoteEvent | RemoteFunction | BindableEvent, Callback: (any) -> (any)): RBXScriptConnection | nil
    if not instance or not Callback then return nil end
    
    if instance:IsA("BindableEvent") then
        return instance.Event:Connect(Callback)
    else
        if RunService:IsServer() then
            if instance:IsA("RemoteEvent") or instance:IsA("UnreliableRemoteEvent") then
                return instance.OnServerEvent:Connect(Callback)
            elseif instance:IsA("RemoteFunction") then
                instance.OnServerInvoke = Callback
            end
            return
        else
            if instance:IsA("RemoteEvent") or instance:IsA("UnreliableRemoteEvent") then
                return instance.OnClientEvent:Connect(Callback)
            elseif instance:IsA("RemoteFunction") then
                instance.OnClientInvoke = Callback
            end
            return
        end
    end
end

--- Adds a connection to a specific event / function instance.
--- @param name                    (`string`):      The name of the instance.
--- @param Type                    (`string`):      The type of the instance.
--- @param Callback                (`function`):    The code that will run when the connection is fired.
--- @return `RBXScriptConnection`                   The set connection for further usage in the script from where this is called.
function Network:SetConnection(name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION" | "BINDABLE_EVENT", Callback: (...any) -> (...any)): RBXScriptConnection
    if not self:_WaitForInit() then
        warn("Network: Failed to initialize in SetConnection for", name)
        return nil
    end
    
    local instance
    if RunService:IsServer() then
        if not self.Folders[Type]:FindFirstChild(name) then
            instance = self:_CreateInstance(name, Type)
        else
            instance = self.Folders[Type]:FindFirstChild(name)
        end
    else
        if not self.Folders[Type]:FindFirstChild(name) then
            if self.InstanceCreator then
                local success, result = pcall(function()
                    return self.InstanceCreator:InvokeServer(name, Type)
                end)
                if success then
                    instance = result
                else
                    warn("Network: Failed to create instance on server:", result)
                    return nil
                end
            else
                warn("Network: InstanceCreator not available")
                return nil
            end
        else
            instance = self.Folders[Type]:FindFirstChild(name)
        end
    end
    
    return self:_SetupConnection(instance, Callback)
end

--- Destroys the Network instance. Only called when the server closes.
function Network:Destroy()
    for _, remote in ipairs(self._Connections) do
        pcall(function()
            if remote and remote.Connected then
                remote:Disconnect()
            end
        end)
    end
    self._Connections = {}
    
    if self.Folders.REMOTE_FUNCTION then
        for _, RemoteFunction in self.Folders.REMOTE_FUNCTION:GetChildren() do
            if RemoteFunction:IsA("RemoteFunction") then
                pcall(function()
                    RemoteFunction.OnServerInvoke = function() end
                end)
            end
        end
    end
end

--- Fires a specific client's event / function connections.
--- @param target  (`Player`):  The target client whose connections will be fired.
--- @param name    (`string`):  The name of the desired event / function
--- @param Type    (`string`):  The type of instance to fire the connections of
--- @param ...                  Any parameters to pass to the connection
function Network:FireClientConnection(target: Player | {Player}, name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION", ...): any | nil
    if not self:_WaitForInit() then return nil end
    if not RunService:IsServer() or not self.Folders[Type]:FindFirstChild(name) then return nil end

    local event = self.Folders[Type]:FindFirstChild(name)
    if not event then return nil end

    local function Fire(player: Player, ...)
        if not player or not player.Parent then return nil end
        
        local args = {...}
        local success, result
        if event:IsA("RemoteFunction") then
            success, result = pcall(function()
                return event:InvokeClient(player, unpack(args))
            end)
        else
            success, result = pcall(function()
                event:FireClient(player, unpack(args))
            end)
        end
        
        if not success then
            warn("Network: Failed to fire client connection:", result)
        end
        return result
    end

    if typeof(target) == "table" then
        local results = {}
        for _, player: Player in target do
            results[player.UserId] = Fire(player, ...)
        end
        return results
    else
        return Fire(target, ...)
    end
end

--- Fires an event's connections to every single connected client. If the type of the object is a RemoteFunction, it won't do anything.
--- @param name    (`string`):  The name of the desired event
--- @param Type    (`string`):  The type of the event (Reliable / Unreliable)
--- @param ...                  Any parameters to pass to the connection
function Network:FireAllClientConnection(name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION", ...)
    if not self:_WaitForInit() then return end
    if not RunService:IsServer() or Type == "REMOTE_FUNCTION" or not self.Folders[Type]:FindFirstChild(name) then return end

    local event = self.Folders[Type]:FindFirstChild(name)
    if event then
        local args = {...}
        local success, result = pcall(function()
            event:FireAllClients(unpack(args))
        end)
        if not success then
            warn("Network: Failed to fire all clients:", result)
        end
    end
end

--- Fires a server's event / function connections.
--- @param name    (`string`):  The name of the desired event / function
--- @param Type    (`string`):  The type of instance to fire the connections of
--- @param ...                  Any parameters to pass to the connection
function Network:FireServerConnection(name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION", ...): any | nil
    if not self:_WaitForInit() then return nil end
    if not RunService:IsClient() or not self.Folders[Type]:FindFirstChild(name) then return nil end

    local instance = self.Folders[Type]:FindFirstChild(name)
    if not instance then return nil end
    
    local args = {...}
    local success, result
    if instance:IsA("RemoteFunction") then
        success, result = pcall(function()
            return instance:InvokeServer(unpack(args))
        end)
    else
        success, result = pcall(function()
            instance:FireServer(unpack(args))
        end)
    end
    
    if not success then
        warn("Network: Failed to fire server connection:", result)
    end
    return result
end

--- Fires a BindableEvent's connections
--- @param name (`string`): The name of the desired BindableEvent
--- @param ...              Any parameters to pass to the connection
function Network:FireConnection(name: string, ...)
    if not self:_WaitForInit() then return end
    local event = self.Folders["BINDABLE_EVENT"]:FindFirstChild(name)
    if event then
        local args = {...}
        local success, result = pcall(function()
            event:Fire(unpack(args))
        end)
        if not success then
            warn("Network: Failed to fire connection:", result)
        end
    end
end

--- Returns an object instance
--- @param name    (`string`):    The name of the desired instance
--- @param Type    (`string`):    The type of the desired instance inside of the script (e. g. "REMOTE_EVENT")
--- @return `any`                 May return the desired instance
function Network:GetInstance(name: string, Type: "REMOTE_EVENT" | "UREMOTE_EVENT" | "REMOTE_FUNCTION" | "BINDABLE_EVENT")
    if not self:_WaitForInit() then return nil end
    return self.Folders[Type]:FindFirstChild(name)
end

--- Checks if the Network service is available in the current environment
function Network:IsLive()
    return self.ServiceLive and self:_FoldersAvailable()
end

--- Checks if every folder is available
function Network:_FoldersAvailable()
    local availableIndex = 0
    for _, folder in self.Folders do
        if folder ~= nil then
            availableIndex += 1
        end
    end
    return availableIndex == #self._FolderNames
end

return Network
