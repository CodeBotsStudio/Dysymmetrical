local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CommonFunctions = require(ServerScriptService.System.CommonFunctions)
local Utils = require(ReplicatedStorage.Modules.Utils)

local AntiTP = {
    KickAllowed = false,
    PlayerThreads = {},
    PositionMagnitudeThreshold = 500,
}

function AntiTP:Init()
    Players.PlayerAdded:Connect(function(Player: Player)
        Player.CharacterAdded:Connect(function(Character: Model)
            self:_SetupCharacter(Player, Character)
        end)
        Player.CharacterRemoving:Connect(function(Character: Model)
            if not self.PlayerThreads[Player.UserId] then
                return
            end

            self.PlayerThreads[Player.UserId]:Disconnect()
            self.PlayerThreads[Player.UserId] = nil
        end)
    end)

    Players.PlayerRemoving:Connect(function(Player: Player)
        if self.PlayerThreads[Player.UserId] then
            self.PlayerThreads[Player.UserId]:Disconnect()
            self.PlayerThreads[Player.UserId] = nil
        end
    end)

    for _, i in Players:GetPlayers() do
        if i.Character then
            self:_SetupCharacter(i, i.Character)
        end
    end
end

function AntiTP:_SetupCharacter(Player: Player, Character: Model)
    local HRP = Utils:FindFirstChild(Character, "HumanoidRootPart")
    local Humanoid = Utils:FindFirstChild(Character, "Humanoid")

    local LastPos = HRP.Position

    self.PlayerThreads[Player.UserId] = RunService.PostSimulation:Connect(function()
        local PosDiff = HRP.Position - LastPos

        if PosDiff.Magnitude > self.PositionMagnitudeThreshold then
            if self.KickAllowed then
                CommonFunctions:KickPlayer(Player, CommonFunctions.KickIDs.TPing)
                return
            end

            Utils:Print("Killing "..Player.Name..": TP detected")
            Humanoid.Health = 0
        end

        LastPos = HRP.Position
    end)
end

return AntiTP
