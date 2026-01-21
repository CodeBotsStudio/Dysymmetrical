return {
    Loaded = false,
    CurrentlyInitting = nil,
    Initting = false,
    Init = function(self)
        if self.Initting then
            return
        end

        self.Initting = true

        game:GetService("Players").LocalPlayer:SetAttribute("BaseFOV", 70)

        local PlayerModule = script.Parent.PlayerModule

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
    end,
}
