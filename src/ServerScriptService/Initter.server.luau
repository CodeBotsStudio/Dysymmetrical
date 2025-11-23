--- Module just used to init all server module scripts.

local SSSDone = false
local RSDone = false

task.spawn(function()
    for _, i in script.Parent:GetDescendants() do
        if i:IsA("ModuleScript") then
            pcall(function()
                local Scr = require(i)
    		    if type(Scr) == "table" and Scr["Init"] and type(Scr["Init"]) == "function" then
    		    	Scr:Init()
    		    end
            end)
        end
    end
    SSSDone = true
end)

task.spawn(function()
    require(game:GetService("ReplicatedStorage").Initter):Init()
    RSDone = true
end)

repeat task.wait()
until SSSDone and RSDone

workspace:SetAttribute("ServerLoaded", true)

if not game:GetService("RunService"):IsStudio() then
    print(require(game:GetService("ReplicatedStorage").Modules.Utils).Credits)
end
