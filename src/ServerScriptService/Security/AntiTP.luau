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
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model)
            AntiTP._SetupCharacter(Player)
        end)
        Player.CharacterRemoving:Connect(function(_Character: Model)
            if not AntiTP.PlayerThreads[Player.UserId] then
                return
            end

            AntiTP.PlayerThreads[Player.UserId]:Disconnect()
            AntiTP.PlayerThreads[Player.UserId] = nil
        end)
    end)

    Players.PlayerRemoving:Connect(function(Player: Player)
        if AntiTP.PlayerThreads[Player.UserId] then
            AntiTP.PlayerThreads[Player.UserId]:Disconnect()
            AntiTP.PlayerThreads[Player.UserId] = nil
        end
    end)
end

function AntiTP._SetupCharacter(Player: Player)
    local Character = Player.Character
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    local HRP = Utils.Character.GetRootPart(Player)

    local LastPos = HRP.Position

    self.PlayerThreads[Player.UserId] = RunService.PostSimulation:Connect(function()
        local PosDiff = HRP.Position - LastPos

        if PosDiff.Magnitude > AntiTP.PositionMagnitudeThreshold then
            if AntiTP.KickAllowed then
                CommonFunctions.KickPlayer(Player, CommonFunctions.KickIDs.TPing)
                return
            end

            Utils.Misc.Print("Killing "..Player.Name..": TP detected")
            Humanoid.Health = 0
        end

        LastPos = HRP.Position
    end)
end

return AntiTP
