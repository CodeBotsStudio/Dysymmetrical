local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Network = require(ReplicatedStorage.Modules.Network)
local ModPanelManager = {
    Admins = {
        432073982, --Dyscarn
    },

    Commands = {},
}

function ModPanelManager:Init()
    for _, CommandScript in ServerScriptService.ModeratorCommands:GetChildren() do
        if not CommandScript:IsA("ModuleScript") then
            continue
        end
        ModPanelManager.Commands[CommandScript.Name] = require(CommandScript)
    end

    for _, i in Players:GetPlayers() do
        ModPanelManager:_CheckPlayer(i)
    end

    Players.PlayerAdded:Connect(function(Player: Player)
        ModPanelManager:_CheckPlayer(Player)
    end)

    Network:SetConnection("ExecuteCommand", "REMOTE_EVENT", function(Player: Player, CommandName: string, ...)
        if not ModPanelManager:_IsPlayerMod(Player) or ModPanelManager.Commands[CommandName] == nil then
            return
        end
        
        ModPanelManager.Commands[CommandName]:Execute(...)
    end)
end

function ModPanelManager:_CheckPlayer(Player: Player)
    if not ModPanelManager:_IsPlayerMod(Player) then
        return
    end

    task.wait(2)

    Network:FireClientConnection(Player, "InitModPanel", "REMOTE_EVENT")
end

function ModPanelManager:_IsPlayerMod(Player: Player)
    return table.find(ModPanelManager.Admins, Player.UserId)
end

return ModPanelManager
