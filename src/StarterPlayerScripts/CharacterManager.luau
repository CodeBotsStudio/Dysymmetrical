--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local CharManager = {}

local LocalPlayer = Players.LocalPlayer

local AbilityGUI = require(ReplicatedStorage.Classes.Ability.AbilityGUI)
local Character = require(ReplicatedStorage.Classes.Character)
local Utils = require(ReplicatedStorage.Modules.Utils)

local AnimLoadPrevented = {
    "IdleAnimation",
    "WalkAnimation",
    "RunAnimation",
    "Execution",
}

function CharManager:Init()
    Utils.Character.ObserveCharacter(LocalPlayer, function(Char: Model)
        if Char:FindFirstChild("Role").Value ~= "Spectator" then
            CharManager.LoadCharacter(Char:GetAttribute("CharacterName"), Char.Role.Value, Char:GetAttribute("CharacterSkinName"))
        end
    end)
end

--- Initializes a character's client abilities.
function CharManager._InitCharacterAbilities(Module)
    local CharacterAbilities = require(LocalPlayer.Character.PlayerAbilities.CharacterAbilities)

    CharacterAbilities.CharacterModule = Module
    for _, Ability in Module.GameplayConfig.Abilities do
        CharacterAbilities.Abilities[Ability.Name or Ability] = Ability
        if Ability.Init then
            Ability:Init(Module, LocalPlayer)
        end
    end

    local function LoadAnim(name, anim)
        if typeof(anim) == "table" then
            for Name, Anim in anim do
                LoadAnim(Name, Anim)
            end
            return
        end

        if table.find(AnimLoadPrevented, name) then
            return
        end

        Module.GameplayConfig.Cache.Animations[name] = Utils.Character.LoadAnimationFromID(LocalPlayer.Character, anim, false)
    end

    for name, anim in Module.Config.AnimationIDs do
        LoadAnim(name, anim)
    end

    return CharacterAbilities
end

--- Loads a specific character's client stuff. The character itself is spawned in in `ServerScriptService.Managers.ServerCharacterManager`.
function CharManager.LoadCharacter(charName: string, charType: "Survivor" | "Killer", skinName: string?)
    task.delay(5, function()
        StarterGui:SetCore("ResetButtonCallback", true)
    end)

    local Char: Model = LocalPlayer.Character

    local CharModule = Utils.Type.CopyTable(require(Utils.Instance.GetCharacterModule(charType, charName, skinName)))
    CharModule.Owner = LocalPlayer

    Utils.Misc.PreloadAssets(CharModule.Config)

    local Sprinting = require(Char.PlayerAbilities.Default.Sprinting)
    Sprinting.SprintMultiplier = CharModule.GameplayConfig.SprintSpeedMultiplier
    task.defer(function()
        local AnimationManager = require(Char:FindFirstChild("AnimationManager"))
        AnimationManager:LoadAnimation("Idle", CharModule.Config.AnimationIDs.IdleAnimation)
        AnimationManager:LoadAnimation("Walk", CharModule.Config.AnimationIDs.WalkAnimation)
        AnimationManager:LoadAnimation("Sprint", CharModule.Config.AnimationIDs.RunAnimation)
    end)

    Utils.Instance.FindFirstChild(Char, "PlayerAttributes.AnimationTransitionTime", 0).Value = CharModule.Config.AnimationTransitionTime

    --loading any anims in `Config.AnimationIDs` that aren't loaded by the engine itself
    task.defer(function()
        for name, anim in CharModule.Config.AnimationIDs do
            local animCodeName = name:gsub("Animation", "")
            if table.find(Character.AutoLoadedAnims, animCodeName) or animCodeName:lower():find("execution") then
                continue
            end

            CharModule.GameplayConfig.Cache.Animations[animCodeName.."Anim"] = Utils.Character.LoadAnimationFromID(Char, anim, false)
        end
    end)

    local CharacterAbilities = CharManager._InitCharacterAbilities(CharModule)

    Char.Effects.ChildAdded:Connect(function(newChild)
        if newChild.Name == "Stunned" then
            if CharacterAbilities.Animations.Stunned then
                CharacterAbilities.Animations.Stunned:Play(0)
            end
            if CharacterAbilities.Animations.StunnedLoop then
                task.delay(CharacterAbilities.Animations.Stunned.Length - 0.1, function()
                    if (CharacterAbilities.Animations.Stunned :: AnimationTrack).IsPlaying then
                        CharacterAbilities.Animations.Stunned:Stop(0)
                    end
                    if not CharacterAbilities.Animations.StunnedEnd.IsPlaying then
                        CharacterAbilities.Animations.StunnedLoop:Play(0)
                    end
                end)
            end
            if CharacterAbilities.Animations.StunnedEnd then
                task.delay((newChild:GetAttribute("Duration") < 0.2 and 0.2 or newChild:GetAttribute("Duration")) - 0.2 - CharacterAbilities.Animations.StunnedEnd.Length, function()
                    if CharacterAbilities.Animations.Stunned then
                        CharacterAbilities.Animations.Stunned:Stop(0)
                    end
                    if CharacterAbilities.Animations.StunnedLoop then
                        CharacterAbilities.Animations.StunnedLoop:Stop(0)
                    end
                    CharacterAbilities.Animations.StunnedEnd:Play(0)
                end)
            end
        end
    end)

    AbilityGUI.InitGUI()

    if CharModule.OnInit then
        CharModule:OnInit(Char)
    end

    return Char
end

return CharManager
