local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local BoolSetting = {}

function BoolSetting:New(Bool: BoolValue, ExistingCheckbox: Frame?, Callback: (Value: boolean) -> ()?)
    if not Bool then
        Bool = Instance.new("BoolValue")
    end

    local BoolTable = setmetatable({
        SettingValue = Bool,
    }, BoolSetting)

    BoolTable.Instance = ExistingCheckbox or script.Checkbox:Clone()
    BoolTable.Instance.CheckboxButton.Checked.Visible = Bool.Value
    BoolTable.Instance.CheckboxButton.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    BoolTable.Instance.CheckboxButton.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)
    BoolTable.Instance.CheckboxButton.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        if Callback then
            task.spawn(Callback, not Bool.Value)
        end
        self:OnUpdate(BoolTable, not Bool.Value)
        Network:FireServerConnection("UpdateSetting", "REMOTE_EVENT", Bool, not Bool.Value)
    end)

    return BoolTable
end

function BoolSetting:OnUpdate(MetaTable, Value)
    MetaTable.Value = Value
    MetaTable.Instance.CheckboxButton.Checked.Visible = MetaTable.Value
end

return BoolSetting
