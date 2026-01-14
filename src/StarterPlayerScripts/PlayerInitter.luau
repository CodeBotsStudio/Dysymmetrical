local PlayerModule = script.Parent.PlayerModule

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

    for _, Module in script.Parent:GetDescendants() do
        if not (Module:IsA("ModuleScript") and Module ~= script and Module ~= PlayerModule and not Module:IsDescendantOf(PlayerModule)) then
            continue
    	end

        if Module.Name ~= "ModPanel" then
            self.CurrentlyInitting = Module.Name
        end
        debug.setmemorycategory(Module.Name)
    	local Scr = require(Module)
    	if type(Scr) == "table" and Scr.Init and type(Scr.Init) == "function" then
    		Scr:Init()
    	end
    end

    debug.setmemorycategory("Default")

    self.Loaded = true
end

return PlayerInitter
