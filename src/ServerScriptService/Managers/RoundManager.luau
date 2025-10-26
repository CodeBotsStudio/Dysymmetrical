--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Rand = Random.new()

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
        StartedLMS = false,
    },
    StopLoop = false,
    CanSpawnKiller = true, --for debugging purposes
}

function RoundManager:Init()
    RoundManager.CurrentRound.Killers = {}
    TimeManager.OnTimerEnd = function()
        RoundManager:StartRound()
    end
end

--- Starts the round right away. There's no more mystery to it.
--- Chooses a killer, resets their malice, increases everyone else's in the round by 1, spawns a map, sets up all characters, sets the round time and plays the killer intro. 
function RoundManager:StartRound()
    local LoadedPlayers = Utils:GetLoadedPlayers(false)
    Utils:Fade(LoadedPlayers, "In", 0.6, true)
    
    --shuffling so that if there's a tie it chooses a truly random one
    RoundManager.CurrentRound.PlayersAccepted = Utils:ShuffleTable(LoadedPlayers)

    local HighestMalice

    local PlayersOrderedByMalice = RoundManager.CurrentRound.PlayersAccepted
    table.sort(PlayersOrderedByMalice, function(a, b)
        return Utils:GetPlayerStat(a, "General.Malice") > Utils:GetPlayerStat(b, "General.Malice")
    end)

    MapManager:GetRandomMap()
    
    for i = 1, workspace:GetAttribute("KillersAllowed") do
        local P = PlayersOrderedByMalice[i]
        if i == 1 then
            HighestMalice = P
        end

        RoundManager.CurrentRound.Killers[i] = {
            Player = P,
            Character = nil
        }
    end

    for i, Player: Player in PlayersOrderedByMalice do
        RoundManager.Utils:SetupPlayer(Player, i <= workspace:GetAttribute("KillersAllowed") and i or nil)
    end

    for i, plr in ipairs(PlayersOrderedByMalice) do
        if RoundManager.CanSpawnKiller and i <= workspace:GetAttribute("KillersAllowed") then
            continue
        end
        RoundManager.CurrentRound.PlayersRemaining[plr.UserId] = plr
    end

    if RoundManager.CanSpawnKiller then --if one is testing survivor then the round'll never end
        for _, i in RoundManager.CurrentRound.Killers do
            table.remove(RoundManager.CurrentRound.PlayersRemaining, table.find(RoundManager.CurrentRound.PlayersRemaining, i.Player))
        end
    end
    Utils:Print(RoundManager.CurrentRound.PlayersRemaining)

    RoundState.Value = "InRound"
    TimeManager:SetTime(TimeManager.Config.RoundTime)
    TimeManager.OnTimerEnd = function()
        RoundManager.Callables:EndRound("Survivors")
    end
    workspace:SetAttribute("LMS", false)
    
    task.spawn(function()
        while task.wait(1) do
            if RoundManager.StopLoop then
                RoundManager.StopLoop = false
                break
            end

            RoundManager.Utils:CheckForKillerWin()
        end
    end)

    RoundManager.Callables:PlayIntro(Utils:GetPlayerEquipped(HighestMalice, "Killer"),
        Utils:GetPlayerEquipped(HighestMalice, "Skins."..Utils:GetPlayerEquipped(HighestMalice, "Killer"))
    )
end

--- Plays the intro to everyone (whose game has loaded).
function RoundManager.Callables:PlayIntro(RootName: string, SkinName: string?)
    local PlayerNames = {}

    for _, i in ipairs(RoundManager.CurrentRound.Killers) do
        table.insert(PlayerNames, i.Player.Name)
    end

    Network:FireClientConnection(Utils:GetLoadedPlayers(), "PlayIntro", "REMOTE_EVENT",
        RootName,
        PlayerNames,
        SkinName
    )

    --whatever happens after since every intro lasts the same
    RoundManager.Threads["IntroEndingThread"] = task.delay(3, function()
        TimeManager.CanDecreaseTime = true
        for _, player: Player in RoundManager.CurrentRound.PlayersAccepted do
            player.Character.HumanoidRootPart.Anchored = false --handled from server
        end
    end)
end

