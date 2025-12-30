--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MapManager = require(ServerScriptService.Managers.MapManager)
local ServerCharacterManager = require(ServerScriptService.Managers.ServerCharacterManager)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local TimeManager = require(ServerScriptService.Managers.TimeManager)
local CommonFunctions = require(ServerScriptService.System.CommonFunctions)

local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState
local PlayersRemaining: Folder = ReplicatedStorage.RoundInfo.PlayersRemaining

local RoundManager = {
    Utils = {},
    Callables = {},
    Threads = {},
    PlayerConnections = {},
    CurrentRound = {
        PlayersAccepted = {},
        PlayersRemaining = {},
        Killers = {
            {
                Player = nil,
                Character = nil,
            },
        },
        KillerIndex = {},
        StartedLMS = false,
    },
    StopLoop = false,
    CanSpawnKiller = true, --for debugging purposes
    CanInitLMS = true, --for debugging purposes
}

function RoundManager:Init()
    RoundManager.CurrentRound.Killers = {}
    TimeManager.OnTimerEnd = function()
        RoundManager.StartRound()
    end
end

--- Starts the round right away. There's no more mystery to it.
--- Chooses a killer, resets their malice, increases everyone else's in the round by 1, spawns a map, sets up all characters, sets the round time and plays the killer intro. 
function RoundManager.StartRound()
    local LoadedPlayers = Utils.Player.GetLoadedPlayers(false)
    Utils.Player.Fade(LoadedPlayers, "In", 0.6, true)
    
    --shuffling so that if there's a tie it chooses a truly random one
    RoundManager.CurrentRound.PlayersAccepted = Utils.Type.ShuffleTable(LoadedPlayers)

    --orders players by malice to choose later
    local PlayersOrderedByMalice = RoundManager.CurrentRound.PlayersAccepted
    table.sort(PlayersOrderedByMalice, function(a, b)
        return Utils.PlayerData.GetPlayerStat(a, "General.Malice") > Utils.PlayerData.GetPlayerStat(b, "General.Malice")
    end)

    --spawns in the map
    MapManager.GetRandomMap()
    
    --gets the killers for the round
    for killerIndex = 1, workspace:GetAttribute("KillersAllowed") do
        RoundManager.CurrentRound.Killers[killerIndex] = {
            Player = PlayersOrderedByMalice[killerIndex],
            Character = nil
        }
        RoundManager.CurrentRound.KillerIndex[PlayersOrderedByMalice[killerIndex]] = killerIndex
    end

    --sets up every player
    for index, Player: Player in PlayersOrderedByMalice do
        local IsKiller = index <= workspace:GetAttribute("KillersAllowed")
        RoundManager.Utils.SetupPlayer(Player, IsKiller and index or nil)

        --if it's a survivor then add it to the PlayersRemaining list
        if RoundManager.CanSpawnKiller and IsKiller then
            continue
        end

        RoundManager.CurrentRound.PlayersRemaining[Player.UserId] = Player
    end

    if RoundManager.CanSpawnKiller then --if one is testing survivor then the round'll never end
        for playerIndex = #RoundManager.CurrentRound.PlayersRemaining, 1, -1 do
            if not table.find(RoundManager.CurrentRound.Killers, RoundManager.CurrentRound.PlayersRemaining[playerIndex]) then
                continue
            end

            table.remove(RoundManager.CurrentRound.PlayersRemaining, playerIndex)
        end
    end
    Utils.Misc.Print(RoundManager.CurrentRound.PlayersRemaining)

    --round vars setup
    RoundState.Value = "InRound"
    TimeManager:SetTime(TimeManager.Config.RoundTime)
    TimeManager.OnTimerEnd = function()
        RoundManager.Callables.EndRound("Survivors")
    end
    workspace:SetAttribute("LMS", false)
    
    --state loop check
    task.defer(function()
        while task.wait(1) do
            if RoundManager.StopLoop then
                RoundManager.StopLoop = false
                break
            end

            RoundManager.Utils.CheckForKillerWin()
        end
    end)

    --final call to begin the round
    RoundManager.Callables.PlayIntro()
end

--- Function called right when starting a round to unanchor every player after the default intro duration.
--- Also removes the black fade from all players if there's no killer.
function RoundManager.Callables.PlayIntro()
    if not RoundManager.CanSpawnKiller then
        Utils.Player.Fade(Utils.Player.GetLoadedPlayers(false), "Out", 0.6, false)
    end
    --whatever happens after since every intro lasts the same
    RoundManager.Threads["IntroEndingThread"] = task.delay(3, function()
        TimeManager.CanDecreaseTime = true
        for _, player: Player in RoundManager.CurrentRound.PlayersAccepted do
            player.Character.HumanoidRootPart.Anchored = false --handled from server
        end
    end)
end

