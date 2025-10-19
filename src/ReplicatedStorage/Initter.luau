local Initter = {
    CurrentlyInitting = nil,
    Loaded = false,
}

function Initter:Init()
    self.CurrentlyInitting = "DysNetworking"
    require(script.Parent.Modules.Network):Init()
    for _, i in ipairs(script.Parent.Modules:GetDescendants()) do
        if i.Name == "Network" then
            continue
        end
        if i:IsA("ModuleScript") and not i:HasTag("PreventInit") then
            pcall(function()
                local Scr = require(i)
    		    if type(Scr) == "table" and Scr["Init"] and type(Scr["Init"]) == "function" then
                    if i.Name ~= "ModPanel" then
                        self.CurrentlyInitting = i.Name
                    end
    		    	Scr:Init()
    		    end
            end)
        end
    end

    Initter.Loaded = true
end

return Initter
