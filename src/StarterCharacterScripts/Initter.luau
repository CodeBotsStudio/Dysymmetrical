return {
    Init = function(_, Char: Model)
        local Server = Char:FindFirstChild("Server")
        local IsServer = game:GetService("RunService"):IsServer()

        local Location = IsServer and Server or Char

        local AnimationManager = Char:FindFirstChild("AnimationManager")
        if not IsServer then
            require(AnimationManager):Init()
        end

        for _, Module in Location:GetDescendants() do
            if not Module:IsA("ModuleScript") or Module == AnimationManager or (not IsServer and Module:IsDescendantOf(Server)) then
                continue
            end
        
            debug.setmemorycategory(Module.Name)
            local Scr = require(Module)
            if type(Scr) == "table" and Scr["Init"] and type(Scr["Init"]) == "function" then
                Scr:Init()
            end
        end

        debug.setmemorycategory("Default")
    end,
}