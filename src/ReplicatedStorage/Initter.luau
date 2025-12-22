local Initter = {
    CurrentlyInitting = nil,
    Loaded = false,
}

function Initter:Init()
    debug.setmemorycategory("DysNetworking")
    self.CurrentlyInitting = "DysNetworking"
    require(script.Parent.Modules.Network):Init()
    for _, Module in ipairs(script.Parent.Modules:GetDescendants()) do
        if Module.Name == "Network" then
            continue
        end
        if Module:IsA("ModuleScript") and not Module:HasTag("PreventInit") then
            debug.setmemorycategory(Module.Name)
            self.CurrentlyInitting = Module.Name
            local Code = require(Module)
            if Code.Init ~= nil and typeof(Code.Init) == "function" then
                Code:Init()
            end
        end
    end

    debug.setmemorycategory("Default")

    Initter.Loaded = true
end

return Initter
