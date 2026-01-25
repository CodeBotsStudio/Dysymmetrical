local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local CharacterManager = require(script.Parent.CharacterManager)
local Utils = require(ReplicatedStorage.Modules.Utils)

local PlayerRespawnManager = {
    PendingAutoRespawns = {},
}

function PlayerRespawnManager:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveHumanoid(Player, function(Humanoid: Humanoid)
            Utils.Character.ObserveOnDeath(Humanoid, function()
                --sets a thread to wait for 3 seconds to respawn the player automatically
                PlayerRespawnManager.PendingAutoRespawns[Player.UserId] =
                    task.delay(3, CharacterManager.LoadDefaultCharacter, Player)
            end)
        end)
    end)
end

--- Cancels a player's automatic respawn if it's scheduled.
function PlayerRespawnManager.CancelAutoRespawn(Player: Player)
    --if the respawn isn't scheduled, halt
    if not PlayerRespawnManager.PendingAutoRespawns[Player.UserId] then
        return
    end

    --if the respawn isn't already happening, cancel the thing
    if coroutine.running() ~= PlayerRespawnManager.PendingAutoRespawns[Player.UserId] then
        task.cancel(PlayerRespawnManager.PendingAutoRespawns[Player.UserId])
        PlayerRespawnManager.PendingAutoRespawns[Player.UserId] = nil
    end
end

--- Loads a player's character directly, as a spectator.
function PlayerRespawnManager.LoadDefaultCharacter(Player: Player): Model
    if not Player.Parent then
        return
    end

    --prevent next automatic respawn
    PlayerRespawnManager.CancelAutoRespawn(Player)
    --respawn
    local Character = Players:CreateHumanoidModelFromUserIdAsync(Player.UserId)
    --removing all scripts generated
    for _, Script in Character:GetDescendants() do
        if not Script:IsA("BaseScript") then
            continue
        end

        Script:Destroy()
    end
    --renaming
    Character.Name = Player.Name
    --clone all stuff from startercharacterscripts over to the new character
    for _, Item in StarterPlayer.StarterCharacterScripts:GetChildren() do
        Item:Clone().Parent = Character
    end
    --replace some humanoid properties
    do
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end
    --add missing core attributes
    CharacterManager._SetupDefaultAttributes(Character)
    --parent the character to the folder properly
    Character.Parent = workspace.Players
    --TODO: fix character respawning disabling all UI and locking the camera in place for no apparent reason at all
    --actually sets the character and fires CharacterAdded
    Player.Character = Character

    return Character
end

return PlayerRespawnManager
