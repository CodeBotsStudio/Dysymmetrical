--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer
local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local GUIDED_ROUNDS = 3
local TIP_TIME = 5

local function keys(): { repair: string, sprint: string }
    local input = UserInputService:GetLastInputType()
    if input == Enum.UserInputType.Touch then
        return { repair = "tap REPAIR", sprint = "tap the sprint button" }
    elseif input.Name:find("Gamepad") then
        return { repair = "press X", sprint = "hold L2" }
    end
    return { repair = "press C", sprint = "hold Shift" }
end

local function tipsFor(role: string): { string }
    local k = keys()
    if role == "Killer" then
        return {
            "Hunt the survivors before the clock runs out. Every kill adds time.",
            "A loud bang means a survivor failed a repair: that generator glows red for you.",
        }
    end
    return {
        `Repair generators: {k.repair} when the needle is in the green zone. Each one cuts 15 s off the clock.`,
        `Run from the killer: {k.sprint}. Repair together to get a wider green zone.`,
        "Survive until the clock hits zero. Medkits heal you.",
    }
end

return {
    Init = function(_)
        local gui = Instance.new("ScreenGui")
        gui.Name = "RoundTips"
        gui.ResetOnSpawn = false
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local label = Instance.new("TextLabel")
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.Position = UDim2.fromScale(0.5, 0.64)
        label.Size = UDim2.fromScale(0.8, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        local maxWidth = Instance.new("UISizeConstraint")
        maxWidth.MaxSize = Vector2.new(620, math.huge)
        maxWidth.Parent = label
        label.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        label.BackgroundTransparency = 1
        label.TextTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.FontFace = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold)
        label.TextSize = 18
        label.TextWrapped = true
        label.Parent = gui
        Instance.new("UICorner").Parent = label
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 4)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.Parent = label

        local queue: { string } = {}
        local showing = false
        local function show(texts: { string })
            for _, text in texts do
                table.insert(queue, text)
            end
            if showing then
                return
            end
            showing = true
            task.spawn(function()
                while #queue > 0 do
                    label.Text = table.remove(queue, 1) :: string
                    TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0, BackgroundTransparency = 0.35 }):Play()
                    task.wait(TIP_TIME)
                    TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
                    task.wait(0.4)
                end
                showing = false
            end)
        end

        local function currentRole(): string?
            local character = LocalPlayer.Character
            local role = character and character:FindFirstChild("Role") :: StringValue?
            return role and role.Value
        end

        local roundsGuided = 0
        RoundState.Changed:Connect(function(state: string)
            if state ~= "InRound" or roundsGuided >= GUIDED_ROUNDS then
                return
            end
            task.wait(1)
            local role = currentRole()
            if role == "Survivor" or role == "Killer" then
                roundsGuided += 1
                show(tipsFor(role))
            end
        end)

        Utils.Character.ObserveCharacter(LocalPlayer, function(character: Model)
            local role = character:WaitForChild("Role", 5) :: StringValue?
            if role and role.Value == "Spectator" and RoundState.Value == "InRound" then
                show({ "You're out. Spectate the others: the next round starts soon." })
            end
        end)
    end,
}
