--!nocheck

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Rand = Random.new()

local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Effect = require(ReplicatedStorage.Classes.Effect)
local Network = require(ReplicatedStorage.Modules.Network)

local Utils = {
    --- INTERNAL: Used for cloned ragdolling.
    TransparentParts = {},
    AuraColors = {
        Killer = Color3.fromRGB(255, 0, 0),
        Survivor = Color3.fromRGB(255, 191, 0),
        Spectator = Color3.fromRGB(255, 255, 255),
    },
    --- UDim utils to not have to repeat creations.
    UDim = {
        Zero = UDim2.new(0, 0, 0, 0),
        FullY = UDim2.fromScale(0, 1),
        Full20Offset = UDim2.new(1, -20, 1, -20),
        Full = UDim2.fromScale(1, 1),
    },
    --- INTERNAL: Used for fading in/out.
    Fade = nil,
}

--- If you change this, you're a bum.
Utils.Credits = [[

######  #     #  #####  #     # #     # #     # ####### ####### ######   ###   #####     #    #       
#     #  #   #  #     #  #   #  ##   ## ##   ## #          #    #     #   #   #     #   # #   #       
#     #   # #   #         # #   # # # # # # # # #          #    #     #   #   #        #   #  #       
#     #    #     #####     #    #  #  # #  #  # #####      #    ######    #   #       #     # #       
#     #    #          #    #    #     # #     # #          #    #   #     #   #       ####### #       
#     #    #    #     #    #    #     # #     # #          #    #    #    #   #     # #     # #       
######     #     #####     #    #     # #     # #######    #    #     #  ###   #####  #     # ####### 


This game is using Dysymmetrical, an open-source asymmetrical game engine available on GitHub.
Credits to Dyscarn for making it! (hello!)
]]

function Utils:Init()
    if not RunService:IsServer() then
        local function AddToR(i)
            if i:IsA("BasePart") and i.Transparency >= 0.75 then
                self.TransparentParts[i] = true
            end
        end
        task.spawn(function()
            for _, i in workspace:GetDescendants() do
                AddToR(i)
            end
            workspace.DescendantAdded:Connect(AddToR)
            workspace.DescendantRemoving:Connect(function(i)
                if self.TransparentParts[i] then
                    self.TransparentParts[i] = nil
                end
            end)
        end)

        Network:SetConnection("RevealPlayerAura", "REMOTE_EVENT", function(RevealedPlayer: Player | Model, Duration: number?, Color: Color3?)
            self:RevealPlayerAura(RevealedPlayer, Duration, Color)
        end)

        Network:SetConnection("Fade", "REMOTE_EVENT", function(FadeType: "In" | "Out", Duration: number, Yield: boolean?, StartTransparency: number?, FadeColor: {R: number, G: number, B: number}?)
            self:_Fade(FadeType, Duration, Yield, StartTransparency, FadeColor)
        end)

        Network:SetConnection("GetMousePosition", "REMOTE_FUNCTION", function(v)
            return self:_GetMousePosition(v)
        end)
        Network:SetConnection("ShakeCamera", "REMOTE_EVENT", function(Magnitude: number, Duration: number)
            return self:ShakeCamera(Magnitude, Duration)
        end)
    end
end

--- Splits a path into multiple strings.
function Utils:SplitStringPath(path: string): {string}
    return path:split(".")
end

--- Returns a completely invisible, uncollidable, undetectable, 1 cubic stud sized part in CFrame `cf` and parented to `parent`.
function Utils:GetInvisPart(cf: CFrame?, parent: Instance?): Part
    local Part = Instance.new("Part")
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.Transparency = 1
    Part.CastShadow = false
    Part.Anchored = true
    Part.Size = Vector3.one

    if cf then
        Part.CFrame = cf
    end
    if parent then
        Part.Parent = parent
    end

    return Part
end

--- Makes a copy of an entire table.
function Utils:CopyTable<T>(CloneThis: T & {}) : T
	local MetaTable = getmetatable(CloneThis)
	local NewTable = (MetaTable and setmetatable({}, MetaTable :: {}?) or {}) :: typeof(CloneThis)

	for i, v in CloneThis do
		if type(v) == `table` then
			NewTable[i] = self:CopyTable(v)
		else
			NewTable[i] = v
		end
	end

	return NewTable
end

