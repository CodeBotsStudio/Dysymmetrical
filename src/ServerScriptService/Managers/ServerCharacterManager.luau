--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)
local PlayerManager = require(script.Parent.PlayerManager)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local ServerCharacterManager = {}

local PlayersRemainingFolder = ReplicatedStorage.RoundInfo.PlayersRemaining

function ServerCharacterManager:Init()
end

--- Sets up a player's character specified by its name, its type, and a possible skin.
--- Can also take a `CFrame` parameter to pivot the character there.
function ServerCharacterManager.SetupCharacter(player: Player, charName: string, charType: "Survivor" | "Killer", skinName: string?, cf: CFrame?)
    local Char: Model = PlayerManager._RespawnPlayer(player, charName, charType, skinName)
    if cf then
        Char:PivotTo(cf)
    end

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
    
    local Animate = Utils.Instance.FindFirstChild(Char, "Animate")
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

        local Primary = Char.PrimaryPart or Char:FindFirstChild("HumanoidRootPart") or Humanoid.RootPart
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
