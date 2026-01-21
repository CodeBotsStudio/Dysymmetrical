return {
    CurrentlyInitting = nil,
    Loaded = false,

    Init = function(self)
        local Modules = script.Parent.Modules

        debug.setmemorycategory("DysNetworking")
        self.CurrentlyInitting = "DysNetworking"
        local NetworkModule = Modules.Network
        require(NetworkModule):Init()

        for _, Module in Modules:GetDescendants() do
            if Module == NetworkModule then
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

        self.Loaded = true
    end,
}