--- Shuffles a table to make it have a random order.
function Utils:ShuffleTable<T>(t: T & {}): T & {}
    local j, temp

	for i = #t, 1, -1 do
		j = Rand:NextInteger(1, i)
		temp = t[i]
		t[i] = t[j]
		t[j] = temp
	end
	
	return t
end

--- Loads any assets in the function's parameter for proper use without loading them right when used.
function Utils:PreloadAssets(assets: string | {string})
    task.defer(function()
        local loadedAssets = {}
        local checkedAssets = {}

        local function Fetch(assetsToFetch: string | {string})
            if typeof(assetsToFetch) == "string" then
                table.insert(loadedAssets, assetsToFetch)
                table.insert(checkedAssets, assetsToFetch)
                return
            end
            
            for t, asset in assetsToFetch do
                if table.find(checkedAssets, asset) then
                    continue
                end
                
                if typeof(asset) == "table" then
                    pcall(Fetch, asset)

                elseif typeof(asset) == "string" and asset:find("rbxassetid://") then
                    if t == "SoundIDs" and RunService:IsClient() then
                        local Sound = Instance.new("Sound")
                        Sound.Name = asset
                        Sound.SoundId = asset
                        Sound.Volume = 0
                        Sound.Parent = workspace.Sounds
                        Sound:Play()

                        Debris:AddItem(Sound, 1)
                    end

                    table.insert(loadedAssets, asset)
                end
                table.insert(checkedAssets, asset)
            end
        end

        pcall(Fetch, assets)
        ContentProvider:PreloadAsync(loadedAssets)
    end)
end

--- Gets the mouse position in the screen. Also supports Mobile devices in a different way.
--- Never call this from server as it won't return anything.
--- This isn't supposed to be called at all, use `Utils:GetPlayerMousePosition()` instead
function Utils:_GetMousePosition(LockToClosestPlayer: boolean): Vector3
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
        local ClosestPlayer = self:GetClosestPlayerFromPosition(Character and Character.PrimaryPart and Character.PrimaryPart.Position or Vector3.new(), {
            PlayerSelection = "Survivor",
            ReturnTable = true,
        })

        for _, i in ClosestPlayer do
            local CPlayer = i.Player
            local Dis = i.Distance
            if self:IsOnScreen(i.Player) and Dis then
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
        for i, _ in self.TransparentParts do
            table.insert(trans, i)
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
function Utils:GetPlayerMousePosition(Player: Player, LockToClosestPlayer: boolean): Vector3
    if RunService:IsServer() then
        return Network:FireClientConnection(Player, "GetMousePosition", "REMOTE_FUNCTION", LockToClosestPlayer)
    end

    return self:_GetMousePosition(LockToClosestPlayer)
end

--- Gets the closest player from a specific group to a position in a radius.
function Utils:GetClosestPlayerFromPosition(Position: Vector3, Options): (Model, number)
    Options = Options or {}

    Options.MaxDistance = Options.MaxDistance or 999
    Options.PlayerSelection = Options.PlayerSelection or "Survivor"
    local Selection = Options.IncludedSelection or {}
    local Exclude = Options.ExcludedSelection or {}
    for _, i in workspace.Players:GetChildren() do
        if (Options.PlayerSelection == "All" or i.Role.Value == Options.PlayerSelection) and i.Role.Value ~= "Spectator" and not table.find(Exclude, i) then
            if not i:GetAttribute("Undetectable") or Options.OverrideUndetectable then
                table.insert(Selection, i)
            end
        end
    end
    local Close = {}
    for _, i in Selection do
        local Distance = i.PrimaryPart and (i.PrimaryPart.Position - Position).Magnitude

        if Distance and i.Humanoid.Health > 0 and (tonumber(Options.MaxDistance) or 999) >= Distance then

            table.insert(Close, {
                Player = i,
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
function Utils:IsOnScreen(Thing: Instance): boolean
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
    for i, _ in self.TransparentParts do
        table.insert(t, i)
    end
    local function checkVisible(i)
        local _, pos = workspace.CurrentCamera:WorldToViewportPoint(i.Position)
        if pos and #workspace.CurrentCamera:GetPartsObscuringTarget({
            workspace.CurrentCamera.CFrame.Position,
            i.Position,
        }, t) > 0 then
            return true
        else
            return false
        end
    end

    if Thing:IsA("Model") then
        --if the entire model is invisible part-related then it's invisible duh
        for _, i in Thing:GetChildren() do
            if i:IsA("BasePart") and i.Transparency ~= 1 then
                visible = checkVisible(i)
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
function Utils:RevealPlayerAura(RevealedPlayer: Player | Model, Duration: number?, Color: Color3?)
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
        
        local UsedColor = Color or self.AuraColors[Character.Role.Value] or self.AuraColors.Spectator

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
function Utils:RevealPlayerAuraTo(Player: Player | Model, RevealedPlayer: Player | Model, Duration: number?, Color: Color3?)
    if not RunService:IsServer() then
        return
    end
    if Player and Player:IsA("Model") then
        Player = Players:GetPlayerFromCharacter(Player)
    end
    Network:FireClientConnection(Player, "RevealPlayerAura", "REMOTE_EVENT", RevealedPlayer, Duration, Color)
