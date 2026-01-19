local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer
local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local RoundPlayerList = {
    UI = nil,
    Conns = {},
}

local TemplateFolder = Utils.Instance.FindFirstChild(script, "Templates")
local Prefabs = {
    UI = Utils.Instance.FindFirstChild(script, "RoundPlayerListUI"),
    Card = Utils.Instance.FindFirstChild(TemplateFolder, "Card"),
}
local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "RoundPlayerList")

function RoundPlayerList:Init()
    Utils.Character.ObserveCharacter(LocalPlayer, function(Char: Model)
        if RoundPlayerList.UI then
            RoundPlayerList.UI:Destroy()
        end
        for _, ConnectionList in RoundPlayerList.Conns do
            for _, Connection in ConnectionList do
                Connection:Disconnect()
            end
        end
        RoundPlayerList.Conns = {}
        RoundPlayerList._InitUI(Char)
    end)
end

function RoundPlayerList._InitUI(Char: Model)
    if Char:FindFirstChild("Role").Value == "Spectator" then
        return
    end

    local UI = Prefabs.UI:Clone()
    RoundPlayerList.UI = UI

    while RoundState.Value ~= "InRound" do
        task.wait()
    end

    local Conns: {[string]: RBXScriptConnection} = {}

    for _, Character in workspace.Players:GetChildren() do
        if not Character:FindFirstChild("Role") or Character.Role.Value ~= "Survivor" then
            continue
        end

        local Card = Prefabs.Card:Clone()
        Card.Name = Character.Name

        --should show the skin portrait if equipped
        Card.Portrait.Image = require(Utils.Instance.GetCharacterModule("Survivor", Character:GetAttribute("CharacterName"), Character:GetAttribute("CharacterSkinName"))).Config.Render
        --should show the root character's name without caring about the skin
        Card.CharacterName.Text = require(Utils.Instance.GetCharacterModule("Survivor", Character:GetAttribute("CharacterName"))).Config.Name

        local Humanoid: Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

        if Character == LocalPlayer.Character then
            Card.PlayerHealth.TextTransparency = 1
            Card.CharacterName.TextColor3 = Color3.fromRGB(255, 255, 127)
            Card.PortraitOutline.ImageColor3 = Color3.fromRGB(255, 255, 127)
            Card.PlayerName.Text = Character.Name.." (You)"
        else
            Card.PlayerName.Text = Character.Name

            local PlayerConns = {}

            local function HealthUpdate(Health)
                --stop checking when they die
                if Humanoid.Health <= 0 and Card then
                    Card.Portrait.ImageColor3 = Color3.fromRGB(161, 0, 0)
                    Card.PortraitOutline.ImageColor3 = Color3.fromRGB(255, 0, 0)

                    Card.PlayerState.TextColor3 = Color3.fromRGB(255, 0, 0)
                    Card.PlayerState.Text = "DEAD"
                    Card.PlayerState.TextTransparency = 1

                    Card.PlayerHealth.TextTransparency = 1

                    for _, Connection in PlayerConns do
                        Connection:Disconnect()
                    end
                    return
                end

                local HealthPercentageMagnitude = Humanoid.Health / Humanoid.MaxHealth
                Card.PlayerHealth.TextColor3 = Color3.fromRGB(
                    Utils.Math.MapToRange(HealthPercentageMagnitude, 0, 1, 1, 0) * 180 + 75,
                    HealthPercentageMagnitude * 180 + 75,
                    75
                )
                Card.PlayerHealth.Text = tostring(HealthPercentageMagnitude * 100).."%"
            end

            table.insert(PlayerConns, Humanoid.HealthChanged:Connect(HealthUpdate))
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

            HealthUpdate(Humanoid.Health)

            Conns[Character.Name] = PlayerConns
        end

        Card.Parent = UI
    end

    RoundPlayerList.Conns = Conns
    UI.Parent = UIParent
end

return RoundPlayerList
