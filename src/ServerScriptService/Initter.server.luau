local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CanBenchmark = RunService:IsStudio() and workspace:GetAttribute("DebugAllowed")

local SSSDone = false
local RSDone = false
local InitErrors = {}

local totalModules = 0
local loadTimes = {}

local function InitModule(Module: ModuleScript)
    debug.setmemorycategory(Module.Name)
    local success, result = pcall(function()
        local Scr = require(Module)
        if typeof(Scr) == "table" and typeof(Scr.Init) == "function" then
            Scr:Init()
        end
        return Scr
    end)
    
    if not success then
        table.insert(InitErrors, {
            module = Module:GetFullName(),
            error = result
        })
        warn("Failed to initialize module:", Module:GetFullName(), "-", result)
    end
    
    return success
end

task.spawn(function()
    local modules = script.Parent:GetDescendants()
    for _, Module in modules do
        if not Module:IsA("ModuleScript") then
            continue
        end

        totalModules += 1

        if CanBenchmark then
            local start = os.clock()
            InitModule(Module)
            local duration = os.clock() - start

            table.insert(loadTimes, {
                name = Module:GetFullName(),
                time = duration
            })
        else
            InitModule(Module)
        end
    end
    debug.setmemorycategory("Default")
    SSSDone = true
end)

task.spawn(function()
    local success, result = pcall(function()
        return require(ReplicatedStorage.Initter):Init()
    end)
    if not success then
        table.insert(InitErrors, {
            module = "ReplicatedStorage.Initter",
            error = result
        })
        warn("Failed to initialize ReplicatedStorage.Initter:", result)
    end
    RSDone = true
end)

-- Timeout protection
local initStartTime = os.clock()
local initTimeout = 60
while not (SSSDone and RSDone) do
    if os.clock() - initStartTime > initTimeout then
        warn("Server initialization timeout after 60 seconds")
        break
    end
    task.wait(0.1)
end

if CanBenchmark then
    table.sort(loadTimes, function(a, b)
        return a.time > b.time
    end)

    print("Total modules loaded:", totalModules)
    print("Top 5 slowest modules:")

    for index = 1, math.min(5, #loadTimes) do
        local info = loadTimes[index]
        print(index .. ".", info.name, string.format("(%.5f seconds)", info.time))
    end
    
    if #InitErrors > 0 then
        print("Initialization errors detected:")
        for _, err in ipairs(InitErrors) do
            print("  -", err.module, ":", err.error)
        end
    end
elseif not RunService:IsStudio() then
    local success, utils = pcall(function()
        return require(ReplicatedStorage.Modules.Utils)
    end)
    if success and utils and utils.Credits then
        print(utils.Credits)
    end
end

if #InitErrors > 0 then
    warn("Server initialized with errors. Check logs above.")
else
    print("Server initialized successfully.")
end

workspace:SetAttribute("ServerLoaded", true)