end

--- Tries to get an instance from a set path with a string.
--- The syntax is exactly the same as in another language when looking for a variable (e. g. "ReplicatedStorage.Modules.Utils").
--- It's useful when sending an object's path between peers (S2C / C2S) to save bandwidth by using a string instead of an Instance reference.
function Utils:GetInstanceFromPath(path: string): Instance
    local Names = self:SplitStringPath(path)
    
    local Inst
	for index, step in Names do
		if index == 1 then
			Inst = game:GetService(step)
		elseif Inst then
			Inst = Inst:FindFirstChild(step)
		end
	end

    if Inst then
        return Inst
    elseif workspace:GetAttribute("DebugAllowed") then
        warn("[Utils:GetInstanceFromPath()] Instance not found for path: " .. path)
    end

    return
end

--- Retrieves a player's stat through a string path.
--- If `value` is false, it'll return the `ValueBase` object instead of the value itself to modify it or to get a property from it (e.g. attributes).
function Utils:GetPlayerStat(Player: Player, path: string, value: boolean?): ValueBase | any
    if value == nil then
        value = true
    end

    local Stat = Utils:FindFirstChild(Player, "PlayerData.Stats."..path)
    return value and Stat.Value or Stat
end

--- Retrieves a player's setting value through a string path.
function Utils:GetPlayerSetting(Player: Player, path: string): any
    local splitPath = self:SplitStringPath(path)
    local PlayerSettings = self:FindFirstChild(Player, "PlayerData.Settings", false)
    if #splitPath == 1 then
        return PlayerSettings:FindFirstChild(splitPath[1]).Value
    else
        local Setting = PlayerSettings
        for _, step in splitPath do
            if not Setting then
                warn("[Utils:GetPlayerSetting()] Child \""..step.."\" not found! Returning nil!")
                return
            end
            Setting = Setting:FindFirstChild(step)
        end
        return Setting.Value
    end
end

--- Retrieves a player's equipped item of a type through a string path.
--- Also works for emotes.
--- If `value` is false, it'll return the `StringValue` object instead of the value itself.
function Utils:GetPlayerEquipped(Player: Player, path: string, value: boolean?): StringValue | string
    if value == nil then
        value = true
    end

    local splitPath = self:SplitStringPath(path)
    local Equipped = Utils:FindFirstChild(Player, "PlayerData.Equipped", false)
    if #splitPath == 1 then
        local Child = Equipped:FindFirstChild(splitPath[1])
        return value and Child.Value or Child
    else
        local Child = Equipped
        for _, step in splitPath do
            if not Child then
                warn("[Utils:GetPlayerEquipped()] Child \""..step.."\" not found! Returning nil!")
                return
            end

            if Child.Name == "Skins" then
                Child = Child:FindFirstChild(step)

                if not Child then
                    if RunService:IsServer() then
                        Child = Utils:CreateMissingSkinValue(Player, step)
                    else
                        Child = Network:FireServerConnection("CreateMissingSkinValue", "REMOTE_FUNCTION", step)
                    end
                end

                continue
            end
            
            Child = Child:FindFirstChild(step)
        end
        return value and Child.Value or Child
    end
end

--- Retrieves a player's purchased item of a type through a string path.
--- Also works for emotes.
--- If `value` is false, it'll return the `StringValue` object instead of the value itself.
function Utils:GetPlayerOwned(Player: Player, path: string, value: boolean?): StringValue | string
    if value == nil then
        value = true
    end

    local Child = Utils:FindFirstChild(Player, "PlayerData.Purchased."..path, false)
    if not Child then
        return
    end
    return value and (Child and Child.Value or false) or Child
