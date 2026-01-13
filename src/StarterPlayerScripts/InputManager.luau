local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Utils.Signal)

local LocalPlayer = Players.LocalPlayer

--- Key config.
export type Key = {
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
    Pressed: Signal.Signal<>,
    --- Signal fired when the input's released. Read `ReplicatedStorage.Utils.Signal`.
    Released: Signal.Signal<>,
}

local function SetupKeybind(key: Key): Key
    key.Pressed = Signal.new()
    key.Released = Signal.new()

    UserInputService.InputBegan:Connect(function(inputObject: InputObject, gameProcessedEvent: boolean)
        if gameProcessedEvent or not key.Enabled then return end
        
        if key.KeyboardKey or key.GamepadKey then
            if inputObject.KeyCode == key.KeyboardKey or inputObject.KeyCode == key.GamepadKey then
                key.Pressed:Fire()
            end
        end

        if key.InputType then
            if inputObject.UserInputType == key.InputType then
                key.Pressed:Fire()
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(inputObject: InputObject, gameProcessedEvent: boolean)
        if gameProcessedEvent or not key.Enabled then return end
        
        if key.KeyboardKey or key.GamepadKey then
            if inputObject.KeyCode == key.KeyboardKey or inputObject.KeyCode == key.GamepadKey then
                key.Released:Fire()
            end
        end

        if key.InputType then
            if inputObject.UserInputType == key.InputType then
                key.Released:Fire()
            end
        end
    end)

    return key
end

local InputManager = {
    CurrentControlScheme = "Keyboard",
    SchemeChanged = Signal.new(),

    DefaultActions = {
        Sprint = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.LeftShift,
            GamepadKey = Enum.KeyCode.ButtonL2,
        }),
        FirstAbility = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.Q,
            GamepadKey = Enum.KeyCode.ButtonL1,
        }),
        SecondAbility = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.E,
            GamepadKey = Enum.KeyCode.ButtonR1,
        }),
        ThirdAbility = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.R,
            GamepadKey = Enum.KeyCode.ButtonY,
        }),
        FourthAbility = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.F,
            GamepadKey = Enum.KeyCode.ButtonB,
        }),
        Slash = SetupKeybind({
            Enabled = true,

            InputType = Enum.UserInputType.MouseButton1,
            GamepadKey = Enum.KeyCode.ButtonR2,
        }),
    },
    Miscellaneous = {
        EmotePanel = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.G,
            GamepadKey = Enum.KeyCode.DPadDown,
        }),
        StopEmote = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.Space,
            GamepadKey = Enum.KeyCode.ButtonA,
        }),
        TogglePlayerList = SetupKeybind({
            Enabled = true,

            KeyboardKey = Enum.KeyCode.Tab,
        }),
    },
}

function InputManager:Init()
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

    ChangePreferred(UserInputService:GetLastInputType())

    LocalPlayer.CharacterAdded:Connect(function(_char: Model)
        for _, input in InputManager do
            if typeof(input) ~= "table" or input.Fire ~= nil then
                continue
            end
            
            if input.Enabled ~= nil then --checking if it's a table of keys
                input.Enabled = true
            else
                for _, key: Key in input do
                    if typeof(key) ~= "table" then
                        continue
                    end
                    if key.Enabled ~= nil then --checking if it's an actual key and not smth random idk lol
                        key.Enabled = true
                    end
                end
            end
        end
    end)
end

return InputManager
