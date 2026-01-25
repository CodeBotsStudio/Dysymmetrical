local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

type BadgeID = number
type BadgeItemList = {
    [BadgeID]: {
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

--[=[
    ADD YOUR BADGE ITEMS HERE
]=]--
local BadgeItemGranter = {}
BadgeItemGranter.BadgesWithItems = {
    -- Here's an example of how a badge in the list could look like:
    -- [0000000000] = {
    --     {
    --         Type = "Character",
    --         Item = {
    --             Role = "Killer",
    --             Name = "NullexVoyd",
    --         },
    --     },
    -- },
} :: BadgeItemList

function BadgeItemGranter:Init()
end

function BadgeItemGranter.CheckPlayer(Player: Player, PlayerData: Folder)
    local PurchasedFolder = PlayerData:FindFirstChild("Purchased")

    local BadgesToCheck = {}
    for ID, _ in BadgeItemGranter.BadgesWithItems do
        table.insert(BadgesToCheck, ID)
    end

    for _, Badges in Utils.Type.SplitTableIntoChunks(BadgesToCheck, 10) do
        local success, ownedBadgeIDs = pcall(function()
            return BadgeService:CheckUserBadgesAsync(Player.UserId, Badges)
        end)

        if not success then
            continue
        end

        for _, ownedID in ownedBadgeIDs do
            local ItemTable = BadgeItemGranter.BadgesWithItems[ownedID]
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

                local Purchased = Utils.Instance.AwaitChild(PurchasedFolder, "Skins."..ItemTable.Item.RootCharacterName, 0) or Utils.PlayerData.CreateMissingPurchasedSkinValue(Player, ItemTable.Item.RootCharacterName)
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

        task.wait(0.1)
    end
end

return BadgeItemGranter
