--!strict
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local FONT = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold)
local CHECK_KEYS = { [Enum.KeyCode.C] = true, [Enum.KeyCode.ButtonX] = true }

local function frame(parent: Instance, size: UDim2, position: UDim2, color: Color3): Frame
    local new = Instance.new("Frame")
    new.Size = size
    new.Position = position
    new.BackgroundColor3 = color
    new.BorderSizePixel = 0
    new.Parent = parent
    return new
end

local function label(parent: Instance, size: UDim2, position: UDim2, text: string): TextLabel
    local new = Instance.new("TextLabel")
    new.Size = size
    new.Position = position
    new.AnchorPoint = Vector2.new(0.5, 0)
    new.BackgroundTransparency = 1
    new.FontFace = FONT
    new.TextScaled = true
    new.TextColor3 = Color3.new(1, 1, 1)
    new.TextStrokeTransparency = 0.4
    new.Text = text
    new.Parent = parent
    return new
end

return {
    Init = function(_)
        local gui = Instance.new("ScreenGui")
        gui.Name = "Generators"
        gui.ResetOnSpawn = false
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

        local counter = label(gui, UDim2.new(0.16, 0, 0.035, 0), UDim2.new(0.5, 0, 0.1, 4), "")
        local function updateCounter()
            local total = workspace:GetAttribute("GeneratorsTotal") or 0
            counter.Text = `Generators {workspace:GetAttribute("GeneratorsRepaired") or 0}/{total}`
            counter.Visible = RoundState.Value == "InRound" and total > 0
        end
        workspace:GetAttributeChangedSignal("GeneratorsRepaired"):Connect(updateCounter)
        workspace:GetAttributeChangedSignal("GeneratorsTotal"):Connect(updateCounter)
        RoundState.Changed:Connect(updateCounter)
        updateCounter()

        local bar = frame(gui, UDim2.new(0.28, 0, 0, 16), UDim2.new(0.5, 0, 0.74, 0), Color3.fromRGB(20, 22, 26))
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Visible = false
        Instance.new("UICorner").Parent = bar
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(200, 200, 210)
        stroke.Parent = bar
        local zone = frame(bar, UDim2.new(), UDim2.new(), Color3.fromRGB(70, 230, 110))
        local needle = frame(bar, UDim2.new(0, 3, 1.6, 0), UDim2.new(), Color3.new(1, 1, 1))
        needle.AnchorPoint = Vector2.new(0.5, 0.5)
        local hint = label(bar, UDim2.new(1, 0, 1.4, 0), UDim2.new(0.5, 0, -2, 0), "")

        local tapButton = Instance.new("TextButton")
        tapButton.Size = UDim2.new(0, 96, 0, 96)
        tapButton.Position = UDim2.new(0.82, 0, 0.6, 0)
        tapButton.AnchorPoint = Vector2.new(0.5, 0.5)
        tapButton.BackgroundColor3 = Color3.fromRGB(70, 230, 110)
        tapButton.BackgroundTransparency = 0.3
        tapButton.FontFace = FONT
        tapButton.TextScaled = true
        tapButton.Text = "REPAIR"
        tapButton.Visible = false
        tapButton.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = tapButton

        local check: { startsAt: number, sweep: number }? = nil
        local repairing = false
        local renderConnection: RBXScriptConnection? = nil

        local function stopRender()
            if renderConnection then
                renderConnection:Disconnect()
                renderConnection = nil
            end
        end

        local function press()
            if not check then
                return
            end
            check = nil
            stopRender()
            Network:FireServerConnection("GeneratorCheckInput", "REMOTE_EVENT")
        end

        Network:SetConnection("GeneratorCheck", "REMOTE_EVENT", function(delay: number, sweep: number, zoneStart: number, width: number)
            if repairing then
                Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, { PlaybackSpeed = 1.3 })
            end
            repairing = true
            ProximityPromptService.Enabled = false
            local touch = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
            local gamepad = UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
            hint.Text = if touch then "Tap REPAIR in the green zone" elseif gamepad then "Press X in the green zone" else "Press C in the green zone"
            tapButton.Visible = touch
            zone.Position = UDim2.new(zoneStart, 0, 0, 0)
            zone.Size = UDim2.new(width, 0, 1, 0)
            needle.Position = UDim2.new(0, 0, 0.5, 0)
            bar.Visible = true
            local current = { startsAt = os.clock() + delay, sweep = sweep }
            check = current
            stopRender()
            renderConnection = RunService.RenderStepped:Connect(function()
                needle.Position = UDim2.new(math.clamp((os.clock() - current.startsAt) / current.sweep, 0, 1), 0, 0.5, 0)
            end)
        end)

        Network:SetConnection("GeneratorCheckEnded", "REMOTE_EVENT", function()
            check = nil
            repairing = false
            stopRender()
            bar.Visible = false
            tapButton.Visible = false
            ProximityPromptService.Enabled = true
        end)

        Network:SetConnection("GeneratorRepaired", "REMOTE_EVENT", function(removed: number)
            Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, { PlaybackSpeed = 0.6, Volume = 2 })
            if removed <= 0 then
                return
            end
            local popup = label(gui, UDim2.new(0.1, 0, 0.04, 0), UDim2.new(0.5, 0, 0.14, 4), `-{removed} s`)
            popup.TextColor3 = Color3.fromRGB(110, 240, 140)
            TweenService:Create(popup, TweenInfo.new(1.6), { Position = UDim2.new(0.5, 0, 0.11, 4), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
            Debris:AddItem(popup, 1.7)
        end)

        Network:SetConnection("GeneratorAlert", "REMOTE_EVENT", function(generator: Model)
            local highlight = Instance.new("Highlight")
            highlight.FillTransparency = 1
            highlight.OutlineColor = Color3.fromRGB(255, 60, 40)
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = generator
            Debris:AddItem(highlight, 2.5)
        end)

        tapButton.Activated:Connect(press)
        UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
            if not gameProcessed and CHECK_KEYS[input.KeyCode] then
                press()
            end
        end)
    end,
}
