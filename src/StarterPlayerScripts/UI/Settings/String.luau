local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local StringSetting = {}

function StringSetting:New(StringValue: StringValue, ExistingInput: TextBox?, Callback: (Value: string) -> ()?)
    if not StringValue then
        StringValue = Instance.new("StringValue")
    end

    local StringTable = setmetatable({
        SettingValue = StringValue,
    }, StringSetting)

    StringTable.Instance = ExistingInput or script.StringInput:Clone()
    StringTable.Value = StringValue.Value
    StringTable.Instance.Input.Text = StringTable.Value

    StringTable.Instance.Input.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    StringTable.Instance.Input.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)
    StringTable.Instance.Input.FocusLost:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
    end)

    local TextBox: TextBox = StringTable.Instance.Input

    TextBox.FocusLost:Connect(function()
        if Callback then
            task.spawn(Callback, TextBox.Text)
        end

        Network:FireServerConnection("UpdateSetting", "REMOTE_EVENT", StringValue, TextBox.Text)
    end)

    return StringTable
end

return StringSetting