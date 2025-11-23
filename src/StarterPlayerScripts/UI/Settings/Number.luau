local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local NumberSetting = {}

function NumberSetting:New(NumberValue: NumberValue, ExistingInput: TextBox?, Callback: (Value: number) -> ()?)
    if not NumberValue then
        NumberValue = Instance.new("NumberValue")
    end

    local NumberTable = setmetatable({
        SettingValue = NumberValue,
    }, NumberSetting)

    NumberTable.Instance = ExistingInput or script.NumberInput:Clone()
    NumberTable.Value = NumberValue.Value
    NumberTable.Instance.Input.Text = tostring(NumberTable.Value)

    NumberTable.Instance.Input.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    NumberTable.Instance.Input.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)
    NumberTable.Instance.Input.FocusLost:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
    end)

    local Bounds = {
        Min = NumberValue:GetAttribute("MinValue") or 0,
        Max = NumberValue:GetAttribute("MaxValue") or 100,
    }
    local TextBox: TextBox = NumberTable.Instance.Input

    local LastNumber = NumberTable.Value
    TextBox.FocusLost:Connect(function()
        local StrNum = TextBox.Text:match("%d+")
        if not StrNum or #StrNum <= 0 then
            TextBox.Text = tostring(LastNumber)
            return
        end

        local NewValue = tonumber(StrNum)
        NewValue = math.clamp(NewValue, Bounds.Min, Bounds.Max)
        LastNumber = NewValue

        TextBox.Text = tostring(NewValue)

        if Callback then
            task.spawn(Callback, NewValue)
        end

        Network:FireServerConnection("UpdateSetting", "REMOTE_EVENT", NumberValue, NewValue)
    end)

    return NumberTable
end

return NumberSetting