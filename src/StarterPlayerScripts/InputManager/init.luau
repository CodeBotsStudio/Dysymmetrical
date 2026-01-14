local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Utils.Signal)

local InputManager = {
    --- WARNING: this won't change in server! Use `UIS.PreferredInput` instead!
    CurrentControlScheme = "Keyboard",
    --- WARNING: this won't fire in server! Use `UIS.PreferredInput` instead!
    SchemeChanged = Signal.new(),
}

function InputManager:Init()
    if RunService:IsServer() then
        return
    end

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

    Players.LocalPlayer.CharacterAdded:Connect(function(_char: Model)
        for _, context in script.InputActions:GetChildren() do
            if not context:IsA("InputContext") then
                continue
            end
            context.Enabled = true

            for _, action in context:GetChildren() do
                if not action:IsA("InputAction") then
                    continue
                end

                action.Enabled = true
            end
        end
    end)
end

--making these functions to provide safe autocompletion, nothing else
function InputManager:GetInputContext(name: string): InputContext
    local Folder = script.InputActions:FindFirstChild(name)

    if not Folder:IsA("InputContext") then
        warn("[InputManager:GetInputAction()] Child \""..name.."\" isn't an input context!", debug.traceback())
        return
    end

    return Folder
end

function InputManager:GetInputAction(path: string): InputAction
    local Folder = script.InputActions
    local Steps = path:split(".")

    for _, Step in ipairs(Steps) do
        Folder = Folder:FindFirstChild(Step)
        if not Folder then
            break
        end
    end

    if not Folder:IsA("InputAction") then
        warn("[InputManager:GetInputAction()] Path \""..path.."\" isn't an input action!", debug.traceback())
        return
    end

    return Folder
end

function InputManager:GetInputBinding(path: string): InputBinding
    local Folder = script.InputActions
    local Steps = path:split(".")

    for _, Step in ipairs(Steps) do
        Folder = Folder:FindFirstChild(Step)
        if not Folder then
            break
        end
    end

    if not Folder:IsA("InputBinding") then
        warn("[InputManager:GetInputAction()] Path \""..path.."\" isn't an input binding!", debug.traceback())
        return
    end

    return Folder
end

return InputManager
