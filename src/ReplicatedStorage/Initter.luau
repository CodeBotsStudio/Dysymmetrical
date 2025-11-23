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
            self.CurrentlyInitting = i.Name
            require(i):Init()
        end
    end

    Initter.Loaded = true
end

return Initter