--- Initiates the Last Man Standing sequence (1v1). The Last Man (survivor) must be specified.
function RoundManager.Callables.InitLMS(LastMan: Player)
    --failsafe
    if not RoundManager.CanInitLMS or RoundManager.CurrentRound.StartedLMS or not RoundManager.CurrentRound.Killers[1] or not RoundManager.CurrentRound.Killers[1].Character then
        return
    end

    RoundManager.CurrentRound.StartedLMS = true
    workspace:SetAttribute("LMS", true)

    --reveals auras
    for _, Killer in RoundManager.CurrentRound.Killers do
        Utils.Player.RevealPlayerAuraTo(Killer.Player, LastMan, 10)
        Utils.Player.RevealPlayerAuraTo(LastMan, Killer.Player, 10)
    end

    --duh
    TimeManager:SetTime(TimeManager.Config.LastManStandingTime)

    Network:FireConnection("LMSVoiceline", LastMan)

    --plays the music
    --i'm sure that there's a better way to check special LMS's
    local Mod = require(Utils.Instance.GetCharacterModule("Killer", RoundManager.CurrentRound.Killers[1].Character:GetAttribute("CharacterName"), RoundManager.CurrentRound.Killers[1].Character:GetAttribute("CharacterSkinName")))
    local SpecialLMS = Mod.Config.SpecialLastManStandings
    local Specials = SpecialLMS[LastMan.Character:GetAttribute("CharacterName")]
    
    local Theme = Specials and (Specials[LastMan.Character:GetAttribute("CharacterSkinName")] or Specials["Default"] or Mod.Config.LastManStandingTheme) or Mod.Config.LastManStandingTheme
    Sounds.PlayTheme(Theme, {Name = "LMS", Priority = 999999, TweenTime = 0, Volume = 1, TimePosition = 0})
end

--- Ends the round. Whoever won is specified by the `winner` parameter.
function RoundManager.Callables.EndRound(winner: "Survivors" | "Killer")
    --cancelling threads and disconnecting connections
    RoundManager.StopLoop = true
    for _, Thread in RoundManager.Threads do
        task.cancel(Thread)
    end
    table.clear(RoundManager.Threads)
    --no more music!!1!
    Sounds.StopTheme("LMS", 0)

    workspace:SetAttribute("LMS", false)

    for _, Connections: {RBXScriptConnection} in RoundManager.PlayerConnections do
        for _, Connection in Connections do
            Connection:Disconnect()
        end
    end
    table.clear(RoundManager.PlayerConnections)

    --checking who won and giving the proper amounts to their stats
    if winner == "Killer" then
        for _, Killer in RoundManager.CurrentRound.Killers do
            CommonFunctions.UpdatePlayerStat(Killer.Player, "KillerStats.KillerWins", 1)
            CommonFunctions.GrantRewardToPlayer(Killer.Player, {Money = 120, EXP = 180, Reason = "winning a match as Killer"})
        end
        --survivor losses aren't handled here since when a player dies it directly counts
        Utils.Misc.Print("killer wins")
    elseif winner == "Survivors" then
        for _, Killer in RoundManager.CurrentRound.Killers do
            CommonFunctions.UpdatePlayerStat(Killer.Player, "KillerStats.KillerLosses", 1)
        end
        for _, Player: Player in RoundManager.CurrentRound.PlayersRemaining do
            CommonFunctions.UpdatePlayerStat(Player, "SurvivorStats.SurvivorWins", 1)
            CommonFunctions.GrantRewardToPlayer(Player, {Money = 70, EXP = 110, Reason = "winning a match as Survivor"})
        end
        
        Utils.Misc.Print("survivors win")
    else
        Utils.Misc.Print("NO ONE WON!!1!")
    end

    Utils.Player.Fade(Utils.Player.GetLoadedPlayers(), "In", 0.7, true)
    
    TimeManager:SetTime(TimeManager.Config.LobbyTime)

    --respawning everyone left
    for _, Player: Player in RoundManager.CurrentRound.PlayersAccepted do
        if Player.Character and Player.Character.Role.Value ~= "Spectator" then
            ServerCharacterManager.SetupCharacter(Player)
        end
    end
    
    --restarting variables
    RoundManager.CurrentRound = {
        Killers = {},
        KillerIndex = {},
        PlayersAccepted = {},
        PlayersRemaining = {},
        StartedLMS = false,
    }

    --removing map and resetting lighting
    task.defer(function()
        MapManager.DestroyCurrentMap()
    end)

    --duh
    RoundState.Value = "Lobby"

    Utils.Player.Fade(Utils.Player.GetLoadedPlayers(), "Out", 0.7, true)

    --resetting TimeManager for lobby
    TimeManager.OnTimerEnd = function()
        RoundManager.StartRound()
    end
    TimeManager.CanDecreaseTime = true
end

