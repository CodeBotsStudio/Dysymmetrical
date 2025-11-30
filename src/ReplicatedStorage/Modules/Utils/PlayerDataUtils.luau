local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Modules.Network)
local InstanceUtils = require(script.Parent.InstanceUtils)
local TypeUtils = require(script.Parent.TypeUtils)

local PlayerDataUtils = {}

--- Retrieves a player's equipped item of a type through a string path.
--- Also works for emotes.
--- If `value` is false, it'll return the `StringValue` object instead of the value itself.
function PlayerDataUtils.GetPlayerEquipped(Player: Player, path: string, value: boolean?): StringValue | string
    if value == nil then
        value = true
    end

    local splitPath = TypeUtils.SplitStringPath(path)
    local Equipped = InstanceUtils.FindFirstChild(Player, "PlayerData.Equipped", 5)
    if #splitPath == 1 then
        local Child = Equipped:FindFirstChild(splitPath[1])
        return value and Child.Value or Child
    else
        local Child = Equipped
        for _, step in splitPath do
            if not Child then
                warn("[Utils:GetPlayerEquipped()] Child \""..step.."\" not found! Returning nil!")
                -- actually returning nil but preventing selene from crying
                return Child
            end

            if Child.Name == "Skins" then
                Child = Child:FindFirstChild(step)

                if not Child then
                    if RunService:IsServer() then
                        Child = PlayerDataUtils.CreateMissingSkinValue(Player, step)
                    else
                        Child = Network:FireServerConnection("CreateMissingSkinValue", "REMOTE_FUNCTION", step)
                    end
                end

                continue
            end
            
            Child = Child:FindFirstChild(step)
        end
        return value and Child.Value or Child
    end
end

--- Retrieves a player's purchased item of a type through a string path.
--- Also works for emotes.
--- If `value` is false, it'll return the `StringValue` object instead of the value itself.
function PlayerDataUtils.GetPlayerOwned(Player: Player, path: string, value: boolean?): StringValue | string
    if value == nil then
        value = true
    end

    local PurchasedFolder = InstanceUtils.FindFirstChild(Player, "PlayerData.Purchased", 5)
    local Child = InstanceUtils.FindFirstChild(PurchasedFolder, path, 0)
    return value and (Child and Child.Value or false) or Child
end

--- Retrieves a player's stat through a string path.
--- If `value` is false, it'll return the `ValueBase` object instead of the value itself to modify it or to get a property from it (e.g. attributes).
function PlayerDataUtils.GetPlayerStat(Player: Player, path: string, value: boolean?): ValueBase | any
    if value == nil then
        value = true
    end

    local Stats = InstanceUtils.FindFirstChild(Player, "PlayerData.Stats", 5)
    local Stat = InstanceUtils.FindFirstChild(Stats, path, 0)
    return value and Stat.Value or Stat
end

--- Retrieves a player's setting value through a string path.
function PlayerDataUtils.GetPlayerSetting(Player: Player, path: string): any
    local splitPath = TypeUtils.SplitStringPath(path)
    local PlayerSettings = InstanceUtils.FindFirstChild(Player, "PlayerData.Settings", 5)
    if #splitPath == 1 then
        return PlayerSettings:FindFirstChild(splitPath[1]).Value
    else
        local Setting = PlayerSettings
        for _, step in splitPath do
            if not Setting then
                warn("[Utils:GetPlayerSetting()] Child \""..step.."\" not found! Returning nil!")
                return
            end
            Setting = Setting:FindFirstChild(step)
        end
        return Setting.Value
    end
end

--- INTERNAL | SERVER FUNCTION: Used to create a character's equipped skin value for a player if it's missing.
function PlayerDataUtils.CreateMissingSkinValue(SourcePlayer: Player, name: string)
    if not RunService:IsServer() then
        return
    end

    local EquippedSkins = InstanceUtils.FindFirstChild(SourcePlayer, "PlayerData.Equipped.Skins", 5)
    local SkinValue = InstanceUtils.FindFirstChild(EquippedSkins, name, 0)
    if SkinValue then
        return SkinValue
    end

    SkinValue = Instance.new("StringValue")
    SkinValue.Name = name
    SkinValue.Value = ""
    SkinValue.Parent = EquippedSkins

    return SkinValue
end

--- INTERNAL | SERVER FUNCTION: Used to create a character's purchased skin value for a player if it's missing.
function PlayerDataUtils.CreateMissingPurchasedSkinValue(SourcePlayer: Player, name: string)
    if not RunService:IsServer() then
        return
    end

    local PurchasedSkins = InstanceUtils.FindFirstChild(SourcePlayer, "PlayerData.Purchased.Skins", 5)
    local SkinFolder = InstanceUtils.FindFirstChild(PurchasedSkins, name, 0)
    if SkinFolder then
        return SkinFolder
    end

    SkinFolder = Instance.new("Folder")
    SkinFolder.Name = name
    SkinFolder.Parent = PurchasedSkins

    return SkinFolder
end

return PlayerDataUtils
