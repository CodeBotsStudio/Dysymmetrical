--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local PlayerManager = require(script.Parent.PlayerManager)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local Rand = Random.new()

local ServerCharacterManager = {}

local PlayersRemainingFolder = ReplicatedStorage.RoundInfo.PlayersRemaining

function ServerCharacterManager:Init()
end

function ServerCharacterManager._PositionCharacter(Char: Model, charType: "Survivor" | "Killer", cf: CFrame?)
    if cf then
        Char:PivotTo(cf)
        return
    end

    --will try to get the current map
    local Map = workspace:FindFirstChild("Map")
    if not Map then
        return
    end

    --will try to get the map itself (because the map itself is parented to a folder named `Map` where `Config` and `Behaviour` reside)
    Map = Map:FindFirstChild("Map")
    if not Map then
        warn("[ServerCharacterManager._PositionCharacter()] The map should be in a whole model inside of the map's folder! Check the template map! Using the folder itself instead...")
        
        Map = workspace:FindFirstChild("Map")
    end

    --will try to get the spawn points of the map
    local SpawnPoints = Map:FindFirstChild("SpawnPoints")
    if not SpawnPoints then
        --i am so lazy to split this string
        warn("[ServerCharacterManager._PositionCharacter()] Spawn points aren't set for this map! Inside of the map there should be a folder called \"SpawnPoints\" containing a folder for every possible spawn layout also containing a folder for every role (\"Killers\" and \"Survivors\" by default)! Preventing character positioning...")

        return
    end

    --will check if the map has any spawn point layouts
    SpawnPoints = SpawnPoints:GetChildren()
    if #SpawnPoints <= 0 then
        warn("[ServerCharacterManager._PositionCharacter()] The map's spawn point folder is empty! Make sure to make some spawn point layouts! Preventing character positioning...")
        
        return
    end

    --will get a random layout if there's more than 1 available (which there shouldn't)
    SpawnPoints = SpawnPoints[#SpawnPoints > 1 and Rand:NextInteger(1, #SpawnPoints) or 1]
    local LayoutName = SpawnPoints.Name
    --will try to get the spawn points for the character's specific role
    SpawnPoints = SpawnPoints:FindFirstChild(charType.."s")

    if not SpawnPoints then
        --i am so lazy to split this string
        warn("[ServerCharacterManager._PositionCharacter()] There are no spawn points for the \""..charType.."\" role! Make sure the folder named \""..LayoutName.."\" in this map's layouts contains a folder for this role named \""..charType.."s\"! Preventing character positioning...")
        
        return
    end

    --will try to get any spawn points in the folder
    SpawnPoints = SpawnPoints:GetChildren()
    if #SpawnPoints <= 0 then
        --i am so lazy to split this string
        warn("[ServerCharacterManager._PositionCharacter()] Spawn Points aren't set for the \""..charType.."\" role in this map! Preventing character positioning...")

        return
    end

    --will try to choose a BasePart spawnpoint from the children of the folder
    local ChosenSpawnPoint = SpawnPoints[Rand:NextInteger(1, #SpawnPoints)]
    if not ChosenSpawnPoint:IsA("BasePart") then
        --i could make this cycle to another spawn but meh the rest would probably be badly set up the same way so yeah
        warn("[ServerCharacterManager._PositionCharacter()] Chosen spawn point is not a BasePart! Make sure all of your spawn points are invisible, anchored, non-collidable baseparts which anchor point is touching the ground! Check the template map! Preventing character positioning...")

        return
    end

    --will move the character to that spawn point
    Char:PivotTo(ChosenSpawnPoint.CFrame)
end

--- Sets up a player's character specified by its name, its type, and a possible skin.
--- Can also take a `CFrame` parameter to pivot the character there.
function ServerCharacterManager.SetupCharacter(player: Player, charName: string, charType: "Survivor" | "Killer", skinName: string?, cf: CFrame?)
    local Char: Model = PlayerManager._RespawnPlayer(player, charName, charType, skinName)
    --setting the character's position
    ServerCharacterManager._PositionCharacter(Char, charType, cf)

    if charType == "Survivor" then
	    local Remaining = Instance.new("ObjectValue") --only for survivors since there's only ever going to be 1 killer (i'm lazy to make the possibility to have multiple and it'd be too broken lol)
	    Remaining.Name = player.UserId
	    Remaining.Value = player
	    Remaining.Parent = PlayersRemainingFolder
    end

    if not charName or not charType then
        return Char
    end

    ServerCharacterManager._InitCharacter(player, Utils.Instance.GetCharacterModule(charType, charName, skinName))

    return Char
end

--- Inits a character's abilities and sets its properties accordingly as specified in its `GameplayConfig`.
function ServerCharacterManager._InitCharacter(player: Player, charModule: ModuleScript)
    local module = Utils.Type.CopyTable(require(charModule))
    module.Owner = player

    --Abilities
    local Char = player.Character
    local CharacterAbilities = require(Char.PlayerAbilities.CharacterAbilities)
    CharacterAbilities.CharacterModule = module
    
    local Animate = Char:FindFirstChild("Animate")
    Animate.idle.IdleAnim.AnimationId = module.Config.AnimationIDs.IdleAnimation
    Animate.walk.WalkAnim.AnimationId = module.Config.AnimationIDs.WalkAnimation
    Animate.run.RunAnim.AnimationId = module.Config.AnimationIDs.RunAnimation

    local Humanoid = Char:FindFirstChildWhichIsA("Humanoid")
    Humanoid.MaxHealth = module.GameplayConfig.Health
    Humanoid.Health = module.GameplayConfig.Health
    Humanoid.JumpPower = 0
    Humanoid.JumpHeight = 0

    Utils.Misc.PreloadAssets(module.Config)

    for name, value in module.GameplayConfig.StaminaProperties do
        local Property = Char.PlayerAttributes:FindFirstChild(name)
        if not Property then
            continue
        end

        Property.Value = value
    end

    for _, Ability in module.GameplayConfig.Abilities do
        Ability:Init(module, player)
        CharacterAbilities.Abilities[Ability] = Ability
    end

    task.defer(function()
        -- loading all execution animations
        task.defer(function()
            for rootName, _ in module.Config.AnimationIDs do
                if not rootName:lower():find("execution") then
                    continue
                end

                module.GameplayConfig.Cache.Animations[rootName] = {}

                for name, anims in module.Config.AnimationIDs[rootName] do
                    module.GameplayConfig.Cache.Animations[rootName][name] = {}
                    for animName, anim in anims do
                        if animName:lower() ~= "killer" then
                            continue
                        end

                        module.GameplayConfig.Cache.Animations[rootName][name][animName] = Utils.Character.LoadAnimationFromID(Char, anim)
                    end
                end
            end
        end)

        if not module.Config.Voicelines then
            return
        end

        local Primary = Utils.Character.GetRootPart(Char)
        if not Primary then
            return
        end

        local VoicelineJanitor = Janitor.new()
        VoicelineJanitor:LinkToInstance(Char)

        if module.Config.Voicelines.Stunned then
            Char.Effects.ChildAdded:Connect(function(newChild)
                if newChild.Name == "Stunned" then
                    Sounds.PlayVoiceline(Char, module.Config.Voicelines.Stunned)
                end
            end)
        end

        task.defer(function()
            if not module.Config.Voicelines.Idle then
                return
            end

            task.wait(math.random(10, 25))
            while player.Character and Char and player.Character == Char and Primary do
                if module.Config.Voicelines.Idle then
                    Sounds.PlayVoiceline(Char, module.Config.Voicelines.Idle, {
                        Priority = 0,
                    })
                end
                task.wait(math.random(10, 25))
            end
        end)

        if not module.Config.Voicelines.LMS then
            return
        end

        VoicelineJanitor:Add(Network:SetConnection("LMSVoiceline", "BINDABLE_EVENT", function(LastMan: Player)
            local Voiceline =
                module.Config.Voicelines.LMS[LastMan:GetAttribute("CharacterSkinName") and LastMan:GetAttribute("CharacterSkinName")..LastMan:GetAttribute("CharacterName") or LastMan:GetAttribute("CharacterName")]
                or module.Config.Voicelines.LMS["Default"]
                or module.Config.Voicelines.LMS

            Sounds.PlayVoiceline(Char, Voiceline, {
                Priority = 999,
            })
        end))
    end)

    if module.OnInit then
        module:OnInit(Char)
    end
end

return ServerCharacterManager
