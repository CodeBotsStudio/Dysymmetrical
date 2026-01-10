local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Medkit = require(ReplicatedStorage.Assets.Items.Medkit)
local PickableItem = require(ReplicatedStorage.Classes.Item.PickableItem)
local Utils = require(ReplicatedStorage.Modules.Utils)

return Utils.Type.CopyTable(PickableItem.New({
    ItemEquivalent = Medkit,
    DisplayName = "Medkit",
    Model = script:FindFirstChild("Medkit"),
}))