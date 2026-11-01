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
        return { repair = "toca REPARAR", sprint = "toca el botón de correr" }
    elseif input.Name:find("Gamepad") then
        return { repair = "pulsa X", sprint = "mantén L2" }
    end
    return { repair = "pulsa C", sprint = "mantén Shift" }
end

local function tipsFor(role: string): { string }
    local k = keys()
    if role == "Killer" then
        return {
            "Caza a los supervivientes antes de que se acabe el reloj. Cada muerte suma tiempo.",
            "Un estallido fuerte significa que un superviviente falló una reparación: ese generador se ilumina en rojo para ti.",
        }
    end
    return {
        `Repara generadores: {k.repair} cuando la aguja esté en la zona verde. Cada uno quita 15 s al reloj.`,
        `Huye del asesino: {k.sprint}. Reparando juntos la zona verde es más ancha.`,
        "Sobrevive hasta que el reloj llegue a cero. Los botiquines te curan.",
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
                show({ "Has caído. Mira a los demás: la siguiente ronda empieza pronto." })
            end
        end)
    end,
}
