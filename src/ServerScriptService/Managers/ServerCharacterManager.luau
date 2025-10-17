--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local PlayerManager = require(script.Parent.PlayerManager)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local ServerCharacterManager = {}

local PlayersRemainingFolder = ReplicatedStorage.RoundInfo.PlayersRemaining

function ServerCharacterManager:Init()
end

--- Sets up a player's character specified by its name, its type, and a possible skin.
--- Can also take a `CFrame` parameter to pivot the character there.
function ServerCharacterManager:SetupCharacter(player: Player, charName: string, charType: "Survivor" | "Killer", skinName: string?, cf: CFrame?)
    local Char: Model = PlayerManager:_RespawnPlayer(player, charName, charType, skinName)
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

    print("sending to "..player.Name)
    self:_InitCharacter(player, CommonUtils:GetCharacterModule(charType, charName, skinName))

    return Char
end

--- Inits a character's abilities and sets its properties accordingly as specified in its `GameplayConfig`.
function ServerCharacterManager:_InitCharacter(player: Player, charModule: ModuleScript)
    local module = CommonUtils:CopyTable(require(charModule))
    module.Owner = player

    --Abilities
    local Char = player.Character
    local CharacterAbilities = require(Char.PlayerAbilities.CharacterAbilities)

    local Humanoid = CommonUtils:FindFirstChild(Char, "Humanoid")
    Humanoid.MaxHealth = module.GameplayConfig.Health
    Humanoid.Health = module.GameplayConfig.Health

    for name, value in module.GameplayConfig.StaminaProperties do
        Char.PlayerAttributes:FindFirstChild(name).Value = value
    end

    for _, Ability in module.GameplayConfig.Abilities do
        CharacterAbilities.Abilities[Ability] = Ability
        if Ability.Init then
            Ability:Init(module, player)
        end
    end

    if module.OnInit then
        module:OnInit(Char)
    end

    if module.Config.Voicelines and module.Config.Voicelines.Stunned then
        Char.Effects.ChildAdded:Connect(function(newChild)
            if newChild.Name == "Stunned" then
                Sounds:PlayVoiceline(Char, module.Config.Voicelines.Stunned)
            end
        end)
    end

    --Idle Voicelines every while
    if module.Config.Voicelines and module.Config.Voicelines.Idle then
        local Primary = Char.PrimaryPart or Char:FindFirstChild("HumanoidRootPart")
        if not Primary then
            return
        end

        local Connections = {}
        if module.Config.Voicelines.LMS then
            --TODO: implement unique LMS voicelines (USE THE KILL LINES AS AN EXAMPLE)
            table.insert(Connections, Network:SetConnection("LMSVoiceline", "BINDABLE_EVENT", function()
                Sounds:PlayVoiceline(Char, module.Config.Voicelines.LMS, {
                    Priority = 999,
                })
            end))
        end

        task.spawn(function()
            if module.Config.AnimationIDs.Execution then
                module.GameplayConfig.Cache.Animations["Execution"] = {}
                for name, i in module.Config.AnimationIDs.Execution do
                    module.GameplayConfig.Cache.Animations.Execution[name] = {}
                    for n, ie in i do
                        if n == "Survivor" then --no need to load survivor execution anims on killers
                            continue
                        end
                        module.GameplayConfig.Cache.Animations.Execution[name][n] = CommonUtils:LoadAnimationFromID(Char, ie, false)
                    end
                end
            end
        end)

        task.spawn(function()
            task.wait(math.random(10, 25))
            while player.Character and Char and player.Character == Char and Primary do
                if module.Config.Voicelines.Idle then
                    Sounds:PlayVoiceline(Char, module.Config.Voicelines.Idle, {
                        Priority = 0,
                    })
                end
                task.wait(math.random(10, 25))
            end

            for _, i in Connections do
                i:Disconnect()
            end
        end)
    end
end

return ServerCharacterManager
