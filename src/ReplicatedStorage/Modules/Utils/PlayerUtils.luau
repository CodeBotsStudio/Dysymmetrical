--!nocheck

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local InstanceUtils = require(script.Parent.InstanceUtils)
local PlayerDataUtils = require(script.Parent.PlayerDataUtils)
local Network = require(ReplicatedStorage.Modules.Network)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local Rand = Random.new()

local PlayerUtils = {
    --- INTERNAL: Used for cloned ragdolling.
    TransparentParts = {},
    AuraColors = {
        Killer = Color3.fromRGB(255, 0, 0),
        Survivor = Color3.fromRGB(255, 191, 0),
        Spectator = Color3.fromRGB(255, 255, 255),
    },
}

--- Equivalent to `Players.PlayerAdded:Connect()` but connections are handled by Janitor.
function PlayerUtils.ObservePlayers(callback: (player: Player, playerJanitor: Janitor.Janitor) -> ()): Janitor.Janitor
	local mainJanitor = Janitor.new()

	local function onNewPlayer(player: Player)
		task.spawn(callback, player, mainJanitor:AddObject(Janitor, nil, player))
	end

	for _, player in Players:GetPlayers() do
		task.spawn(onNewPlayer, player)
	end
    
	mainJanitor:Add(Players.PlayerAdded:Connect(onNewPlayer))
	mainJanitor:Add(Players.PlayerRemoving:Connect(function(player: Player)
		mainJanitor:Remove(player)
	end))

	return mainJanitor
end

--- Gets the mouse position in the screen. Also supports Mobile devices in a different way.
--- Never call this from server as it won't return anything.
--- This isn't supposed to be called at all, use `Utils:GetPlayerMousePosition()` instead
function PlayerUtils._GetMousePosition(LockToClosestPlayer: boolean): Vector3
    --only available in client
    if RunService:IsServer() then
        return
    end

    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()
    local Character = LocalPlayer.Character
    local InputManager = require(LocalPlayer.PlayerScripts.InputManager)
    local SmoothShiftLock = require(LocalPlayer.PlayerScripts.PlayerModule.CameraModule.SmoothShiftLock)
    local FirstPerson = Character and Character:FindFirstChild("Head") and Character.Head.LocalTransparencyModifier >= 0.5

    --If shift lock is enabled it should get the center of the screen.
    if SmoothShiftLock:GetIsMouseLocked() or FirstPerson then
        --Separates default and mobile returns.
        if InputManager.CurrentControlScheme == "Touch" then
            return (Camera.CFrame * CFrame.new(0, 0, -250)).Position
        else
            local Dir = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
            return Dir.Origin + Dir.Direction * 500
        end
    --i honestly have no idea what i did here but it fucking works somehow
    elseif LockToClosestPlayer then
        local ClosestPlayers = PlayerUtils.GetClosestPlayerFromPosition(Character and Character.PrimaryPart and Character.PrimaryPart.Position or Vector3.new(), {
            PlayerSelection = "Survivor",
            ReturnTable = true,
        })

        for _, Player in ClosestPlayers do
            local CPlayer = Player.Player
            local Dis = Player.Distance
            if PlayerUtils.IsOnScreen(CPlayer) and Dis then
                local Pos = CPlayer.PrimaryPart.Position
                local Vel = CPlayer.PrimaryPart.AssemblyLinearVelocity
                if Vel.Magnitude == 0 then
                    return Pos
                else
                    return Pos + Vel * (Dis / 50)
                end
            end
        end
        return (workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -500)).Position
    else
        local Pos = nil
        local LookVector = nil
        if InputManager.CurrentControlScheme == "Touch" then
            Pos = workspace.CurrentCamera.CFrame.Position
            LookVector = workspace.CurrentCamera.CFrame.LookVector * 500
        else
            local Dir = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
            Pos = Dir.Origin
            LookVector = Dir.Direction * 500
        end
        local trans = {}
        for index, _ in PlayerUtils.TransparentParts do
            table.insert(trans, index)
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = trans
        params.IgnoreWater = true

        local cast = workspace:Raycast(Pos, LookVector, params)
        return cast and cast.Position or Pos + LookVector
    end
end

