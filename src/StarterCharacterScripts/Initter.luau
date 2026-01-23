return {
    Init = function(_, Char: Model)
        local Server = Char:FindFirstChild("Server")
        local IsServer = game:GetService("RunService"):IsServer()

        local Location = IsServer and Server or Char

        for _, Module in Location:GetDescendants() do
            if Module == script or not Module:IsA("ModuleScript") or (not IsServer and Module:IsDescendantOf(Server)) then
                continue
            end
        
            debug.setmemorycategory(Module.Name)
            local Code = require(Module)
            if typeof(Code) == "function" then
                Code()
            elseif typeof(Code) == "table" and Code.Init ~= nil and typeof(Code.Init) == "function" then
                Code:Init()
            end
        end

        debug.setmemorycategory("Default")
    end,
}