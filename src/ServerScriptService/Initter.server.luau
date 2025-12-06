local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CanBenchmark = RunService:IsStudio() and workspace:GetAttribute("DebugAllowed")

local SSSDone = false
local RSDone = false

local totalModules = 0
local loadTimes = {}

local function InitModule(Module: ModuleScript)
    local Scr = require(Module)
    if typeof(Scr) == "table" and typeof(Scr.Init) == "function" then
        Scr:Init()
    end
end

task.spawn(function()
    for _, Module in script.Parent:GetDescendants() do
        if not Module:IsA("ModuleScript") then
            continue
        end

        totalModules += 1

        if CanBenchmark then
            local start = os.clock()
            pcall(InitModule, Module)
            local duration = os.clock() - start

            table.insert(loadTimes, {
                name = Module:GetFullName(),
                time = duration
            })
        else
            pcall(InitModule, Module)
        end
    end
    SSSDone = true
end)

task.spawn(function()
    require(ReplicatedStorage.Initter):Init()
    RSDone = true
end)

repeat task.wait() until SSSDone and RSDone

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
elseif not RunService:IsStudio() then
    print(require(ReplicatedStorage.Modules.Utils).Credits)
end

workspace:SetAttribute("ServerLoaded", true)
