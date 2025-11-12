local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)

--- Class used to create mouse tooltips.
--- Only one can be created at a time and this class should only be used internally / in the `More Info` section for characters.
local TooltipClass = {}

local Tooltip = nil
local Prefab = Utils:FindFirstChild(script, "Tooltip")
local UI = Utils:FindFirstChild(Players.LocalPlayer.PlayerGui, "Menus")

--- Creates a new Tooltip.
--- If there's an existing one, it'll just change the text if it's different.
--- If `Text` is `nil`, it'll hide the existing tooltip and destroy it.
function TooltipClass.New(Text: string)
    if Tooltip and (not Text or #Text <= 0) and Tooltip.Parent then
        TweenService:Create(Tooltip.Title, TweenInfo.new(0.15), {
            TextSize = 0,
            TextTransparency = 1,
        }):Play()
        TweenService:Create(Tooltip.Background, TweenInfo.new(0.15), {
            Size = Utils.UDim.Zero,
            ImageTransparency = 1,
            BackgroundTransparency = 1,
        }):Play()
        Debris:AddItem(Tooltip, 0.15)
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})

        Tooltip = nil
        return
    end

    if not Text or #Text <= 0 then
        return
    end

    if Tooltip and Text and Text ~= Tooltip.Title.Text then
        Tooltip.Title.Text = Text
        return Tooltip
    end

    if not Tooltip then
        local InitialMousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
        Tooltip = Prefab:Clone()
        Tooltip.Title.Text = Text
        Tooltip.Title.Position = UDim2.fromOffset(InitialMousePos.X, InitialMousePos.Y - 30)
        Tooltip.Background.Position = UDim2.fromOffset(InitialMousePos.X, InitialMousePos.Y - 30 - Tooltip.Title.AbsoluteSize.Y + 40)
        Tooltip.Title.Size = UDim2.fromOffset(Tooltip.Title.AbsoluteSize.X + 64, Tooltip.Title.AbsoluteSize.Y + 50)
        Tooltip.Background.Size = UDim2.fromOffset(Tooltip.Title.AbsoluteSize.X + 64, Tooltip.Title.AbsoluteSize.Y + 50)
        Tooltip.Parent = UI
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        task.spawn(function()
            while task.wait() and Tooltip do
                local MousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
                Tooltip.Title.Position = UDim2.fromOffset(MousePos.X, MousePos.Y - 30)
                Tooltip.Background.Position = UDim2.fromOffset(MousePos.X, MousePos.Y - 30 - Tooltip.Title.AbsoluteSize.Y + 40)
                Tooltip.Background.Size = UDim2.fromOffset(Tooltip.Title.AbsoluteSize.X + 64, Tooltip.Title.AbsoluteSize.Y + 50)
            end
        end)

        return Tooltip
    end

    return Tooltip
end

return TooltipClass
