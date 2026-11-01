--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)
local CommonFunctions = require(script.Parent.Parent.System.CommonFunctions)
local TimeManager = require(script.Parent.TimeManager)

local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local BROKEN_COLOR = Color3.fromRGB(200, 40, 30)
local FIXED_COLOR = Color3.fromRGB(70, 230, 110)
local FAIL_NOISE = "rbxasset://sounds/impact_explosion_03.mp3"

local GeneratorManager = {
    Config = {
        Stages = 6,
        TimeReduction = 15,
        MalicePerStage = 0.2,
        MinimumTimeLeft = 15,
        HitLockout = 1.5,
        FailLockout = 2,
        SweepTime = 1.3,
        ZoneWidth = 0.18,
        CoopZoneBonus = 0.08,
        LatencyTolerance = 0.08,
        MaxDistance = 10,
    },
}

type Session = {
    generator: Model,
    panel: BasePart,
    startsAt: number,
    zone: number,
    width: number,
    token: number,
    hitConnection: RBXScriptConnection,
}

local sessions: { [Player]: Session } = {}
local lockedUntil: { [Player]: number } = {}
local random = Random.new()

local function survivorHumanoid(player: Player): Humanoid?
    local character = player.Character
    local role = character and character:FindFirstChild("Role") :: StringValue?
    if not role or role.Value ~= "Survivor" then
        return nil
    end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return if humanoid and humanoid.Health > 0 then humanoid else nil
end

local function isNear(player: Player, session: Session): boolean
    local root = player.Character and player.Character.PrimaryPart
    return root ~= nil and (root.Position - session.panel.Position).Magnitude <= GeneratorManager.Config.MaxDistance
end

local function paintStatus(generator: Model, progress: number)
    local status = generator:FindFirstChild("Status") :: BasePart?
    if not status then
        return
    end
    local color = BROKEN_COLOR:Lerp(FIXED_COLOR, progress / GeneratorManager.Config.Stages)
    status.Color = color
    local light = status:FindFirstChildOfClass("PointLight")
    if light then
        light.Color = color
    end
end

local function endSession(player: Player, lockout: number?)
    local session = sessions[player]
    if not session then
        return
    end
    sessions[player] = nil
    session.hitConnection:Disconnect()
    if lockout then
        lockedUntil[player] = os.clock() + lockout
    end
    Network:FireClientConnection(player, "GeneratorCheckEnded", "REMOTE_EVENT")
end

local function workersOn(generator: Model): number
    local count = 0
    for _, session in sessions do
        if session.generator == generator then
            count += 1
        end
    end
    return count
end

local function killers(): { Player }
    local list = {}
    for _, player in Players:GetPlayers() do
        local role = player.Character and player.Character:FindFirstChild("Role") :: StringValue?
        if role and role.Value == "Killer" then
            table.insert(list, player)
        end
    end
    return list
end

local function fail(player: Player)
    local session = sessions[player]
    if not session then
        return
    end
    local noise = Instance.new("Sound")
    noise.SoundId = FAIL_NOISE
    noise.Volume = 1.5
    noise.RollOffMode = Enum.RollOffMode.Linear
    noise.RollOffMaxDistance = 300
    noise.SoundGroup = SoundService.SoundGroups.Master.SFX
    noise.Parent = session.panel
    noise:Play()
    Debris:AddItem(noise, 4)
    Network:FireClientConnection(killers(), "GeneratorAlert", "REMOTE_EVENT", session.generator)
    endSession(player, GeneratorManager.Config.FailLockout)
end

local function startCheck(player: Player, session: Session)
    local config = GeneratorManager.Config
    if not isNear(player, session) or not survivorHumanoid(player) or RoundState.Value ~= "InRound" then
        endSession(player)
        return
    end
    session.token += 1
    local token = session.token
    local delay = random:NextNumber(0.4, 1)
    session.width = config.ZoneWidth + (if workersOn(session.generator) > 1 then config.CoopZoneBonus else 0)
    session.zone = random:NextNumber(0.4, 0.95 - session.width)
    session.startsAt = os.clock() + delay
    Network:FireClientConnection(player, "GeneratorCheck", "REMOTE_EVENT", delay, config.SweepTime, session.zone, session.width)
    task.delay(delay + config.SweepTime + config.LatencyTolerance + player:GetNetworkPing(), function()
        if sessions[player] ~= session or session.token ~= token then
            return
        end
        if isNear(player, session) then
            fail(player)
        else
            endSession(player)
        end
    end)
end

