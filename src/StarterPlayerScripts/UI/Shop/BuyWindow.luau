local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Signal = require(ReplicatedStorage.Utils.Signal)

return {
    New = function(Shop, Module: ModuleScript, skin: boolean?, Parent: Frame, Card)
        local Window = {
            Checking = false,
            Instance = Utils:FindFirstChild(script, "Window"):Clone(),
            Connections = {},
            Removed = Signal.new(),
            Purchased = Signal.new(),
        }

        if skin == nil then
            skin = false
        end

        local CharInfo = require(Module)

        Window.Instance.PriceTag.Text = "Purchase "..CharInfo.Config.Name.." for "..(CharInfo.Config.Price > 0 and CharInfo.Config.Price.."$" or "FREE").."?"
        Window.Instance.Parent = Parent
        Window.Instance.Size = Utils.UDim.Zero

        function Window:Show()
            TweenService:Create(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.253, 0.202)}):Play()
        end

        function Window:Hide(instant: boolean?)
            if instant == nil then
                instant = false
            end

            self.Removed:Fire()
            self.Removed:DisconnectAll()
            self.Purchased:DisconnectAll()

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

        table.insert(Window.Connections, Window.Instance.Buy.Button.MouseButton1Click:Connect(function()
            if Window.Checking then
                return
            end

            Window.Checking = true
            Window.Instance.Buy.TextLabel.Text = "..."
            local Success = Network:FireServerConnection("BuyItem", "REMOTE_FUNCTION", Module)

            if Success then
                Window.Instance.Buy.TextLabel.Text = "Purchased!"
                Card.Container.Owned.BackgroundTransparency = 0.55
                Card.Container.Owned.TextLabel.TextTransparency = 0

                Window.Purchased:Fire()

                table.insert(Window.Connections, task.delay(0.75, function()
                    Window:Hide()
                end))
            else
                Window.Instance.Buy.TextLabel.Text = "you're too poor."
                Window.Checking = false
            end
        end))
        table.insert(Window.Connections, Window.Instance.Cancel.Button.MouseButton1Click:Connect(function()
            if Window.Checking then
                return
            end

            Window:Hide()
        end))

        Window:Show()

        return Window
    end,
}
