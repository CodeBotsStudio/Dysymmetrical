--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local QueryHitboxVisibility = {}

function QueryHitboxVisibility:Init()
    for _, i: Player in Players:GetPlayers() do
        self:_SetupPlayer(i)
    end

    Players.PlayerAdded:Connect(function(i: Player)
        self:_SetupPlayer(i)
    end)
end

function QueryHitboxVisibility:_SetupPlayer(Player: Player)
    if Player.Character then
        self:_CharSetup(Player.Character)
    end

    Player.CharacterAdded:Connect(function(char: Model)
        self:_CharSetup(char)
    end)
end

function QueryHitboxVisibility:_CharSetup(char: Model)
    task.defer(function()
        if not Utils:GetPlayerSetting(LocalPlayer, "Advanced.ShowPlayerHitboxes") then
            return
        end

        if Utils:FindFirstChild(char, "Hitboxes", true, 3) then
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
