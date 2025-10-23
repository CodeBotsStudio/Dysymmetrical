--!nocheck

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Signal = require(ReplicatedStorage.Utils.Signal)

local ButtonPrefab = Utils:FindFirstChild(script, "EmoteButton")

return {
    New = function(Slot: number, Parent: Instance)
        local Window = {
            Instance = Utils:FindFirstChild(script, "EmoteEquipWindow"):Clone(),
            Connections = {},
            Equipped = Signal.new(),
            Removed = Signal.new(),
            Buttons = {},
        }

        Window.Instance.Parent = Parent

        function Window:Show()
            TweenService:Create(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.855, 0.962)}):Play()
        end

        function Window:Hide(instant: boolean?)
            if instant == nil then
                instant = false
            end

            self.Removed:Fire()
            self.Removed:DisconnectAll()
            self.Equipped:DisconnectAll()

            for _, i in self.Connections do
                if typeof(i) == "thread" then
                    if coroutine.status(i) ~= "running" then
                        task.cancel(i)
                    end
                else
                    i:Disconnect()
                end
            end

            if not instant then
                TweenService:Create(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
            else
                self.Instance.Size = Utils.UDim.Zero
            end

            Debris:AddItem(self.Instance, 0.5)
        end

        local EmotesToInstantiate = {}
        for _, i in Utils:GetPlayerOwned(Players.LocalPlayer, "Emotes", false):GetChildren() do
            table.insert(EmotesToInstantiate, i.Name)
        end
        table.sort(EmotesToInstantiate, function(a, b)
            return a < b
        end)

        for _, i in EmotesToInstantiate do
            local EmoteInfo = require(Utils:GetEmoteModule(i))

            local Button = ButtonPrefab:Clone()
            Button.Name = i
            Button.Render.Image = EmoteInfo.Config.Render
            Button.NameLabel.Text = EmoteInfo.Config.Name

            table.insert(Window.Buttons, Button)
            Button.Parent = Window.Instance.Content
        end
        
        for _, i in Window.Buttons do
            table.insert(Window.Connections, i.MouseButton1Click:Connect(function()
                Window.Equipped:Fire(Network:FireServerConnection("EquipEmote", "REMOTE_FUNCTION", Slot, i.Name))
                Window:Hide()
            end))
        end

        table.insert(Window.Connections, Window.Instance.Cancel.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end))
        table.insert(Window.Connections, Window.Instance.Cancel.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end))
        table.insert(Window.Connections, Window.Instance.Cancel.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            Window:Hide()
        end))
        
        table.insert(Window.Connections, Window.Instance.Unequip.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end))
        table.insert(Window.Connections, Window.Instance.Unequip.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end))
        table.insert(Window.Connections, Window.Instance.Unequip.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            Window.Equipped:Fire(Network:FireServerConnection("EquipEmote", "REMOTE_FUNCTION", Slot, ""))
            Window:Hide()
        end))

        Window:Show()

        return Window
    end,
}