--- Initiates the Last Man Standing sequence (1v1). The Last Man (survivor) must be specified.
function RoundManager.Callables:InitLMS(LastMan: Player)
    local allowed = true
    --failsafe
    if not allowed or RoundManager.CurrentRound.StartedLMS or not RoundManager.CurrentRound.Killers[0] or not RoundManager.CurrentRound.Killers[0].Character then
        return
    end

    RoundManager.CurrentRound.StartedLMS = true
    workspace:SetAttribute("LMS", true)

    --reveals auras
    for _, i in RoundManager.CurrentRound.Killers do
        Utils:RevealPlayerAuraTo(i.Player, LastMan, 10)
        Utils:RevealPlayerAuraTo(LastMan, i.Player, 10)
    end

    Network:FireConnection("LMSVoiceline")

    --plays the music
    --i'm sure that there's a better way to check special LMS's
    local Mod = require(Utils:GetCharacterModule("Killer", RoundManager.CurrentRound.Killers[1].Character:GetAttribute("CharacterName"), RoundManager.CurrentRound.Killers[1].Character:GetAttribute("CharacterSkinName")))
    local SpecialLMS = Mod.Config.SpecialLastManStandings
    local Specials = SpecialLMS[LastMan.Character:GetAttribute("CharacterName")]
    
    local Theme = Specials and (Specials[LastMan.Character:GetAttribute("CharacterSkinName")] or Specials["Default"] or Mod.Config.LastManStandingTheme) or Mod.Config.LastManStandingTheme
    Sounds:PlayTheme(Theme, {Name = "LMS", Priority = 999999, TweenTime = 0, Volume = 1, TimePosition = 0})

    --duh
    TimeManager:SetTime(TimeManager.Config.LastManStandingTime)
end

--- Ends the round. Whoever won is specified by the `winner` parameter.
function RoundManager.Callables:EndRound(winner: "Survivors" | "Killer")
    --cancelling threads and disconnecting connections
    RoundManager.StopLoop = true
    for _, Thread in RoundManager.Threads do
        task.cancel(Thread)
    end
    table.clear(RoundManager.Threads)
    --no more music!!1!
    Sounds:StopTheme("LMS", 0)

    workspace:SetAttribute("LMS", false)

    for _, Connections: {RBXScriptConnection} in RoundManager.PlayerConnections do
        for _, Connection in Connections do
            Connection:Disconnect()
        end
    end
    table.clear(RoundManager.PlayerConnections)

    --checking who won and giving the proper amounts to their stats
    if winner == "Killer" then
        for _, i in RoundManager.CurrentRound.Killers do
            CommonFunctions:UpdatePlayerStat(i.Player, "KillerStats.KillerWins", 1)
            CommonFunctions:GrantRewardToPlayer(i.Player, 120, 180, "winning a match as Killer")
        end
        --survivor losses aren't handled here since when a player dies it directly counts
        Utils:Print("killer wins")
    elseif winner == "Survivors" then
        for _, i in RoundManager.CurrentRound.Killers do
            CommonFunctions:UpdatePlayerStat(i.Player, "KillerStats.KillerLosses", 1)
        end
        for _, Player: Player in RoundManager.CurrentRound.PlayersRemaining do
            CommonFunctions:UpdatePlayerStat(Player, "SurvivorStats.SurvivorWins", 1)
            CommonFunctions:GrantRewardToPlayer(Player, 70, 110, "winning a match as Survivor")
        end
        
        Utils:Print("survivors win")
    else
        Utils:Print("NO ONE WON!!1! https://www.youtube.com/watch?v=L8XbI9aJOXk")
    end

    Utils:Fade(Utils:GetLoadedPlayers(), "In", 0.7, true)
    
    TimeManager:SetTime(TimeManager.Config.LobbyTime)

    --respawning everyone left
    for _, i in RoundManager.CurrentRound.PlayersAccepted do
        if i.Character and i.Character.Role.Value ~= "Spectator" then
            ServerCharacterManager:SetupCharacter(i)
        end
    end
    
    --restarting variables
    RoundManager.CurrentRound = {
        Killers = {},
        PlayersAccepted = {},
        PlayersRemaining = {},
        StartedLMS = false,
    }

    --removing map and resetting lighting
    task.defer(function()
        MapManager:DestroyCurrentMap()
    end)

    --duh
    RoundState.Value = "Lobby"

    Utils:Fade(Utils:GetLoadedPlayers(), "Out", 0.7, true)

    --resetting TimeManager for lobby
    TimeManager.OnTimerEnd = function()
        RoundManager:StartRound()
    end
    TimeManager.CanDecreaseTime = true
end

function RoundManager.Callables:_OnPlayerDeath(dead: Player, wasKiller: boolean?)
    wasKiller = wasKiller or false

    for _, i in RoundManager.PlayerConnections[dead.UserId] do
        i:Disconnect()
    end
    RoundManager.PlayerConnections[dead.UserId] = nil
    if wasKiller then
        for i, v in RoundManager.CurrentRound.Killers do
            if v.Player == dead then
                RoundManager.CurrentRound.Killers[i] = nil
                break
            end
        end
        --resorts to maintain the minimum indexes possible
        table.sort(RoundManager.CurrentRound.Killers)
        local NewTable = {}
        for _, v in ipairs(RoundManager.CurrentRound.Killers) do
            table.insert(NewTable, v)
        end
        RoundManager.CurrentRound.Killers = NewTable
    else
        RoundManager.CurrentRound.PlayersRemaining[dead.UserId] = nil --removing from remaining list
    end

    --info
    if PlayersRemaining:FindFirstChild(dead.UserId) then
        PlayersRemaining:FindFirstChild(dead.UserId):Destroy()
    end

    RoundManager.Utils:CheckForKillerWin() --also checks for lms
