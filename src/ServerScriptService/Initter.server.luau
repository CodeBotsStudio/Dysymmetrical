local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CanBenchmark = RunService:IsStudio() and workspace:GetAttribute("DebugAllowed")

local SSSDone = false
local RSDone = false

local totalModules = 0
local loadTimes = {}

local function InitModule(i)
    local Scr = require(i)
    if typeof(Scr) == "table" and typeof(Scr.Init) == "function" then
        Scr:Init()
    end
end

task.spawn(function()
    for _, i in script.Parent:GetDescendants() do
        if i:IsA("ModuleScript") then
            totalModules += 1

            if CanBenchmark then
                local start = os.clock()
                pcall(InitModule, i)
                local duration = os.clock() - start

                table.insert(loadTimes, {
                    name = i:GetFullName(),
                    time = duration
                })
            else
                pcall(InitModule, i)
            end
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

    for i = 1, math.min(5, #loadTimes) do
        local info = loadTimes[i]
        print(i .. ".", info.name, string.format("(%.5f seconds)", info.time))
    end
elseif not RunService:IsStudio() then
    print(require(ReplicatedStorage.Modules.Utils).Credits)
end

workspace:SetAttribute("ServerLoaded", true)
