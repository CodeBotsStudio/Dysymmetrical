--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local ServerCharacterManager = RunService:IsServer() and require(ServerScriptService.Managers.ServerCharacterManager) or nil

return {
    Name = "Turn Player Into Killer/Survivor",
    Executable = true,
    Params = {
        {
            Title = "Chosen Player",
            Type = "Player",
            Default = "...",
        },
        {
            Title = "Character Type",
            Default = "...",
            Cache = {
                Options = {
                    "Survivor",
                    "Killer",
                },
            },
        },
    },
    Executed = function(self, Player: string, Type: "Survivor" | "Killer")
        if typeof(Player) ~= "string" then
            return
        end

        if not table.find(self.Params[2].Cache.Options, Type) then
            return
        end

        if Player:lower() == "all" then
            for _, PlayerChar in Players:GetPlayers() do
                task.spawn(function()
                    ServerCharacterManager.SetupCharacter(PlayerChar, Utils.PlayerData.GetPlayerEquipped(PlayerChar, Type), Type)
                end)
            end
            return
        end

        Player = Players:FindFirstChild(Player)
        ServerCharacterManager.SetupCharacter(Players:FindFirstChild(Player), Utils.PlayerData.GetPlayerEquipped(Player, Type), Type)
    end,
}