function RoundManager.Callables._OnPlayerDeath(dead: Player, wasKiller: boolean?)
    wasKiller = wasKiller or false

    --disconnect all connections related to this player
    for _, Player in RoundManager.PlayerConnections[dead.UserId] do
        Player:Disconnect()
    end
    RoundManager.PlayerConnections[dead.UserId] = nil
    --if it was a killer, remove killer from table and resort it
    if wasKiller then
        --updates killer losses
        CommonFunctions.UpdatePlayerStat(dead, "KillerStats.KillerLosses", 1)
        --removes killer from table using table index
        RoundManager.CurrentRound.Killers[RoundManager.CurrentRound.KillerIndex[dead]] = nil
        RoundManager.CurrentRound.KillerIndex[dead] = nil
        --resorts to maintain the minimum indexes possible
        table.clear(RoundManager.CurrentRound.KillerIndex)
        table.sort(RoundManager.CurrentRound.Killers)
        local NewTable = {}
        --resets indexes in order
        for _, killer in ipairs(RoundManager.CurrentRound.Killers) do
            table.insert(NewTable, killer)
        end
        --sets the indexes in KillerIndex for the next killer removal
        for index, killer in ipairs(NewTable) do
            RoundManager.CurrentRound.KillerIndex[killer.Player] = index
        end
        RoundManager.CurrentRound.Killers = NewTable
    else
        RoundManager.CurrentRound.PlayersRemaining[dead.UserId] = nil --removing from remaining list
    end

    --info
    local DeadRemainingValue = PlayersRemaining:FindFirstChild(tostring(dead.UserId))
    if DeadRemainingValue then
        DeadRemainingValue:Destroy()
    end

    RoundManager.Utils.CheckForKillerWin() --also checks for lms
end

--- Checks which role won by seeing how many players are left in each one.
--- Also used to check for LMS.
function RoundManager.Utils.CheckForKillerWin()
    local Count = Utils.Character.GetCharactersWithRoles()

    local Survivors = #Count.Survivor

    if RoundManager.CanSpawnKiller then
        -- if the killer leaves or dies
        if #Count.Killer <= 0 then
            RoundManager.Callables.EndRound("Survivors")
        -- lms
        elseif Survivors == 1 then
            RoundManager.Callables.InitLMS(Players:GetPlayerFromCharacter(Count.Survivor[1]))
        -- if every surv is dead
        elseif #RoundManager.CurrentRound.PlayersAccepted > 1 and Survivors <= 0 then
            RoundManager.Callables.EndRound("Killer")
        end
    -- never check anything killer-related if there's no killer
    elseif Survivors <= 0 then
        RoundManager.Callables.EndRound("Killer")
    end
end

--- Gets a character's module depending on a player's equipped values.
function RoundManager.Utils.GetCharacterModule(player: Player, charType: "Killer" | "Survivor")
    local EquippedCharacter = Utils.PlayerData.GetPlayerEquipped(player, charType)
    local EquippedSkin = Utils.PlayerData.GetPlayerEquipped(player, "Skins."..EquippedCharacter)

    return Utils.Instance.GetCharacterModule(charType, EquippedCharacter, EquippedSkin)
end

--- Sets up a player in the round's player list while also spawning its character.
function RoundManager.Utils.SetupPlayer(Player: Player, KillerIndex: number)
    local Char

    if KillerIndex and RoundManager.CanSpawnKiller then --RoundManager.CanSpawnKiller is for debugging
        Utils.PlayerData.GetPlayerStat(Player, "General.Malice", false).Value = 1 --resets malice

        local EquippedKillerName = Utils.PlayerData.GetPlayerEquipped(Player, "Killer")

        --spawns the character
        Char = ServerCharacterManager.SetupCharacter(Player,
            EquippedKillerName,
            "Killer",
            Utils.PlayerData.GetPlayerEquipped(Player, "Skins."..EquippedKillerName)
        )

        --sets up connections for the round
        RoundManager.PlayerConnections[Player.UserId] = {
            Player.CharacterRemoving:Connect(function()
                RoundManager.Callables._OnPlayerDeath(Player, true)
            end),
        
            --checks for death to count kills n shit
            Char.Humanoid.Died:Connect(function()
                RoundManager.Callables._OnPlayerDeath(Player, true)
            end)
        }

        RoundManager.CurrentRound.Killers[KillerIndex].Character = Char
    else
        CommonFunctions.UpdatePlayerStat(Player, "General.Malice", 1) --adds 1 malice

        local EquippedSurvivorName = Utils.PlayerData.GetPlayerEquipped(Player, "Survivor")

        --spawns the character
        Char = ServerCharacterManager.SetupCharacter(Player,
            EquippedSurvivorName,
            "Survivor",
            Utils.PlayerData.GetPlayerEquipped(Player, "Skins."..EquippedSurvivorName)
        )

        --sets up connections for the round
        RoundManager.PlayerConnections[Player.UserId] = {
            --should count as a death when it gets removed just in case the player leaves
            Player.CharacterRemoving:Connect(function()
                RoundManager.Callables._OnPlayerDeath(Player)
            end),

            --checks for death to count kills n shit
            Char.Humanoid.Died:Connect(function()
                --if the survivor dies they lose duh
                CommonFunctions.UpdatePlayerStat(Player, "SurvivorStats.SurvivorLosses", 1) --increasing loss stat
                RoundManager.Callables._OnPlayerDeath(Player)
            end)
        }
    end

    --anchoring at beginning of round to unanchor later
    task.wait()
    Char.HumanoidRootPart.Anchored = true
end

return RoundManager
