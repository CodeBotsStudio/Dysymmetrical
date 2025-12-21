local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)

local GlobalPrefab = Utils.Instance.FindFirstChild(script, "Enum", 0)
local ValuePrefab = Utils.Instance.FindFirstChild(script, "EnumValue", 0)
-- local OptionPrefab = Utils.Instance.FindFirstChild(script, "EnumOption", 0)

local Dropdown = {}

function Dropdown.New(CommandModule: ModuleScript, UI): ImageLabel
    local Config = require(CommandModule)

    local CommandFrame = GlobalPrefab:Clone()
    CommandFrame.Parent = UI.Content

    CommandFrame.Label.Text = Config.Name
    CommandFrame.Value.Text = "Current value: "..tostring(workspace:GetAttribute(Config.DisplayedAttribute))

    for lo, param in Config.Params do
        local Value = ValuePrefab:Clone()
        Value.Parent = CommandFrame.Values

        
    end
    
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

return Dropdown
