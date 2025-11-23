--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    Network:SetConnection("BuyItem", "REMOTE_FUNCTION", function(SourcePlayer: Player, Module: ModuleScript, Quotation: boolean?)
        if Quotation == nil then
            Quotation = true
        end

        local ItemType = Module.Parent
        if ItemType.Parent.Parent.Name == "Skins" then
            ItemType = ItemType.Parent.Parent
        end
        ItemType = ItemType.Name
        local Money = Utils:FindFirstChild(SourcePlayer, "PlayerData.Stats.Currency.Money")
        local NetWorth = Utils:FindFirstChild(SourcePlayer, "PlayerData.Stats.Currency.NetWorth")
        local Price = require(Module).Config.Price

        if Price > Money.Value then
            return false
        else
            Money.Value -= Price
            NetWorth.Value += Price

            local Product = Instance.new("IntValue")
            Product.Name = Module.Name
            Product.Value = 0

            local Parent = SourcePlayer.PlayerData.Purchased[ItemType]
            if ItemType == "Skins" then
                Parent = Parent:FindFirstChild(Module.Parent.Name) or Utils:CreateMissingPurchasedSkinValue(SourcePlayer, Module.Parent.Name)
            end

            Product.Parent = Parent

            Network:FireClientConnection(SourcePlayer, "ShowRewardNotification", "REMOTE_EVENT", Module, "QuotedSkin")

            return true
        end
    end)
end