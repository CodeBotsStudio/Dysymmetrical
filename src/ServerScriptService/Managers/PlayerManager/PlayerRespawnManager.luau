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
                    task.delay(3, PlayerRespawnManager.LoadCharacter, Player)
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
function PlayerRespawnManager.LoadRigOntoPlayer(Player: Player, Character: Model, Callback: ((Character: Model, Humanoid: Humanoid) -> ())?): Model
    if not Player.Parent then
        return
    end

    --prevent next automatic respawn
    PlayerRespawnManager.CancelAutoRespawn(Player)
    --removing all scripts generated if allowed
    if not Character:GetAttribute("KeepRigScripts") then
        for _, Script in Character:GetDescendants() do
            if not Script:IsA("BaseScript") then
                continue
            end

            Script:Destroy()
        end
    end
    --renaming
    Character.Name = Player.Name
    local Root = Utils.Character.GetRootPart(Character)
    Character.PrimaryPart = Root
    --clone all stuff from startercharacterscripts over to the new character
    for _, Item in StarterPlayer.StarterCharacterScripts:GetChildren() do
        Item:Clone().Parent = Character
    end
    --replace some humanoid properties
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    --add missing core attributes
    CharacterManager._SetupDefaultAttributes(Character)
    --parent the character to the folder properly
    Character.Parent = workspace.Players
    --actually sets the character and fires CharacterAdded
    Player.Character = Character

    if Callback then
        Callback(Character, Humanoid)
    end

    return Character
end

local function _GetCharacterRigFromService(ServiceName: "ReplicatedStorage"  | "ServerStorage", CharacterRole: string, CharacterName: string, CharacterSkin: string?): Model
    local Service = game:GetService(ServiceName)
    if not Service then
        return
    end

    local CharacterFolder = Utils.Instance.FindFirstChild(Service, "Assets.Characters")

    local Path = `{CharacterRole}s.{CharacterName}`
    if CharacterSkin ~= nil then
        Path = `Skins.{Path}.{CharacterSkin}`
    end

    local Character = Utils.Instance.FindFirstChild(CharacterFolder, Path) --using Utils.Instance.FindFirstChild() for using path strings
    return Character
end
local function GetCharacterRig(CharacterRole: string, CharacterName: string, CharacterSkin: string?): Model
    return
        _GetCharacterRigFromService("ReplicatedStorage", CharacterRole, CharacterName, CharacterSkin)
        or _GetCharacterRigFromService("ServerStorage", CharacterRole, CharacterName, CharacterSkin)
end

type LoadCharacterSettings = {
    Role: ("Killer" | "Survivor" | "Spectator")?,
    Name: string?,
    Skin: string?,
    LoadCallback: ((Character: Model, Humanoid: Humanoid) -> ())?,
}
function PlayerRespawnManager.LoadCharacter(Player: Player, FuncSettings: LoadCharacterSettings?): Model
    FuncSettings = FuncSettings or {} :: LoadCharacterSettings

    if not FuncSettings.Role or not FuncSettings.Name then
        print("loading default")
        return PlayerRespawnManager.LoadRigOntoPlayer(Player, Players:CreateHumanoidModelFromUserIdAsync(Player.UserId))
    end

    local CharacterRig = GetCharacterRig(FuncSettings.Role, FuncSettings.Name, FuncSettings.Skin)
    if CharacterRig ~= nil then
        CharacterRig = CharacterRig:Clone()
    end
    return PlayerRespawnManager.LoadRigOntoPlayer(Player, CharacterRig or Players:CreateHumanoidModelFromUserIdAsync(Player.UserId), FuncSettings.LoadCallback)
end

return PlayerRespawnManager
