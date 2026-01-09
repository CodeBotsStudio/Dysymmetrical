local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local QueryHitboxVisibility = {
    ShowOtherPlayersHitbox = false,
}

function QueryHitboxVisibility:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        if not self.ShowOtherPlayersHitbox and Player ~= Players.LocalPlayer then
            return
        end
        Utils.Character.ObserveCharacter(Player, function(char: Model)
            self._CharSetup(char)
        end)
    end)
end

function QueryHitboxVisibility._CharSetup(char: Model)
    task.defer(function()
        if not Utils.PlayerData.GetPlayerSetting(LocalPlayer, "Advanced.ShowPlayerHitboxes") then
            return
        end

        local Hitboxes = char:FindFirstChild("Hitboxes")
        if Hitboxes then
            for _, Hitbox in Hitboxes:GetChildren() do
                if not Hitbox:IsA("BasePart") then
                    continue
                end

                Hitbox.Transparency = Hitbox:GetAttribute("VisibleTransparency") or 0.75
            end
        end
    end)
end

return QueryHitboxVisibility
