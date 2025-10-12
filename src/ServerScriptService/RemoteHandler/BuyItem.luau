--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
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
        
        local Money = SourcePlayer.PlayerData.Stats.Currency.Money
        local Price = require(Module).Config.Price

        if Price > Money.Value then
            return false
        else
            Money.Value -= Price

            local Product = Instance.new("IntValue")
            Product.Name = Module.Name
            Product.Value = 0

            local Parent = SourcePlayer.PlayerData.Purchased[ItemType]
            if ItemType == "Skins" then
                Parent = Parent:FindFirstChild(Module.Parent.Name) or CommonUtils:CreateMissingPurchasedSkinValue(SourcePlayer, Module.Parent.Name)
            end

            Product.Parent = Parent

            Network:FireClientConnection(SourcePlayer, "ShowRewardNotification", "REMOTE_EVENT", Module, "QuotedSkin")

            return true
        end
    end)
end