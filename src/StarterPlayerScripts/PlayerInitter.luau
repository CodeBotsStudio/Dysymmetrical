local PlayerModule = script.Parent.PlayerModule
local ServerScripts = script.Parent.Server

local Player = game:GetService("Players").LocalPlayer

local PlayerInitter = {
    Loaded = false,
    CurrentlyInitting = nil,
    Initting = false,
}

function PlayerInitter:Init()
    if game:GetService("RunService"):IsServer() or self.Initting then
        return
    end

    self.Initting = true

    Player:SetAttribute("BaseFOV", 70)

    for _, i in script.Parent:GetDescendants() do
        if i:IsA("ModuleScript") and i ~= PlayerModule and not i:IsDescendantOf(PlayerModule) and not i:IsDescendantOf(ServerScripts) then
            if i.Name ~= "ModPanel" then
                self.CurrentlyInitting = i.Name
            end
    		local Scr = require(i)
    		if type(Scr) == "table" and Scr.Init and type(Scr.Init) == "function" then
    			Scr:Init()
    		end
    	end
    end

    self.Loaded = true
end

return PlayerInitter
