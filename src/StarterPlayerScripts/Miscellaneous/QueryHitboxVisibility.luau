--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local QueryHitboxVisibility = {}

function QueryHitboxVisibility:Init()
    Utils.Player.ObservePlayers(function(i: Player)
        Utils.Character.ObserveCharacter(i, function(char: Model)
            self:_CharSetup(char)
        end)
    end)
end

function QueryHitboxVisibility:_CharSetup(char: Model)
    task.defer(function()
        if not Utils.PlayerData.GetPlayerSetting(LocalPlayer, "Advanced.ShowPlayerHitboxes") then
            return
        end

        if Utils.Instance.FindFirstChild(char, "Hitboxes", true, 3) then
            for _, i in char.Hitboxes:GetChildren() do
                if not i:IsA("BasePart") then
                    continue
                end

                i.Transparency = i:GetAttribute("VisibleTransparency") or 0.75
            end
        end
    end)
end

return QueryHitboxVisibility
