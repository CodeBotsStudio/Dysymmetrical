local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Utils.Signal)

local LocalPlayer = Players.LocalPlayer

--- Key config.
export type Key = {
    --- The name of the key for usage.
    Name: string,
    --- Any subgroup in may be in.
    Subgroup: string, --we don't need subgroups of subgroups btw not going through that too lazy even if it's easy
    --- If false, it won't detect any input.
    Enabled: boolean,

    --- The keyboard key that will be detected.
    KeyboardKey: Enum.KeyCode?,
    --- The gamepad key that will be detected.
    GamepadKey: Enum.KeyCode?,
    --- Just used for mouse, really.
    InputType: Enum.UserInputType?, --used for mouse

    --TODO: do this.
    --- The mobile button that will be tied to the input (TBI).
    MobileButton: GuiButton?, --NEVER IMPLEMENTING THIS. >:(

    --- Signal fired when the input's pressed. Read `ReplicatedStorage.Utils.Signal`.
    Pressed: any,
    --- Signal fired when the input's released. Read `ReplicatedStorage.Utils.Signal`.
    Released: any,
}

local InputManager = {
    CurrentControlScheme = "Keyboard",
    SchemeChanged = Signal.new(),
}

function InputManager:_SetupKeybind(key: Key)
    key.Pressed = Signal.new()
    key.Released = Signal.new()

    UserInputService.InputBegan:Connect(function(i: InputObject, gpe: boolean)
        if gpe or not key.Enabled then return end
        
        if key.KeyboardKey or key.GamepadKey then
            if i.KeyCode == key.KeyboardKey or i.KeyCode == key.GamepadKey then
                key.Pressed:Fire()
            end
        end

        if key.InputType then
            if i.UserInputType == key.InputType then
                key.Pressed:Fire()
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(i: InputObject, gpe: boolean)
        if gpe or not key.Enabled then return end
        
        if key.KeyboardKey or key.GamepadKey then
            if i.KeyCode == key.KeyboardKey or i.KeyCode == key.GamepadKey then
                key.Released:Fire()
            end
        end

        if key.InputType then
            if i.UserInputType == key.InputType then
                key.Released:Fire()
            end
        end
    end)

    if key.Subgroup and #key.Subgroup > 0 then
        if not InputManager[key.Subgroup] then
            InputManager[key.Subgroup] = {}
        end
        InputManager[key.Subgroup][key.Name] = key
    else
        InputManager[key.Name] = key
    end
end

function InputManager:Init()
    --DEFAULT ACTIONS--
    InputManager:_SetupKeybind({
        Name = "Sprint",
        Subgroup = "DefaultActions",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.LeftShift,
        GamepadKey = Enum.KeyCode.ButtonL2,
    })
    InputManager:_SetupKeybind({
        Name = "FirstAbility",
        Subgroup = "DefaultActions",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.Q,
        GamepadKey = Enum.KeyCode.ButtonL1,
    })
    InputManager:_SetupKeybind({
        Name = "SecondAbility",
        Subgroup = "DefaultActions",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.E,
        GamepadKey = Enum.KeyCode.ButtonR1,
    })
    InputManager:_SetupKeybind({
        Name = "ThirdAbility",
        Subgroup = "DefaultActions",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.R,
        GamepadKey = Enum.KeyCode.ButtonY,
    })
    InputManager:_SetupKeybind({
        Name = "FourthAbility",
        Subgroup = "DefaultActions",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.F,
        GamepadKey = Enum.KeyCode.ButtonB,
    })

    --KILLER--
    InputManager:_SetupKeybind({
        Name = "Slash",
        Subgroup = "DefaultActions",

        Enabled = true,

        GamepadKey = Enum.KeyCode.ButtonR2,

        InputType = Enum.UserInputType.MouseButton1,
    })

    --MISC--
    InputManager:_SetupKeybind({
        Name = "EmotePanel",
        Subgroup = "Miscellaneous",

        Enabled = true,
        
        KeyboardKey = Enum.KeyCode.G,
        GamepadKey = Enum.KeyCode.DPadDown,
    })
    InputManager:_SetupKeybind({
        Name = "StopEmote",
        Subgroup = "Miscellaneous",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.Space,
        GamepadKey = Enum.KeyCode.ButtonA,
    })

    InputManager:_SetupKeybind({
        Name = "TogglePlayerList",
        Subgroup = "Miscellaneous",

        Enabled = true,

        KeyboardKey = Enum.KeyCode.Tab,
    })

    --SETTING UP--
    local function ChangePreferred(value: Enum.UserInputType)
        local LastControlScheme = InputManager.CurrentControlScheme
        if value.Name:find("Gamepad") then
            InputManager.CurrentControlScheme = "Gamepad"
        elseif value == Enum.UserInputType.Touch then
            InputManager.CurrentControlScheme = "Touch"
        else
            InputManager.CurrentControlScheme = "Keyboard"
        end
        if InputManager.CurrentControlScheme ~= LastControlScheme then
            InputManager.SchemeChanged:Fire(InputManager.CurrentControlScheme)
        end
    end
    UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
        if gpe then return end
        ChangePreferred(input.UserInputType)
    end)

    -- RunService.PreRender:Connect(function(_delta: number)
    --     ChangePreferred(UserInputService:GetLastInputType())
    -- end)

    ChangePreferred(UserInputService:GetLastInputType())

    LocalPlayer.CharacterAdded:Connect(function(_char: Model)
        for _, input in InputManager do
            if typeof(input) ~= "table" or input.Fire ~= nil then
                continue
            end
            
            if input.Enabled ~= nil then --checking if it's a table of keys
                input.Enabled = true
            else
                for _, i: Key in input do
                    if typeof(i) ~= "table" then
                        continue
                    end
                    if i.Enabled ~= nil then --checking if it's an actual key and not smth random idk lol
                        i.Enabled = true
                    end
                end
            end
        end
    end)
end

return InputManager
