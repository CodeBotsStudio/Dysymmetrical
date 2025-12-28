local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        Utils.Character.ObserveCharacter(Players.LocalPlayer, function(Char: Model)
            local Server = Char:FindFirstChild("Server")

            for _, Module in Char:GetDescendants() do
            	if not Module:IsA("ModuleScript") or Module:IsDescendantOf(Server) then
            		continue
            	end
            
            	debug.setmemorycategory(Module.Name)
            	local Scr = require(Module)
            	if type(Scr) == "table" and Scr["Init"] and type(Scr["Init"]) == "function" then
            		Scr:Init()
            	end
            end

            debug.setmemorycategory("Default")
        end)
    end,
}