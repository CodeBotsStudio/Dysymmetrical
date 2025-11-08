--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local CharManager = {}

local LocalPlayer = Players.LocalPlayer

local AbilityGUI = require(ReplicatedStorage.Classes.Ability.AbilityGUI)
local Utils = require(ReplicatedStorage.Modules.Utils)

function CharManager:Init()
    LocalPlayer.CharacterAdded:Connect(function(Char: Model)
        if Utils:FindFirstChild(Char, "Role").Value ~= "Spectator" then
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
    Utils:Print(CharacterAbilities.Abilities)
end

--- Loads a specific character's client stuff. The character itself is spawned in in `ServerScriptService.Managers.ServerCharacterManager`.
function CharManager:LoadCharacter(charName: string, charType: "Survivor" | "Killer", skinName: string?)
    task.delay(5, function()
        StarterGui:SetCore("ResetButtonCallback", true)
    end)

    local Char: Model = LocalPlayer.Character
    local Animate = Utils:FindFirstChild(Char, "Animate")

    local CharModule = Utils:CopyTable(require(Utils:GetCharacterModule(charType, charName, skinName)))
    CharModule.Owner = LocalPlayer

    Utils:PreloadAssets(CharModule.Config)

    Animate.idle.IdleAnim.AnimationId = CharModule.Config.AnimationIDs.IdleAnimation
    Animate.walk.WalkAnim.AnimationId = CharModule.Config.AnimationIDs.WalkAnimation
    Animate.run.RunAnim.AnimationId = CharModule.Config.AnimationIDs.RunAnimation
    local Sprinting = require(Char.PlayerAbilities.Default.Sprinting)
    Sprinting:ReloadAnimation(CharModule.Config.AnimationIDs.RunAnimation)
    Sprinting.SprintMultiplier = CharModule.GameplayConfig.SprintSpeedMultiplier

    self:_InitCharacterAbilities(CharModule)

    if charType == "Killer" then
        local Slash = require(Char.PlayerAbilities.CharacterAbilities).Abilities.Slash
        Slash:ReloadAnimation(CharModule.Config.AnimationIDs.SlashAnimation)
        Slash.Duration = CharModule.GameplayConfig.SlashDuration
        Slash.Cooldown = CharModule.GameplayConfig.SlashCooldown
    elseif charType ~= "Survivor" then
        LocalPlayer:Kick("https://www.youtube.com/watch?v=L8XbI9aJOXk")
        return
    end

    AbilityGUI:InitGUI()

    if CharModule.OnInit then
        CharModule:OnInit(Char)
    end

    return Char
end

return CharManager