--- Gets a player's mouse position from any side.
function PlayerUtils.GetPlayerMousePosition(Player: Player, LockToClosestPlayer: boolean): Vector3
    if RunService:IsServer() then
        return Network:FireClientConnection(Player, "GetMousePosition", "REMOTE_FUNCTION", LockToClosestPlayer)
    end

    return PlayerUtils._GetMousePosition(LockToClosestPlayer)
end

--- Gets the closest player from a specific group to a position in a radius.
function PlayerUtils.GetClosestPlayerFromPosition(Position: Vector3, Options): (Model, number)
    Options = Options or {}

    Options.MaxDistance = Options.MaxDistance or 999
    Options.PlayerSelection = Options.PlayerSelection or "Survivor"
    local Selection = Options.IncludedSelection or {}
    local Exclude = Options.ExcludedSelection or {}
    for _, PlayerChar in workspace.Players:GetChildren() do
        if (Options.PlayerSelection == "All" or PlayerChar.Role.Value == Options.PlayerSelection) and PlayerChar.Role.Value ~= "Spectator" and not table.find(Exclude, PlayerChar) then
            if not PlayerChar:GetAttribute("Undetectable") or Options.OverrideUndetectable then
                table.insert(Selection, PlayerChar)
            end
        end
    end
    local Close = {}
    for _, PlayerChar in Selection do
        local Distance =PlayerChar.PrimaryPart and (PlayerChar.PrimaryPart.Position - Position).Magnitude

        if Distance and PlayerChar.Humanoid.Health > 0 and (tonumber(Options.MaxDistance) or 999) >= Distance then
            table.insert(Close, {
                Player = PlayerChar,
                Distance = Distance,
            })
        end
    end
    table.sort(Close, function(current, Next)
        return current.Distance < Next.Distance
    end)
    if Options.ReturnTable then
        return Close
    else
        local Closest = Close[1]
        if Closest then
            return Closest.Player, Closest.Distance
        else
            return
        end
    end
end

--- Checks if a certain `Instance` is on screen.
function PlayerUtils.IsOnScreen(Thing: Instance): boolean
    if RunService:IsServer() or not Thing:IsA("Instance") then
        return
    end
    local found = false

    local Char = Players.LocalPlayer.Character
    local visible = false
    --table used to ignore the thing itself, the player's character and the camera itself (??)
    local t = {}
    table.insert(t, Thing)
    table.insert(t, Char)
    table.insert(t, workspace.CurrentCamera)
    for index, _ in PlayerUtils.TransparentParts do
        table.insert(t, index)
    end
    local function checkVisible(Part: BasePart)
        local _, pos = workspace.CurrentCamera:WorldToViewportPoint(Part.Position)
        if pos and #workspace.CurrentCamera:GetPartsObscuringTarget({
            workspace.CurrentCamera.CFrame.Position,
            Part.Position,
        }, t) > 0 then
            return true
        else
            return false
        end
    end

    if Thing:IsA("Model") then
        --if the entire model is invisible part-related then it's invisible duh
        for _, Part in Thing:GetChildren() do
            if Part:IsA("BasePart") and Part.Transparency ~= 1 then
                visible = checkVisible(Part)
                found = visible
            end
            if found then
                break
            end
        end
        if not found then
            return visible
        end
    elseif Thing:IsA("BasePart") and Thing.Transparency ~= 1 then
        visible = checkVisible(Thing)
    end

    return visible
end

