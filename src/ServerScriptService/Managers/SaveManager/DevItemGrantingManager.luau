local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utils)
type DevItemList = {
    [number]: {
        {
            Type: "Character" | "Skin" | "Emote",
            Item: {
                Role: ("Killer" | "Survivor")?,
                Name: string,
                RootCharacterName: string?,
            },
        }
    }
}

local DevItemGrantingManager = {}
DevItemGrantingManager.UsersWithDevItems = {
    [432073982] = { --Dyscarn
        {
            Type = "Character",
            Item = {
                Role = "Killer",
                Name = "NullexVoyd",
            },
        },
    },
} :: DevItemList

function DevItemGrantingManager:Init()
end

function DevItemGrantingManager.CheckPlayer(Player: Player, PlayerData: Folder)
    if not DevItemGrantingManager.UsersWithDevItems[Player.UserId] then
        return
    end

    local PurchasedFolder = PlayerData:FindFirstChild("Purchased")

    for _, ItemTable in DevItemGrantingManager.UsersWithDevItems[Player.UserId] do
        if ItemTable.Type == "Character" then
            if not Utils.Instance.GetCharacterModule(ItemTable.Item.Role, ItemTable.Item.Name) then
                continue
            end

            local Purchased = PurchasedFolder:FindFirstChild(ItemTable.Item.Role.."s")
            if Purchased:FindFirstChild(ItemTable.Item.Name) then
                continue
            end

            local CharValue = Instance.new("NumberValue")
            CharValue.Name = ItemTable.Item.Name
            CharValue.Value = 0
            CharValue:AddTag("PreventSave")
            CharValue.Parent = Purchased
        elseif ItemTable.Type == "Skin" then
            if not Utils.Instance.GetCharacterModule(ItemTable.Item.Role, ItemTable.Item.RootCharacterName, ItemTable.Item.Name) then
                continue
            end

            local Purchased = Utils.Instance.FindFirstChild(PurchasedFolder, "Skins."..ItemTable.Item.RootCharacterName, 0) or Utils.PlayerData.CreateMissingPurchasedSkinValue(Player, ItemTable.Item.RootCharacterName)
            if Purchased:FindFirstChild(ItemTable.Item.Name) then
                continue
            end

            local SkinValue = Instance.new("NumberValue")
            SkinValue.Name = ItemTable.Item.Name
            SkinValue.Value = 0
            SkinValue:AddTag("PreventSave")
            SkinValue.Parent = Purchased
        elseif ItemTable.Type == "Emote" then
            if not Utils.Instance.GetEmoteModule(ItemTable.Item.Name) then
                continue
            end

            local Purchased = PurchasedFolder:FindFirstChild("Emotes")
            if Purchased:FindFirstChild(ItemTable.Item.Name) then
                continue
            end

            local EmoteValue = Instance.new("NumberValue")
            EmoteValue.Name = ItemTable.Item.Name
            EmoteValue.Value = 0
            EmoteValue:AddTag("PreventSave")
            EmoteValue.Parent = Purchased
        end
    end
end

return DevItemGrantingManager
