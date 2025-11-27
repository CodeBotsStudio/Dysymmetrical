--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InstanceUtils = require(script.Parent.InstanceUtils)
local PlayerUtils = require(script.Parent.PlayerUtils)
local TypeUtils = require(script.Parent.TypeUtils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages._Index["howmanysmall_janitor@1.18.3"].Promise)

local Rand = Random.new()

local CharacterUtils = {}

--- Waits for a character to properly load.
function CharacterUtils.WaitForCharacterLoaded(character: Model)
	if not character.PrimaryPart then
		character:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end

	if not character:IsDescendantOf(workspace) then
		character.AncestryChanged:Wait()
	end
end

--- Gets a player's character's humanoid.
function CharacterUtils.GetPlayerHumanoid(player: Player) : Humanoid
	local character = player.Character
	if not character then
		return
	end

	return character:FindFirstChildWhichIsA("Humanoid")
end

--- Equal to `Humanoid.Died:Connect()` but managed by Janitor.
function CharacterUtils.ObserveOnDeath(humanoid: Humanoid, callback: () -> ())
	local mainJanitor = Janitor.new()
	mainJanitor:LinkToInstance(humanoid)

	local alreadyDied = false

	local function onDied()
		if alreadyDied then
			return
		end
		alreadyDied = true
		callback()
	end
	mainJanitor:Add(InstanceUtils.ObserveProperty(humanoid, "Health", function(health)
		if health > 0 then
			return
		end
		onDied()
	end))
	mainJanitor:Add(InstanceUtils.ObserveParent(humanoid, function(parent: Instance)
		if parent ~= nil then
			return
		end
		onDied()
	end))
	mainJanitor:Add(humanoid.Died:Connect(onDied))
	mainJanitor:Add(onDied)

	return mainJanitor
end

--- Checks if a `Humanoid` instance is actually dead.
function CharacterUtils.IsHumanoidDead(humanoid: Humanoid)
	return humanoid.Health <= 0
		or humanoid:GetState() == Enum.HumanoidStateType.Dead
		or not humanoid:IsDescendantOf(workspace)
end

--- Gets the alive character of a player if it exists. If there's no character, it'll yield until there is one. If it's dead, it won't be returned.
function CharacterUtils.GetAliveCharacter(player: Player) : Model?
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or CharacterUtils.IsHumanoidDead(humanoid) then
		return
	end
	return character
end

--- Gets the root part of a player's alive character.
function CharacterUtils.GetAliveRootPart(player: Player) : BasePart?
	local character = CharacterUtils.GetAliveCharacter(player)
	if not character then
		return
	end
	return character:FindFirstChild("HumanoidRootPart")
end

--- Gets the humanoid of a player's alive character.
function CharacterUtils.GetAlivePlayerHumanoid(player: Player) : Humanoid?
	local humanoid = CharacterUtils.GetPlayerHumanoid(player)
	if not humanoid or CharacterUtils.IsHumanoidDead(humanoid) then
		return
	end
	return humanoid
end

--- Equivalent to `Player.CharacterAdded:Connect()` but managed by Janitor.
function CharacterUtils.ObserveCharacter(
	player: Player,
	callback: (character: Model, characterJanitor: janitor.Janitor) -> ()
)
	local mainJanitor = Janitor.new()
	mainJanitor:LinkToInstance(player)

	local function onCharacterAdded(character: Model)
		mainJanitor:AddPromise(Promise.new(function(resolve)
			CharacterUtils.WaitForCharacterLoaded(character)
			return resolve()
		end):andThen(function()
			task.defer(callback, character, mainJanitor:AddObject(Janitor, nil, "LastCharacter"))
		end))
	end

	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	mainJanitor:Add(player.CharacterAdded:Connect(onCharacterAdded))

	return mainJanitor
end

--- Equivalent to waiting for a player's character's humanoid to appear.
--- Will execute code whenever a `Humanoid` appears in a player's character.
function CharacterUtils.ObserveHumanoid(
	player: Player,
	callback: (humanoid: Humanoid, humanoidJanitor: janitor.Janitor) -> ()
)
	return CharacterUtils.ObserveCharacter(player, function(character: Model, characterJanitor)
		characterJanitor:Add(
			InstanceUtils.ObserveChildrenWhichIsA(character, "Humanoid", function(humanoid: Humanoid, childJanitor) 
				local aliveJanitor = childJanitor:AddObject(Janitor)

				aliveJanitor:Add(CharacterUtils.ObserveOnDeath(humanoid, function()
					aliveJanitor:Cleanup()
				end))

				callback(humanoid, aliveJanitor)
			end)
		)
	end)
end

--- Checks if a player has an effect.
--- @return Returns a `boolean` indicating if the specified player has the effect and the level if it's true.
function CharacterUtils.CheckPlayerEffect(Player: Player, effectName: string): (boolean & number)?
    if Player.Character and InstanceUtils.FindFirstChild(Player.Character, "Effects."..effectName) then
        return true, Player.Character.Effects[effectName].Value
    end

    return false
end

--- Loads an animation into a rig, returning the corresponding `AnimationTrack` for usage.
--- If `YieldUntilLoad` is true, the code executing this function will yield until the `AnimationTrack` is fully loaded. Defaults to `false`.
function CharacterUtils.LoadAnimationFromID(Rig: Model, ID: string | {string} | {[string]: string}, YieldUntilLoad: boolean?): AnimationTrack
    if not Rig then
        error("[Utils:LoadAnimationFromID()]: Rig not provided or nil.")
        return
    end

    if not ID or #ID < 0 then
        error("[Utils:LoadAnimationFromID()]: Animation ID invalid or nil.")
        return
    end

    if typeof(ID) == "table" then
        ID = TypeUtils.DictToTable(ID)
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

    local Animation: Animation = AnimInstances:FindFirstChild(ID)
    if Animation then
        return Animator:LoadAnimation(Animation)
    else
        Animation = Instance.new("Animation")
        Animation.Name = ID
        Animation.AnimationId = ID
        Animation.Parent = AnimInstances
        
        local Track = Animator:LoadAnimation(Animation)

        local Timeout = 0
        if YieldUntilLoad and Track.Length <= 0 then
            repeat Timeout += task.wait()
            until Track.Length > 0 or Timeout >= 25
        end

        return Track
    end
end

--- Returns a list of every loaded player's character.
--- Also read `Utils:GetLoadedPlayers()`.
function CharacterUtils.GetLoadedCharacters(IncludeAFK: boolean?): {Model}
    local t: {Model} = {}

    for _, i in PlayerUtils.GetLoadedPlayers(IncludeAFK) do
        if i.Character then
            table.insert(t, i.Character)
        end
    end

    return t
end

--- Returns a list of all characters from every role instantiated.
function CharacterUtils.GetCharactersWithRoles(IncludeAFK: boolean?): {[string]: {Model}}
    local Characters = {}

    for _, Character in CharacterUtils.GetLoadedCharacters(IncludeAFK) do
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

return CharacterUtils