--- CLIENT FUNCTION: Reveals a player's aura (highlight) for a specific duration.
--- If a color for the aura isn't specified, it'll be automatically chosen depending on their role.
function PlayerUtils.RevealPlayerAura(RevealedPlayer: Player | Model, Duration: number?, Color: Color3?)
    if RunService:IsServer() then
        return
    end

    local Character = RevealedPlayer and RevealedPlayer:IsA("Player") and RevealedPlayer.Character or RevealedPlayer
    local LocalPlayer = Players.LocalPlayer
    local LocalCharacter = LocalPlayer.Character
    
    if Character and LocalCharacter and (not Character.Effects:FindFirstChild("Undetectable") or Character.Role.Value == LocalCharacter.Role.Value) then
        local ExistingAura = Character:FindFirstChild("PlayerAura")
        if ExistingAura then
            ExistingAura:Destroy()
        end
        
        local UsedColor = Color or PlayerUtils.AuraColors[Character.Role.Value] or PlayerUtils.AuraColors.Spectator

        local Highlight = Instance.new("Highlight")
        Highlight.Name = "PlayerAura"
        Highlight.FillColor = UsedColor
        Highlight.OutlineColor = UsedColor
        Highlight.Parent = Character

        Debris:AddItem(Highlight, (Duration or 10) + 2)

        --if the aura didn't already exist then it starts off completely transparent
        if not ExistingAura then
            Highlight.FillTransparency = 1
            Highlight.OutlineTransparency = 1
            TweenService:Create(Highlight, TweenInfo.new(1), {FillTransparency = 0.5, OutlineTransparency = 0}):Play()
        end

        task.delay((Duration or 10) - 1, function()
            Highlight.Name = "buhbye" --ipad went buhbye -Noli real
            TweenService:Create(Highlight, TweenInfo.new(1), {FillTransparency = 1, OutlineTransparency = 1}):Play()
        end)
    end
end

--- SERVER FUNCTION: Reveals a player's aura (highlight) to a specific player for a speficic duration.
--- If a color for the aura isn't specified, it'll be automatically chosen depending on their role.
function PlayerUtils.RevealPlayerAuraTo(Player: Player | Model, RevealedPlayer: Player | Model, Duration: number?, Color: Color3?)
    if not RunService:IsServer() then
        return
    end
    if Player and Player:IsA("Model") then
        Player = PlayerUtils.GetPlayerFromCharacter(Player)
    end
    Network:FireClientConnection(Player, "RevealPlayerAura", "REMOTE_EVENT", RevealedPlayer, Duration, Color)
end

--- SERVER FUNCTION: Shows a black fade in/out in a player's UI.
--- If it's called from server, the player(s) must be specified.
--- If it's called from client, it can't be sent to other clients.
function PlayerUtils.Fade(Target: Player | {Player}, FadeType: "In" | "Out", Duration: number, Yield: boolean?, StartTransparency: number?, FadeColor: {R: number, G: number, B: number}?)
    if RunService:IsServer() then
        if typeof(Target) == "table" then
            for _, Player in Target do
                Network:FireClientConnection(Player, "Fade", "REMOTE_EVENT", FadeType, Duration, Yield, StartTransparency, FadeColor)
            end
        else
            Network:FireClientConnection(Target, "Fade", "REMOTE_EVENT", FadeType, Duration, Yield, StartTransparency, FadeColor)
        end

        if Yield and Duration > 0 then
            task.wait(Duration)
        end
    else
        PlayerUtils._Fade(FadeType, Duration, Yield, FadeColor)
    end
end

--- INTERNAL: Makes `Utils:Fade()` work. Use that one instead.
function PlayerUtils._Fade(FadeType: "In" | "Out", Duration: number, Yield: boolean?, StartTransparency: number?, FadeColor: {R: number, G: number, B: number}?)
    if RunService:IsServer() then
        warn("[Utils:Fade()] Tried to call internal fade function from server! Preventing fade execution...")
        return
    end

    if workspace:GetAttribute("ClientLoaded") ~= true then
        warn("[Utils:Fade()] Tried to call fade when client hasn't loaded yet! Preventing fade execution...")
        return
    end

    FadeType = FadeType or "In"
    Duration = Duration or 0.4

    if FadeType == "In" then
        if PlayerUtils.FadeFrame and PlayerUtils.FadeFrame.Parent then
            warn("[Utils:Fade()] Fade already exists! Preventing fade execution...")
            return
        end
        
        PlayerUtils.FadeFrame = Instance.new("Frame")
        PlayerUtils.FadeFrame.Name = "Fade"
        PlayerUtils.FadeFrame.BackgroundTransparency = StartTransparency or 1
        PlayerUtils.FadeFrame.BackgroundColor3 = FadeColor and Color3.fromRGB(FadeColor.R, FadeColor.G, FadeColor.B) or Color3.fromRGB(0, 0, 0)
        PlayerUtils.FadeFrame.Size = UDim2.fromScale(1, 1)
        PlayerUtils.FadeFrame.Parent = InstanceUtils.FindFirstChild(Players.LocalPlayer.PlayerGui, "KillerIntros")

        if Duration <= 0 then
            PlayerUtils.FadeFrame.BackgroundTransparency = 0
            return
        end

        local Twn = TweenService:Create(PlayerUtils.FadeFrame, TweenInfo.new(Duration), {BackgroundTransparency = 0})
        Twn:Play()
        if Yield then
            Twn.Completed:Wait()
        end
    elseif FadeType == "Out" then
        if not PlayerUtils.FadeFrame or not PlayerUtils.FadeFrame.Parent then
            warn("[Utils:Fade()] Fade non-existant! Call with `In` type first! Preventing fade execution...")
            return
        end

        if Duration <= 0 then
            PlayerUtils.FadeFrame:Destroy()
            return
        end

        local Twn = TweenService:Create(PlayerUtils.FadeFrame, TweenInfo.new(Duration), {BackgroundTransparency = 1})
        Debris:AddItem(PlayerUtils.FadeFrame, Duration)
        Twn:Play()
        if Yield then
            Twn.Completed:Wait()
        end
    else
        warn("[Utils:Fade()] Fade type not specified! Preventing fade execution...")
    end
