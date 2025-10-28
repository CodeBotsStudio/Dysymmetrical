--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer
local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local RoundPlayerList = {
    UI = nil,
    Conns = {},
}

local TemplateFolder = Utils:FindFirstChild(script, "Templates")
local Prefabs = {
    UI = Utils:FindFirstChild(script, "RoundPlayerListUI"),
    Card = Utils:FindFirstChild(TemplateFolder, "Card"),
}
local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "RoundPlayerList")

function RoundPlayerList:Init()
    LocalPlayer.CharacterAdded:Connect(function(Char: Model)
        if self.UI then
            self.UI:Destroy()
        end
        for _, i in self.Conns do
            for _, v in i do
                v:Disconnect()
            end
        end
        self.Conns = {}
        self:_InitUI(Char)
    end)
end

function RoundPlayerList:_InitUI(Char: Model)
    if Utils:FindFirstChild(Char, "Role").Value == "Spectator" then
        return
    end

    local UI = Prefabs.UI:Clone()
    self.UI = UI

    if RoundState.Value ~= "InRound" then
        repeat task.wait()
        until RoundState.Value == "InRound"
    end

    local Conns: {[string]: RBXScriptConnection} = {}

    for _, Character in workspace.Players:GetChildren() do
        if not Utils:FindFirstChild(Character, "Role") or Character.Role.Value ~= "Survivor" then
            continue
        end

        local Card = Prefabs.Card:Clone()
        Card.Name = Character.Name

        --should show the skin portrait if equipped
        Card.Portrait.Image = require(Utils:GetCharacterModule("Survivor", Character:GetAttribute("CharacterName"), Character:GetAttribute("CharacterSkinName"))).Config.Render
        --should show the root character's name without caring about the skin
        Card.CharacterName.Text = require(Utils:GetCharacterModule("Survivor", Character:GetAttribute("CharacterName"))).Config.Name

        local Humanoid = Utils:FindFirstChild(Character, "Humanoid")

        if Character == LocalPlayer.Character then
            Card.PlayerHealth.TextTransparency = 1
            Card.CharacterName.TextColor3 = Color3.fromRGB(255, 255, 127)
            Card.PortraitOutline.ImageColor3 = Color3.fromRGB(255, 255, 127)
            Card.PlayerName.Text = Character.Name.." (You)"
        else
            Card.PlayerName.Text = Character.Name

            local PlayerConns = {}
            table.insert(PlayerConns, RunService.PreRender:Connect(function(_delta: number)
                --stop checking when they die
                if Humanoid.Health <= 0 and Card then
                    Card.Portrait.ImageColor3 = Color3.fromRGB(161, 0, 0)
                    Card.PortraitOutline.ImageColor3 = Color3.fromRGB(255, 0, 0)

                    Card.PlayerState.TextColor3 = Color3.fromRGB(255, 0, 0)
                    Card.PlayerState.Text = "DEAD"
                    Card.PlayerState.TextTransparency = 1

                    Card.PlayerHealth.TextTransparency = 1

                    for _, i in PlayerConns do
                        i:Disconnect()
                    end
                    return
                end

                local HealthPercentageMagnitude = Humanoid.Health / Humanoid.MaxHealth
                Card.PlayerHealth.TextColor3 = Color3.fromRGB(
                    Utils:MapToRange(HealthPercentageMagnitude, 0, 1, 1, 0) * 180 + 75,
                    HealthPercentageMagnitude * 180 + 75,
                    75
                )
                Card.PlayerHealth.Text = tostring(HealthPercentageMagnitude * 100).."%"
            end))
            table.insert(PlayerConns, Players.PlayerRemoving:Connect(function(Player: Player)
                if not Character then
                    return
                end

                --stop checking when they leave and are still alive
                if Player.Name == Character.Name then
                    for _, c in PlayerConns do
                        c:Disconnect()
                    end

                    Card.Portrait.ImageColor3 = Color3.fromRGB(200, 200, 200)
                    Card.PortraitOutline.ImageColor3 = Color3.fromRGB(150, 150, 150)

                    Card.PlayerState.TextColor3 = Color3.fromRGB(170, 170, 170)
                    Card.PlayerState.Text = "LOST"
                    Card.PlayerState.TextTransparency = 0

                    Card.PlayerHealth.TextTransparency = 1
                end
            end))

            Conns[Character.Name] = PlayerConns
        end

        Card.Parent = UI
    end

    self.Conns = Conns
    UI.Parent = UIParent
end

return RoundPlayerList
