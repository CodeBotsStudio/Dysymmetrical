--!nocheck

--it was definitely not 3 am when writing this months ago (excusing the funny comments)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ability = require(script.Parent)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

type Ability = {
    ModuleCode: Ability.Ability,
    Keybind: TextLabel,
    Timer: TextLabel,
    Uses: TextLabel?,
    Interactor: ImageButton,
}

local AbilityGUI = {
    AbilityFramePositions = {
        Slash = UDim2.fromScale(0.675, 0.9),
        FirstAbility = UDim2.fromScale(0.745, 0.9),
        SecondAbility = UDim2.fromScale(0.815, 0.9),
        ThirdAbility = UDim2.fromScale(0.885, 0.9),
        FourthAbility = UDim2.fromScale(0.605, 0.9),
    },
    AbilityLayoutOrder = {
        Slash = 1,
        FirstAbility = 2,
        SecondAbility = 3,
        ThirdAbility = 4,
        FourthAbility = 5,
    },
}

local PrefabContainer = Utils.Instance.FindFirstChild(script, "Prefabs")
local Prefabs = {
    Container = Utils.Instance.FindFirstChild(PrefabContainer, "CharacterAbilitiesContainer"),
    AbilityContainer = Utils.Instance.FindFirstChild(PrefabContainer, "AbilityContainer"),
    UsesLeftText = Utils.Instance.FindFirstChild(PrefabContainer, "UsesLeft"),
}

--- Function used to init a character's ability GUI based on their ability table's info stored in `StarterCharacterScripts.PlayerAbilities.CharacterAbilities`.
function AbilityGUI.InitGUI()
    local InputManager = require(Players.LocalPlayer.PlayerScripts.InputManager)
    local Character = Players.LocalPlayer.Character

    --creating the entire gui
    local Container = Prefabs.Container:Clone()
    Container.Name = Character:GetAttribute("CharacterName")
    Container.Parent = Players.LocalPlayer.PlayerGui.CharacterGUI

    local Abilities: {Ability} = {}

    --this gets every single ability's properties and uses them
    --it's fucking genius!!
    for _, Ability in require(Players.LocalPlayer.Character.PlayerAbilities.CharacterAbilities).Abilities do
        if Ability.Passive ~= nil and Ability.Passive == true then
            continue
        end
        local AbilityT = {
            Module = Ability,
            RenderImage = Ability.RenderImage,
            UICorner = Ability.UICorner,
            Parent = Container,
        }
        table.insert(Abilities, AbilityGUI._SetupAbilityFrame(AbilityT))
    end

    local JanitorInstance = Janitor.new()
    JanitorInstance:LinkToInstance(Container)

    JanitorInstance:Add(InputManager.SchemeChanged:Connect(function(CurrentScheme: string)
        for _, Ability: Ability in Abilities do
            AbilityGUI._UpdateAbilityFrameInput(Ability, InputManager, CurrentScheme)
        end
    end), "Disconnect")

    for _, Ability: Ability in Abilities do
        AbilityGUI._UpdateAbilityFrameInput(Ability, InputManager, InputManager.CurrentControlScheme)

        --it would be stupid to not add this (again). -Dyscarn
        -- uses label
        if Ability.Uses then
            JanitorInstance:Add(Ability.ModuleCode.Signals.ChargesChanged:Connect(function(amount: number)
                Ability.Uses.Text = tostring(amount)
            end), "Disconnect")
        end

        if Ability.Timer then
            Ability.Timer.TextTransparency = 1
        end

        JanitorInstance:Add(Ability.ModuleCode.Signals.CooldownSet:Connect(function(_cooldownSet: number)
            Ability.Timer.TextTransparency = 0
            while Ability.Timer and Ability.ModuleCode.CooldownTimer > 0 do
                -- failsafe if the ui gets destroyed for any reason
                if not Ability.Timer then
                    break
                end
                Ability.Timer.Text = tostring(math.ceil(Ability.ModuleCode.CooldownTimer * 10) / 10)
                task.wait(0.025)
            end
            -- failsafe if the ui gets destroyed for any reason
            if Ability.Timer then
                Ability.Timer.TextTransparency = 1
            end
        end), "Disconnect")

        JanitorInstance:Add(Ability.Interactor.MouseButton1Click:Connect(function()
            Ability.ModuleCode:AttemptUse()
        end), "Disconnect")
    end
end

--this is so messy wth
--- Function used to set up an entire ability's GUI for display in a character's GUI.
function AbilityGUI._SetupAbilityFrame(Ability): Ability
    --we'll have to put everything in a frame right????
    local AbilityContainer: Frame = Prefabs.AbilityContainer:Clone()
    AbilityContainer.Name = Ability.Module.Name
    AbilityContainer.Position = AbilityGUI.AbilityFramePositions[Ability.Module.InputName]
    AbilityContainer.LayoutOrder = AbilityGUI.AbilityLayoutOrder[Ability.Module.InputName]
    AbilityContainer.Parent = Ability.Parent

    --what if i put skibidi toilet in here -Quinn definetly not Dyscarn
    local RenderImage: ImageLabel = AbilityContainer:FindFirstChildWhichIsA("ImageLabel")
    RenderImage.Image = Ability.RenderImage
    if Ability.UICorner then
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = RenderImage
    end

    --COOLDOWNS ARE IMPORTANT INFO YOU DIPSHIT!!!!
    local CooldownTimer: TextLabel = AbilityContainer:FindFirstChild("CooldownTime")
    CooldownTimer.Text = Ability.Module.Cooldown

    --KEYBINDS AS WELL!!! IF NOT, HOW ARE YOU GONNA KNOW WHAT YOU PRESS???????
    --(they WERE here but now they're dynamic TOODLES :D)

    --maybe the name not so much BUT YOU'LL HAVE TO REFERENCE IT IN A SPECIFIC WAY WON'T YOU?????
    AbilityContainer:FindFirstChild("Name").Text = Ability.Module.Name

    local AbilityT: Ability = {
        ModuleCode = Ability.Module,
        Keybind = AbilityContainer:FindFirstChild("Keybind"),
        Timer = CooldownTimer,
        Interactor = AbilityContainer:FindFirstChild("Interactor"),
    }

    --it would be stupid to not add this. -Dyscarn
    if Ability.Module.UseSettings.Limited then
        local UsesLeft: TextLabel = Prefabs.UsesLeftText:Clone()
        UsesLeft.Text = Ability.Module.UseSettings.InitialUses
        UsesLeft.Parent = AbilityContainer

        AbilityT.Uses = UsesLeft
    end

    return AbilityT
end

function AbilityGUI._UpdateAbilityFrameInput(Ability: Ability, InputManager, CurrentScheme: string)
    --I HATE MOBILE SUPPORT GNMDKIMBKBMSPMBPJBSG
    if CurrentScheme ~= "Touch" then
        Ability.Keybind.TextTransparency = 0

        --slash isn't built different now nvm :(
        local Input = InputManager.DefaultActions[Ability.ModuleCode.InputName]
        local Key = Input[CurrentScheme.."Key"] or Input["InputType"]

        --WOW THANKS DYSCARN FOR MAKING A COOL INPUT MANAGER THAT ACTUALLY WORKS AND SHOWS YOUR `preferred input device` // you're welcome Dyscarn
        Ability.Keybind.Text = Key.Name
        if CurrentScheme == "Gamepad" then
            Ability.Keybind.Text = Ability.Keybind.Text:gsub("Button", "")
        end

        return
    end
    --NEVER SHOW UP ON MY FACE AGAIN!!!!
    Ability.Keybind.TextTransparency = 1
end

return AbilityGUI
