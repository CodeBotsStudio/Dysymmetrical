local SSSDone = false
local RSDone = false

local totalModules = 0
local loadTimes = {}

task.spawn(function()
    for _, i in script.Parent:GetDescendants() do
        if i:IsA("ModuleScript") then
            totalModules += 1

            local start = os.clock()
            pcall(function()
                local Scr = require(i)
                if type(Scr) == "table" and type(Scr.Init) == "function" then
                    Scr:Init()
                end
            end)
            local duration = os.clock() - start

            table.insert(loadTimes, {
                name = i:GetFullName(),
                time = duration
            })
        end
    end
    SSSDone = true
end)

task.spawn(function()
    require(game.ReplicatedStorage.Initter):Init()
    RSDone = true
end)

repeat task.wait() until SSSDone and RSDone

if game:GetService("RunService"):IsStudio() then
    table.sort(loadTimes, function(a, b)
        return a.time > b.time
    end)

    print("Total modules loaded:", totalModules)
    print("Top 5 slowest modules:")

    for i = 1, math.min(5, #loadTimes) do
        local info = loadTimes[i]
        print(i .. ".", info.name, string.format("(%.5f seconds)", info.time))
    end
end

workspace:SetAttribute("ServerLoaded", true)

if not game:GetService("RunService"):IsStudio() then
    print(require(game.ReplicatedStorage.Modules.Utils).Credits)
end
