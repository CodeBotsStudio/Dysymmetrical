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

--- Loads a rig to a player to replace its custom player model.
--- 
--- All of the needed attributes for it to work will be automatically set just in case.
--- 
--- If the rig has an attribute named `KeepRigScripts` set to `true`, none of the scripts inside of the rig will be remmoved.
--- 
--- If not, every single script inside of the rig will be automatically destroyed.
--- 
--- @return The rig that ended up loading into the player.
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
    --get the set service, Replicated or Server Storage
    local Service = game:GetService(ServiceName)
    --if it was mispelled, halt
    if not Service then
        return
    end

    --get the root character folder
    local CharacterFolder = Utils.Instance.FindFirstChild(Service, "Assets.Characters")

    --making a var for the loaded rig
    local Character
    --if there is a skin to be loaded, load it
    if CharacterSkin ~= nil then
        --try to fetch the skin
        Character = Utils.Instance.FindFirstChild(CharacterFolder, `Skins.{CharacterRole}s.{CharacterName}.{CharacterSkin}`)
    end
    --if the character still hasn't been found (either because there was no skin to be found or because it failed to find it), load the character's base rig if possible
    if not Character then
        Character = Utils.Instance.FindFirstChild(CharacterFolder, `{CharacterRole}s.{CharacterName}`)
    end

    return Character
end
--separated in another local function to improve reading LoadCharacter()
local function GetCharacterRig(CharacterRole: string, CharacterName: string, CharacterSkin: string?): Model
    --look in ReplicatedStorage first, then in ServerStorage
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
--- Loads a character onto a player.
--- 
--- If `FuncSettings.Role` or `FuncSettings.Name` aren't specified, or if `FuncSettings.Role` is set to `"Spectator"`, the default player model will load instead as a Spectator.
--- 
--- If they both are, it'll load a character from either `ReplicatedStorage.Assets.Characters` or `ServerStorage.Assets.Characters`.
--- 
--- If `CharacterSkin` is specified and its rig isn't found, then the character's base rig will load instead.
--- 
--- If no rig is found at the end, the default player model will load instead.
--- 
--- @return The rig that ended up loading into the player.
function PlayerRespawnManager.LoadCharacter(Player: Player, FuncSettings: LoadCharacterSettings?): Model
    --defaults
    FuncSettings = FuncSettings or {} :: LoadCharacterSettings

    --load default rig if there is nothing to find or if it's a spectator
    --this last condition can be removed if spectators have a custom preset rig
    if not FuncSettings.Role or not FuncSettings.Name or FuncSettings.Role == "Spectator" then
        return PlayerRespawnManager.LoadRigOntoPlayer(Player, Players:CreateHumanoidModelFromUserIdAsync(Player.UserId))
    end

    --find a character rig
    local CharacterRig = GetCharacterRig(FuncSettings.Role, FuncSettings.Name, FuncSettings.Skin)
    --clone the rig if it is found
    if CharacterRig ~= nil then
        CharacterRig = CharacterRig:Clone()
    end
    --load the character
    --if the rig isn't found, load the default player rig
    local Character = PlayerRespawnManager.LoadRigOntoPlayer(Player, CharacterRig or Players:CreateHumanoidModelFromUserIdAsync(Player.UserId), FuncSettings.LoadCallback)
    --set the role beforehand to make sure everything works fine
    Character:SetAttribute("Role", FuncSettings.Role)
    --set the character specific attributes
    Character:SetAttribute("CharacterName", FuncSettings.Name)
    --if it's nil it won't even show up so i'm not gonna wrap this in an unnecessary if
    Character:SetAttribute("CharacterSkin", FuncSettings.Skin)
    --return le thing
    return Character
end

return PlayerRespawnManager
