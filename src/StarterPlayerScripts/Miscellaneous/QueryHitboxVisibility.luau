--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local QueryHitboxVisibility = {}

function QueryHitboxVisibility:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(char: Model)
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
            for _, Hitbox in char.Hitboxes:GetChildren() do
                if not Hitbox:IsA("BasePart") then
                    continue
                end

                Hitbox.Transparency = Hitbox:GetAttribute("VisibleTransparency") or 0.75
            end
        end
    end)
end

return QueryHitboxVisibility
