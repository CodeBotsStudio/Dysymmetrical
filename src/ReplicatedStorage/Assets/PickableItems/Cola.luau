local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cola = require(ReplicatedStorage.Assets.Items.Cola)
local PickableItem = require(ReplicatedStorage.Classes.Item.PickableItem)
local Utils = require(ReplicatedStorage.Modules.Utils)

return Utils.Type.CopyTable(PickableItem.New({
    ItemEquivalent = Cola,
    DisplayName = "BloxyCola",
    Model = script:FindFirstChild("Cola"),
}))