end

--- Checks if a player has an effect.
--- @return Returns a `boolean` indicating if the specified player has the effect and the level if it's true.
function Utils:CheckPlayerEffect(Player: Player, effectName: string): (boolean & number)?
    if Player.Character and Utils:FindFirstChild(Player.Character, "Effects."..effectName) then
        return true, Player.Character.Effects[effectName].Value
    end

    return false
end

--- Linear interpolation: formula used to get a certain value between two specified values by using a magnitude from 0 to 1.
--- See [Lerping](https://rfcs.luau.org/function-math-lerp.html).
function Utils:Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

--- Function used instead of the built-in print to trace for bugs in public playtesting.
--- If called from Server, it'll also print to all clients to trace server values.
function Utils:Print(...)
    if RunService:IsServer() then
        print(...)
        if workspace:GetAttribute("DebugAllowed") == true and not RunService:IsStudio() then
            Network:FireAllClientConnection("Print", "UREMOTE_EVENT", Enum.MessageType.MessageInfo, ...)
        end
    elseif workspace:GetAttribute("DebugAllowed") == true then
        print(...)
    end
end

--- @return Returns a string containing the passed number to be 2 digits or more, filling the blank spaces with zeros.
function Utils:FormatInt(Int: number): string
	return string.format("%02i", Int)
end

--- Function that'll turn a seconds value to Days:Hours:Minutes:Seconds format in a string.
function Utils:ConvertToDHMS(Seconds: number): string
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds -= Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes -= Hours * 60

    local Days = 0
    if Hours > 23 then
        Days = (Hours - Hours % 24) / 24
        Hours -= Days * 24
    end

    local FinalText = self:FormatInt(Hours)..":"..self:FormatInt(Minutes)..":"..self:FormatInt(Seconds)

    if Days > 0 then
        FinalText = self:FormatInt(Days)..":"..FinalText
    end

	return FinalText
end

--- Function that works like `FormatInt` but is used to return seconds in Minutes:Seconds format.
function Utils:ConvertToMinSec(Seconds: number): string
	return string.format("%02i:%02i", Seconds / 60, Seconds % 60)
end

--- Gets a character's module from a specific type.
--- It also supports skins using `skinName` as an optional last parameter.
function Utils:GetCharacterModule(charType: "Survivor" | "Killer", charName: string, skinName: string?): ModuleScript
    local CharFolder = ReplicatedStorage.Characters

    local Module

    --checks if a skin exists and assigns it
    if skinName ~= nil and #skinName > 0 then
        Module = CharFolder["Skins"][charType.."s"]:FindFirstChild(charName)
        if Module then
            Module = Module:FindFirstChild(skinName)
        end
    end

    --replaces with the default character if it hasn't found the skin or if there wasn't one from the start
    if not Module then
        Module = CharFolder[charType.."s"]:FindFirstChild(charName)
    end

    --obv errors if there's none
    if not Module then
        warn("Can't find character module! ("..charType..", "..charName..", "..skinName..")")
        return
    end

    return Module
end

--- Gets an emote's module. Just used as a shortcut, and also serves use for tracing errors (it has a custom error message).
function Utils:GetEmoteModule(EmoteName: string): ModuleScript
    local EmoteFolder = ReplicatedStorage.Assets.Emotes

    local Module = EmoteFolder:FindFirstChild(EmoteName)

    --obv errors if there's none
    if not Module then
        -- error("Can't find emote module! ("..EmoteName..")")
        return
    end

    return Module
end

local RomanNumeralMap = {
    [1000] = 'M',
    [900] = 'CM',
    [500] = 'D',
    [400] = 'CD',
    [100] = 'C',
    [50] = 'L',
    [40] = 'XL',
    [10] = 'X',
    [9] = 'IX',
    [5] = 'V',
    [4] = 'IV',
    [1] = 'I',
}

--- Converts an `int` to roman numerals in a `string`. 
function Utils:IntToRoman(num: number): string
    local roman = ""

    while num > 0 do
        for int, romanChar in RomanNumeralMap do 
            while num >= int do
                roman = roman..romanChar
                num -= int
            end
        end
    end
    
    return roman
end

--- Gets an effect's module.
--- Also supports subfolders in `ReplicatedStorage.Effects`.
function Utils:GetEffectModule(name: string, subfolder: string?, module: boolean?): Effect.Effect
    if module == nil then
        module = false
    end
    
	local Effect: ModuleScript

	if subfolder and #subfolder > 0 then
        Effect = Utils:FindFirstChild(ReplicatedStorage.Effects, subfolder.."."..name, false)
	else
        Effect = Utils:FindFirstChild(ReplicatedStorage.Effects, name, false)
	end

    if not Effect:IsA("ModuleScript") then
        return
    end

    return module and Effect or self:CopyTable(require(Effect))
end

--- Calculates a character's level from an EXP value.
--- Will increase the requirement for the next level until level 100 and begins at 1.
function Utils:CalculateLevelFromEXP(EXP: number): (number, number, number)
	local Levels = 1
	local EXPForNextLevel = 100
	local EXPRemaining = EXP

	while EXPForNextLevel <= EXPRemaining do
		EXPRemaining -= EXPForNextLevel

		Levels += 1

		EXPForNextLevel = math.round(math.clamp(Levels, 1, 100) * 12 + 80)
	end

	return Levels, EXPRemaining, EXPForNextLevel
end

--- Loads an animation into a rig, returning the corresponding `AnimationTrack` for usage.
--- If `YieldUntilLoad` is true, the code executing this function will yield until the `AnimationTrack` is fully loaded. Defaults to `false`.
function Utils:LoadAnimationFromID(Rig: Model, ID: string | {string} | {[string]: string}, YieldUntilLoad: boolean?): AnimationTrack
    if not Rig then
        error("[Utils:LoadAnimationFromID()]: Rig not provided or nil.")
        return
    end

    if not ID or #ID < 0 then
        error("[Utils:LoadAnimationFromID()]: Animation ID invalid or nil.")
        return
    end

    if typeof(ID) == "table" then
        ID = Utils:DictToTable(ID)
        ID = ID[Rand:NextInteger(1, #ID)]
    end

    if YieldUntilLoad == nil then
        YieldUntilLoad = false
    end

    local Animator = Rig:FindFirstChild("Animator", true)
    if not Animator then
        local timeout = 0
        repeat
            timeout += task.wait(0.1)
            Animator = Rig:FindFirstChild("Animator", true)
        until Animator or timeout > 30
    end

    local AnimInstances = Rig:FindFirstChild("AnimationInstances")
    if not AnimInstances then
        AnimInstances = Instance.new("Folder")
        AnimInstances.Name = "AnimationInstances"
        AnimInstances.Parent = Rig
    end

    local Animation: Animation = Rig.AnimationInstances:FindFirstChild(ID)
    if Animation then
        return Animator:LoadAnimation(Animation)
    else
        Animation = Instance.new("Animation")
        Animation.Name = ID
        Animation.AnimationId = ID
        Animation.Parent = Rig.AnimationInstances
        
        local Track = Animator:LoadAnimation(Animation)

        local Timeout = 0
        if YieldUntilLoad and Track.Length <= 0 then
            repeat Timeout += task.wait()
            until Track.Length > 0 or Timeout >= 25
        end

        return Track
    end
end

--- Turns a dictionary into a table, removing the keys and making them numbers.
--- Primarily used for randomness as it isn't ordered in any way.
function Utils:DictToTable<T>(Dictionary: {[any]: T}): {T}
    local NewTable = {}

    for _, item in Dictionary do
        table.insert(NewTable, item)
    end

    return NewTable
end

--- SERVER FUNCTION: Shows a black fade in/out in a player's UI.
--- If it's called from server, the player(s) must be specified.
--- If it's called from client, it can't be sent to other clients.
function Utils:Fade(Target: Player | {Player}, FadeType: "In" | "Out", Duration: number, Yield: boolean?, StartTransparency: number?, FadeColor: {R: number, G: number, B: number}?)
    if RunService:IsServer() then
        if typeof(Target) == "table" then
            for _, i in Target do
                Network:FireClientConnection(i, "Fade", "REMOTE_EVENT", FadeType, Duration, Yield, StartTransparency, FadeColor)
            end
        else
            Network:FireClientConnection(Target, "Fade", "REMOTE_EVENT", FadeType, Duration, Yield, StartTransparency, FadeColor)
        end

        if Yield and Duration > 0 then
            task.wait(Duration)
        end
    else
        self:_Fade(FadeType, Duration, Yield, FadeColor)
    end
end

--- INTERNAL: Makes `Utils:Fade()` work. Use that one instead.
function Utils:_Fade(FadeType: "In" | "Out", Duration: number, Yield: boolean?, StartTransparency: number?, FadeColor: {R: number, G: number, B: number}?)
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
        if self.FadeFrame and self.FadeFrame.Parent then
            warn("[Utils:Fade()] Fade already exists! Preventing fade execution...")
            return
        end
        
        self.FadeFrame = Instance.new("Frame")
        self.FadeFrame.Name = "Fade"
        self.FadeFrame.BackgroundTransparency = StartTransparency or 1
        self.FadeFrame.BackgroundColor3 = FadeColor and Color3.fromRGB(FadeColor.R, FadeColor.G, FadeColor.B) or Color3.fromRGB(0, 0, 0)
        self.FadeFrame.Size = self.UDim.Full
        self.FadeFrame.Parent = Utils:FindFirstChild(Players.LocalPlayer.PlayerGui, "KillerIntros")

        if Duration <= 0 then
            self.FadeFrame.BackgroundTransparency = 0
            return
        end

        local Twn = TweenService:Create(self.FadeFrame, TweenInfo.new(Duration), {BackgroundTransparency = 0})
        Twn:Play()
        if Yield then
            Twn.Completed:Wait()
        end
    elseif FadeType == "Out" then
        if not self.FadeFrame or not self.FadeFrame.Parent then
            warn("[Utils:Fade()] Fade non-existant! Call with `In` type first! Preventing fade execution...")
            return
        end

        if Duration <= 0 then
            self.FadeFrame:Destroy()
            return
        end

        local Twn = TweenService:Create(self.FadeFrame, TweenInfo.new(Duration), {BackgroundTransparency = 1})
        Debris:AddItem(self.FadeFrame, Duration)
        Twn:Play()
        if Yield then
            Twn.Completed:Wait()
        end
    else
        warn("[Utils:Fade()] Fade type not specified! Preventing fade execution...")
    end
end

--- Returns a list of every player whose game has loaded.
function Utils:GetLoadedPlayers(IncludeAFK: boolean?): {Player}
    if IncludeAFK == nil then
        IncludeAFK = true
    end

    local t: {Player} = {}

    for _, i: ObjectValue in ReplicatedStorage.LoadedPlayers:GetChildren() do
        if not IncludeAFK and self:GetPlayerSetting(i.Value, "Game.AFK") then
            continue
        end

        table.insert(t, i.Value)
    end

    return t
end

--- Returns a list of every loaded player's character.
--- Also read `Utils:GetLoadedPlayers()`.
function Utils:GetLoadedCharacters(IncludeAFK: boolean?): {Model}
    local t: {Model} = {}

    for _, i in self:GetLoadedPlayers(IncludeAFK) do
        if i.Character then
            table.insert(t, i.Character)
        end
    end

    return t
end

--- Returns a list of all characters from every role instantiated.
function Utils:GetCharactersWithRoles(IncludeAFK: boolean?): {[string]: {Model}}
    local Characters = {}

    for _, Character in self:GetLoadedCharacters(IncludeAFK) do
        if Character:FindFirstChild("Role") then
            --dead ones EZ!!!!
            if Character:FindFirstChildOfClass("Humanoid").Health <= 0 or Character:GetAttribute("Dead") == true then
                continue
            end

            --creates the table if it's not created with the character inside
            if not Characters[Character.Role.Value] then
                Characters[Character.Role.Value] = {Character}
                continue
            end

            --adds a new character to the list
            table.insert(Characters[Character.Role.Value], Character)
        end
    end

    Characters.Killer = Characters.Killer or {}
    Characters.Survivor = Characters.Survivor or {}

    return Characters
end

--- INTERNAL | SERVER FUNCTION: Used to create a character's equipped skin value for a player if it's missing.
function Utils:CreateMissingSkinValue(SourcePlayer: Player, name: string)
    if not RunService:IsServer() then
        return
    end

    local SkinValue = Utils:FindFirstChild(SourcePlayer, "PlayerData.Equipped.Skins."..name, false)
    if SkinValue then
        return SkinValue
    end

    SkinValue = Instance.new("StringValue")
    SkinValue.Name = name
    SkinValue.Value = ""
    SkinValue.Parent = SourcePlayer.PlayerData.Equipped.Skins

    return SkinValue
end

--- INTERNAL | SERVER FUNCTION: Used to create a character's purchased skin value for a player if it's missing.
function Utils:CreateMissingPurchasedSkinValue(SourcePlayer: Player, name: string)
    if not RunService:IsServer() then
        return
    end

    local SkinFolder = Utils:FindFirstChild(SourcePlayer, "PlayerData.Purchased.Skins."..name, false)
    if SkinFolder then
        return SkinFolder
    end

    SkinFolder = Instance.new("Folder")
    SkinFolder.Name = name
    SkinFolder.Parent = SourcePlayer.PlayerData.Purchased.Skins

    return SkinFolder
end

--- Util to replace `Instance:FindFirstChild()` if you know that a certain instance IS going to be there soon if it isn't already there (e.g. Role value in the character).
--- An example of a replaceable chunk of code is `local Role = Char:FindFirstChild("Role") or Char:WaitForChild("Role", 30)`.
function Utils:FindFirstChild(Parent: Instance, ChildPath: string, YieldPerStep: boolean?, Timeout: number?): Instance
    if not Parent then
        warn("[Utils:FindFirstChild()] `Parent` is nil!")
        return
    end

    if YieldPerStep == nil then
        YieldPerStep = true
    end

    local SplitPath = self:SplitStringPath(ChildPath)

    local Result = Parent

    for _, step in SplitPath do
        local P = Result

        Result = P:FindFirstChild(step) or (YieldPerStep and P:WaitForChild(step, Timeout or 3) or nil)

        if not Result then
            break
        end
    end

    if not Result or Result == Parent then
        -- warn("[Utils:FindFirstChild()] Couldn't find \""..Parent.Name.."."..ChildPath.."\"!", debug.traceback())
        return
    end

    return Result
end

--- Maps a numeric range onto another and returns position `t`.
function Utils:MapToRange(t: number, a: number, b: number, c: number, d: number): number
	return c + ((d - c) / (b - a)) * (t - a)
end

--- Returns an achievement's data table through an `AchievementGroup.AchievementName` path.
function Utils:GetAchievementData(path: string): Achievements.Achievement
    local steps = self:SplitStringPath(path)
    
    local Achievement = Achievements
    for _, step in steps do
        Achievement = Achievement[step]
    end

    return Achievement
end

--- Shakes the local player's camera. Yeah, pretty intuitive, isn't it?
function Utils:ShakeCamera(Magnitude: number, Duration: number)
    if RunService:IsServer() or not self:GetPlayerSetting(Players.LocalPlayer, "Customization.ScreenShakeEnabled") then
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
function Utils:ShakeCameraOf(Player: Player | {Player}, Magnitude: number, Duration: number)
    if not RunService:IsServer() then
        return
    end

    if typeof(Player) == "table" then
        for _, i in Player do
            Network:FireClientConnection(i, "ShakeCamera", "REMOTE_EVENT", Magnitude, Duration)
        end
        return
    end
    Network:FireClientConnection(Player, "ShakeCamera", "REMOTE_EVENT", Magnitude, Duration)
end

--- Wraps a number between two values, meaning that if it's out of bounds, it turns to the contrary bound.
--- For example, if the value is less than the minimum, it'll turn into the maximum and viceversa.
function Utils:WrapNum(Value: number, Minimum: number, Maximum: number): number
    if Value < Minimum then
        Value = Maximum
    elseif Value > Maximum then
        Value = Minimum
    end

    return Value
end

--- Returns the amount of items there are in a dictionary.
function Utils:GetCountOfDict(dictionary: {[any]: any}): number
    local Count = 0

    if dictionary then
        for _, _ in dictionary do
            Count += 1
        end
    end
    
    return Count
end

function Utils:FindInDictionary<T>(Dictionary: T & {}, Item: T, Type: "Key" | "Value"): (T, T)
    if Type == "Key" then
        for v, i in Dictionary do
            if v == Item then
                return v, i
            end
        end
    elseif Type == "Value" then
        for v, i in Dictionary do
            if i == Item then
                return v, i
            end
        end
    end

    return
end

return Utils
