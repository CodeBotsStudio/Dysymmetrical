local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local BoolCommand = {}

function BoolCommand.New(CommandModule: ModuleScript, UI): ImageLabel
    local Config = require(CommandModule)

    local CommandFrame = script:FindFirstChildWhichIsA("ImageLabel"):Clone()
    CommandFrame.Parent = UI.Content

    CommandFrame.Label.Text = Config.Name
    CommandFrame.Value.Text = "Current value: "..tostring(workspace:GetAttribute(Config.DisplayedAttribute))
    CommandFrame.Execute.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    CommandFrame.Execute.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)
    CommandFrame.Execute.MouseButton1Click:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        local Value = Network:FireServerConnection("ExecuteCommand", "REMOTE_FUNCTION", CommandModule.Name)
        CommandFrame.Value.Text = "Current value: "..tostring(Value or workspace:GetAttribute(Config.DisplayedAttribute))
    end)

    return CommandFrame
end

return BoolCommand