local function completeStage(player: Player, session: Session)
    local config = GeneratorManager.Config
    local generator = session.generator
    local progress = (generator:GetAttribute("Progress") :: number) + 1
    generator:SetAttribute("Progress", progress)
    if not Utils.PlayerData.GetPlayerSetting(player, "Game.MaliceDisabled") then
        CommonFunctions.UpdatePlayerStat(player, "General.Malice", config.MalicePerStage)
    end
    paintStatus(generator, progress)
    local prompt = session.panel:FindFirstChildOfClass("ProximityPrompt")
    if progress < config.Stages then
        if prompt then
            prompt.ObjectText = `Generator {progress}/{config.Stages}`
        end
        startCheck(player, session)
        return
    end

    if prompt then
        prompt:Destroy()
    end
    for worker, other in sessions do
        if other.generator == generator then
            endSession(worker)
        end
    end
    generator:SetAttribute("Repaired", true)
    workspace:SetAttribute("GeneratorsRepaired", (workspace:GetAttribute("GeneratorsRepaired") or 0) + 1)
    local removed = math.max(math.min(config.TimeReduction, TimeManager.CurrentTime - config.MinimumTimeLeft), 0)
    if removed > 0 then
        TimeManager.SetTime(TimeManager.CurrentTime - removed)
    end
    Network:FireAllClientConnection("GeneratorRepaired", "REMOTE_EVENT", removed)
end

local function onCheckInput(player: Player)
    local config = GeneratorManager.Config
    local session = sessions[player]
    if not session then
        return
    end
    if not isNear(player, session) then
        endSession(player)
        return
    end
    local position = (os.clock() - player:GetNetworkPing() - session.startsAt) / config.SweepTime
    local tolerance = config.LatencyTolerance / config.SweepTime
    if position < session.zone - tolerance or position > session.zone + session.width + tolerance then
        fail(player)
    else
        completeStage(player, session)
    end
end

local function setupGenerator(generator: Model, janitor: any): boolean
    local config = GeneratorManager.Config
    local panel = generator:FindFirstChild("Panel") :: BasePart?
    if not panel then
        warn(`[GeneratorManager] {generator:GetFullName()} has no "Panel" part, skipping it`)
        return false
    end

    generator:SetAttribute("Progress", 0)
    paintStatus(generator, 0)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Repair"
    prompt.ObjectText = `Generator 0/{config.Stages}`
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.C
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt:SetAttribute("SurvivorOnly", true)
    prompt.Parent = panel

    janitor:Add(prompt.Triggered:Connect(function(player: Player)
        local humanoid = survivorHumanoid(player)
        if not humanoid or sessions[player] or os.clock() < (lockedUntil[player] or 0) then
            return
        end
        if RoundState.Value ~= "InRound" or (generator:GetAttribute("Progress") :: number) >= config.Stages then
            return
        end
        local lastHealth = humanoid.Health
        local session: Session = {
            generator = generator,
            panel = panel,
            startsAt = 0,
            zone = 0,
            width = 0,
            token = 0,
            hitConnection = humanoid.HealthChanged:Connect(function(health: number)
                if health < lastHealth then
                    endSession(player, config.HitLockout)
                end
                lastHealth = health
            end),
        }
        sessions[player] = session
        startCheck(player, session)
    end), "Disconnect")
    return true
end

local function onMapAdded(map: Instance)
    if map.Name ~= "Map" then
        return
    end
    workspace:SetAttribute("GeneratorsRepaired", 0)
    local generators = map:FindFirstChild("Generators", true)
    if not generators then
        workspace:SetAttribute("GeneratorsTotal", 0)
        return
    end

    local janitor = Janitor.new()
    janitor:LinkToInstance(map)
    janitor:Add(function()
        for player in sessions do
            endSession(player)
        end
    end, true)
    local total = 0
    for _, generator in generators:GetChildren() do
        if generator:IsA("Model") and setupGenerator(generator, janitor) then
            total += 1
        end
    end
    workspace:SetAttribute("GeneratorsTotal", total)
end

function GeneratorManager:Init()
    for _, name in { "GeneratorCheck", "GeneratorCheckEnded", "GeneratorRepaired", "GeneratorAlert" } do
        Network:SetConnection(name, "REMOTE_EVENT", function() end)
    end
    Network:SetConnection("GeneratorCheckInput", "REMOTE_EVENT", onCheckInput)
    Players.PlayerRemoving:Connect(function(player: Player)
        endSession(player)
        lockedUntil[player] = nil
    end)
    RoundState.Changed:Connect(function(state: string)
        if state ~= "InRound" then
            for player in sessions do
                endSession(player)
            end
        end
    end)
    workspace.ChildAdded:Connect(onMapAdded)
end

return GeneratorManager