end

--- Returns a list of every player whose game has loaded.
function PlayerUtils.GetLoadedPlayers(IncludeAFK: boolean?): {Player}
    if IncludeAFK == nil then
        IncludeAFK = true
    end

    local t: {Player} = {}

    for _, Player: ObjectValue in ReplicatedStorage.LoadedPlayers:GetChildren() do
        if not IncludeAFK and PlayerDataUtils.GetPlayerSetting(Player.Value, "Game.AFK") then
            continue
        end

        table.insert(t, Player.Value)
    end

    return t
end

--- Shakes the local player's camera. Yeah, pretty intuitive, isn't it?
function PlayerUtils.ShakeCamera(Magnitude: number, Duration: number)
    if RunService:IsServer() or not PlayerDataUtils.GetPlayerSetting(Players.LocalPlayer, "Customization.ScreenShakeEnabled") then
        return
    end

    local Start = time()
    local Conn
    Conn = RunService.PreRender:Connect(function(_delta: number)
        local Left = math.clamp((time() - Start) / Duration, 0, 1)
        local mult = Magnitude * (1 - Left)
        local AxisTable = {}
        for _, Axis: string in {"X", "Y", "Z"} do
            AxisTable[Axis] = (Rand:NextInteger(0, 1) - 0.5) * 2 * mult
        end
        local TargetPos = Vector3.new(AxisTable.X, AxisTable.Y, AxisTable.Z)
        local Cam = workspace.CurrentCamera
        Cam.CFrame *= CFrame.new(TargetPos)
        if Left >= 1 then
            Conn:Disconnect()
        end
    end)
end

--- SERVER FUNCTION: Shakes the camera of one or more players.
function PlayerUtils.ShakeCameraOf(Target: Player | {Player}, Magnitude: number, Duration: number)
    if not RunService:IsServer() then
        return
    end

    if typeof(Target) == "table" then
        for _, Player in Target do
            Network:FireClientConnection(Player, "ShakeCamera", "REMOTE_EVENT", Magnitude, Duration)
        end
        return
    end
    Network:FireClientConnection(Target, "ShakeCamera", "REMOTE_EVENT", Magnitude, Duration)
end

--- Attempts to get a `Player` instance from a character `Model`.
--- Usually runs better than `Players:GetPlayerFromCharacter()` as this one just looks for a player with the same name as the character in `Players`.
--- This is assured to return a player if the character is tied to one as they're both named the same.
--- When using this, pass a character from `workspace.Players` as the `Character` param to make sure this works.
--- Take into account that if the player isn't found, `Players:GetPlayerFromCharacter()` WILL be used as a fallback.
function PlayerUtils.GetPlayerFromCharacter(Character: Model): Player
    local Player = InstanceUtils.FindFirstChild(Players, Character.Name, 0)
    if not Player then
        Player = Players:GetPlayerFromCharacter(Character)
    end
    return Player
end

return PlayerUtils