end

--- Checks which role won by seeing how many players are left in each one.
--- Also used to check for LMS.
function RoundManager.Utils:CheckForKillerWin()
    local Count = Utils:GetCharactersWithRoles()

    local Killers = Count.Killer and #Count.Killer or 1
    local Survivors = Count.Survivor and #Count.Survivor or 2

    if RoundManager.CanSpawnKiller then
        if Killers <= 0 then
            RoundManager.Callables:EndRound("Survivors")
        elseif Survivors == 1 then
            RoundManager.Callables:InitLMS(Count.Survivor[1])
        elseif #RoundManager.CurrentRound.PlayersAccepted > 1 and Survivors <= 0 then
            RoundManager.Callables:EndRound("Killer")
        end
    elseif Survivors <= 0 then
        RoundManager.Callables:EndRound("Killer")
    end
end

--- Gets a character's module depending on a player's equipped values.
function RoundManager.Utils:GetCharacterModule(player: Player, charType: "Killer" | "Survivor")
    local EquippedCharacter = Utils:GetPlayerEquipped(player, charType)
    local EquippedSkin = Utils:GetPlayerEquipped(player, "Skins."..EquippedCharacter)

    return Utils:GetCharacterModule(charType, EquippedCharacter, EquippedSkin)
end

--- Sets up a player in the round's player list while also spawning its character.
function RoundManager.Utils:SetupPlayer(Player: Player, KillerIndex: number)
    local Spawns = MapManager.CurrentMap.Map.SpawnPoints

    local Char

    if KillerIndex and RoundManager.CanSpawnKiller then --RoundManager.CanSpawnKiller is for debugging
        Utils:GetPlayerStat(Player, "General.Malice", false).Value = 1 --resets malice

        local KillerSpawns = Spawns.Killers:GetChildren()

        local ChosenSpawn = KillerSpawns[Rand:NextInteger(1, #KillerSpawns)].CFrame
        local EquippedKillerName = Utils:GetPlayerEquipped(Player, "Killer")

        --spawns the character
        Char = ServerCharacterManager:SetupCharacter(Player,
            EquippedKillerName,
            "Killer",
            Utils:GetPlayerEquipped(Player, "Skins."..EquippedKillerName),
            ChosenSpawn
        )

        --sets up connections for the round
        RoundManager.PlayerConnections[Player.UserId] = {
            Player.CharacterRemoving:Connect(function()
                RoundManager.Callables:_OnPlayerDeath(Player, true)
            end),
        
            --checks for death to count kills n shit
            Char.Humanoid.Died:Connect(function()
                RoundManager.Callables:_OnPlayerDeath(Player, true)
            end)
        }

        print(KillerIndex)
        RoundManager.CurrentRound.Killers[KillerIndex].Character = Char
    else
        CommonFunctions:UpdatePlayerStat(Player, "General.Malice", 1) --adds 1 malice

        local SurvivorSpawns = Spawns.Survivors:GetChildren()

        local ChosenSpawn = SurvivorSpawns[Rand:NextInteger(1, #SurvivorSpawns)].CFrame
        local EquippedSurvivorName = Utils:GetPlayerEquipped(Player, "Survivor")

        --spawns the character
        Char = ServerCharacterManager:SetupCharacter(Player,
            EquippedSurvivorName,
            "Survivor",
            Utils:GetPlayerEquipped(Player, "Skins."..EquippedSurvivorName),
            ChosenSpawn
        )

        --sets up connections for the round
        RoundManager.PlayerConnections[Player.UserId] = {
            --should count as a death when it gets removed just in case the player leaves
            Player.CharacterRemoving:Connect(function()
                RoundManager.Callables:_OnPlayerDeath(Player)
                -- RoundManager.PlayerConnections[Player.UserId] = nil
            end),

            --checks for death to count kills n shit
            Char.Humanoid.Died:Connect(function()
                --if the survivor dies they lose duh
                CommonFunctions:UpdatePlayerStat(Player, "SurvivorStats.SurvivorLosses", 1) --increasing loss stat
                RoundManager.Callables:_OnPlayerDeath(Player)
                -- RoundManager.PlayerConnections[Player.UserId] = nil
                -- RoundManager.Utils:CheckForKillerWin()
            end)
        }
    end

    task.wait()
    Player.Character.HumanoidRootPart.Anchored = true
end

return RoundManager
