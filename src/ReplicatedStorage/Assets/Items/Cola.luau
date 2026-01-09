local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Item = require(ReplicatedStorage.Classes.Item)
local Types = require(ReplicatedStorage.Classes.Types)

return Item.New({
    Name = "Bloxy Cola",
    ToolPrefab = script:FindFirstChild("Cola"),

    Behaviour = function(self: Types.Item)
        print("sssss")
    end,
})