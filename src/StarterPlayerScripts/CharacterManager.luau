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
    "SlashAnimation",
}

function CharManager:Init()
    Utils.Character.ObserveCharacter(LocalPlayer, function(Char: Model)
        if Utils.Instance.FindFirstChild(Char, "Role").Value ~= "Spectator" then
            self:LoadCharacter(Char:GetAttribute("CharacterName"), Char.Role.Value, Char:GetAttribute("CharacterSkinName"))
        end
    end)
end

--- Initializes a character's client abilities.
function CharManager:_InitCharacterAbilities(Module)
    local CharacterAbilities = require(LocalPlayer.Character.PlayerAbilities.CharacterAbilities)

    CharacterAbilities.CharacterModule = Module
    for _, Ability in Module.GameplayConfig.Abilities do
        CharacterAbilities.Abilities[Ability.Name or Ability] = Ability
        if Ability.Init then
            Ability:Init(Module, LocalPlayer)
        end
    end

    for name, anim in Module.Config.AnimationIDs do
        if table.find(AnimLoadPrevented, name) then
            continue
        end

        Module.GameplayConfig.Cache.Animations[name] = Utils.Character.LoadAnimationFromID(LocalPlayer.Character, anim, false)
    end

    return CharacterAbilities
end

--- Loads a specific character's client stuff. The character itself is spawned in in `ServerScriptService.Managers.ServerCharacterManager`.
function CharManager:LoadCharacter(charName: string, charType: "Survivor" | "Killer", skinName: string?)
    task.delay(5, function()
        StarterGui:SetCore("ResetButtonCallback", true)
    end)

    local Char: Model = LocalPlayer.Character

    local CharModule = Utils.Type.CopyTable(require(Utils.Instance.GetCharacterModule(charType, charName, skinName)))
    CharModule.Owner = LocalPlayer

    Utils.Misc.PreloadAssets(CharModule.Config)

    local Sprinting = require(Char.PlayerAbilities.Default.Sprinting)
    Sprinting:ReloadAnimation(CharModule.Config.AnimationIDs.RunAnimation)
    Sprinting.SprintMultiplier = CharModule.GameplayConfig.SprintSpeedMultiplier

    Utils.Instance.FindFirstChild(Char, "PlayerAttributes.AnimationTransitionTime", 0).Value = CharModule.Config.AnimationTransitionTime

    --loading any anims in `Config.AnimationIDs` that aren't loaded by the engine itself
    task.defer(function()
        for name, anim in CharModule.Config.AnimationIDs do
            local animCodeName = name:gsub("Animation", "")
            if table.find(Character.AutoLoadedAnims, animCodeName) then
                continue
            end

            CharModule.GameplayConfig.Cache.Animations[animCodeName.."Anim"] = Utils.Character.LoadAnimationFromID(Char, anim, false)
        end
    end)

    local CharacterAbilities = self:_InitCharacterAbilities(CharModule)

    Char.Effects.ChildAdded:Connect(function(newChild)
        if newChild.Name == "Stunned" then
            if CharacterAbilities.Animations.Stunned then
                CharacterAbilities.Animations.Stunned:Play(0)
            end
            task.wait(0.2)
            if CharacterAbilities.Animations.StunnedEnd then
                task.delay(newChild:GetAttribute("Duration") - 0.2 - CharacterAbilities.Animations.StunnedEnd.Length, function()
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
