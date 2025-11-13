--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)

type Ability = {
    ModuleCode: any,
    Keybind: TextLabel,
    Timer: TextLabel,
    Uses: TextLabel?,
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

local PrefabContainer = Utils:FindFirstChild(script, "Prefabs")
local Prefabs = {
    Container = Utils:FindFirstChild(PrefabContainer, "CharacterAbilitiesContainer"),
    AbilityContainer = Utils:FindFirstChild(PrefabContainer, "AbilityContainer"),
    UsesLeftText = Utils:FindFirstChild(PrefabContainer, "UsesLeft"),
}

--- Function used to init a character's ability GUI based on their ability table's info stored in `StarterCharacterScripts.PlayerAbilities.CharacterAbilities`.
function AbilityGUI:InitGUI()
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
        table.insert(Abilities, self:_SetupAbilityFrame(AbilityT))
    end

    local Conns = {
        RunService.PreRender:Connect(function(_delta: number)
            for _, Ability: Ability in Abilities do
                self:_UpdateAbilityFrame(Ability, InputManager)
            end
        end),
        InputManager.SchemeChanged:Connect(function(CurrentScheme: string)
            for _, Ability: Ability in Abilities do
                self:_UpdateAbilityFrameInput(Ability, InputManager, CurrentScheme)
            end
        end),
    }
    for _, Ability: Ability in Abilities do
        self:_UpdateAbilityFrameInput(Ability, InputManager, InputManager.CurrentControlScheme)
    end

    --kids, remember to disconnect your useless crap!
    Container.Destroying:Connect(function()
        for _, Conn in Conns do
            Conn:Disconnect()
        end
    end)
end

--this is so messy wth
--- Function used to set up an entire ability's GUI for display in a character's GUI.
function AbilityGUI:_SetupAbilityFrame(Ability): Ability
    --we'll have to put everything in a frame right????
    local AbilityContainer: Frame = Prefabs.AbilityContainer:Clone()
    AbilityContainer.Name = Ability.Module.Name
    AbilityContainer.Position = self.AbilityFramePositions[Ability.Module.InputName]
    AbilityContainer.LayoutOrder = self.AbilityLayoutOrder[Ability.Module.InputName]
    AbilityContainer.Parent = Ability.Parent

    --what if i put skibidi toilet in here -Quinn definetly not Dyscarn
    local RenderImage: ImageLabel = AbilityContainer:FindFirstChildOfClass("ImageLabel")
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

--- Function used to update an ability's frame's values to display accurate information about the ability itself and its current state.
function AbilityGUI:_UpdateAbilityFrame(Ability: Ability, InputManager)
    --duh
    if Ability.ModuleCode.CooldownTimer > 0 then
        Ability.Timer.TextTransparency = 0
        Ability.Timer.Text = tostring(math.round(Ability.ModuleCode.CooldownTimer * 10) / 10)
    else
        Ability.Timer.TextTransparency = 1
    end

    --it would be stupid to not add this (again). -Dyscarn
    if Ability.Uses and Ability.ModuleCode.UseSettings.Limited then
        Ability.Uses.Text = Ability.ModuleCode.UsesLeft
    end
end

function AbilityGUI:_UpdateAbilityFrameInput(Ability: Ability, InputManager, CurrentScheme: string)
    --I HATE MOBILE SUPPORT GNMDKIMBKBMSPMBPJBSG
    if CurrentScheme ~= "Touch" then
        Ability.Keybind.TextTransparency = 0

        --slash isn't built different now nvm :(
        local Input = InputManager["DefaultActions"][Ability.ModuleCode.InputName]
        local Key = Input[CurrentScheme.."Key"] or Input["InputType"]

        --WOW THANKS DYSCARN FOR MAKING A COOL INPUT MANAGER THAT ACTUALLY WORKS AND SHOWS YOUR `preferred input device` // you're welcome Dyscarn
        Ability.Keybind.Text = Key.Name
        if CurrentScheme == "Gamepad" then
            Ability.Keybind.Text = Ability.Keybind.Text:gsub("Button", "")
        end
    else
        --NEVER SHOW UP ON MY FACE AGAIN!!!!
        Ability.Keybind.TextTransparency = 1
    end
end

return AbilityGUI
