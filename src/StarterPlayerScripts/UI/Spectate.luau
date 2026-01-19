local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local SideBar = require(script.Parent.SideBar)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer
local RoundState = ReplicatedStorage.RoundInfo.CurrentState

local Spectate = {
    Opened = false,
    Enabled = true,
    UIInstance = nil,

    PlayersAvailable = {},
    CurSelected = 1,
}

local UIParent = Utils.Instance.FindFirstChild(LocalPlayer.PlayerGui, "Menus")
local ButtonTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

function Spectate:Init()
    if Spectate.UIInstance then
        Spectate.UIInstance.Visible = false
        return
    end

    local UI = Utils.Instance.FindFirstChild(script, "SpectateUI")
    UI.Visible = false
    UI.Parent = UIParent
    Spectate.UIInstance = UI

    UI.Buttons.Left.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Left, ButtonTweenInfo, {Size = UDim2.fromScale(0.14, 0.44)}):Play()
    end)
    UI.Buttons.Right.MouseEnter:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Right, ButtonTweenInfo, {Size = UDim2.fromScale(0.14, 0.44)}):Play()
    end)
    UI.Buttons.Left.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Left, ButtonTweenInfo, {Size = UDim2.fromScale(0.12, 0.377)}):Play()
    end)
    UI.Buttons.Right.MouseLeave:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Right, ButtonTweenInfo, {Size = UDim2.fromScale(0.12, 0.377)}):Play()
    end)

    UI.Buttons.Left.MouseButton1Click:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        Spectate.ChangeSelection(-1)
    end)
    UI.Buttons.Right.MouseButton1Click:Connect(function()
        Sounds.PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        Spectate.ChangeSelection(1)
    end)

    RunService.PreRender:Connect(function(_delta: number)
        Spectate._Update()
    end)

    local function OnCharacterAdded(Player: Player, Character: Model)
        local Role = Character:FindFirstChild("Role")

        if Role.Value == "Spectator" then

            local FoundPlayer = table.find(Spectate.PlayersAvailable, Player.Name)
            if FoundPlayer then

                table.remove(Spectate.PlayersAvailable, FoundPlayer)

                if Spectate.CurSelected <= FoundPlayer then
                    Spectate.ChangeSelection(-1)
                end

            end

        elseif not table.find(Spectate.PlayersAvailable, Player.Name) then
            
            table.insert(Spectate.PlayersAvailable, Player.Name)
            Spectate.ChangeSelection()
        end
    end

    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model)
            OnCharacterAdded(Player, Character)
        end)
    end)

    Spectate.ChangeSelection()
end

function Spectate.Open()
    if not Spectate.Enabled or not SideBar.Enabled or RoundState.Value == "Lobby" then
        return "Prevented"
    end

    Spectate.Opened = true
    Spectate.UIInstance.Visible = true
    Spectate.ChangeSelection()
    Spectate._Update()

    return
end

function Spectate.Close()
    Spectate.Opened = false
    Spectate.UIInstance.Visible = false
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end

function Spectate.Toggle(toggle: boolean)
    Spectate:Close()
    Spectate.Enabled = toggle
end

function Spectate.ChangeSelection(amount: number?)
    amount = amount or 0
    
    Spectate.CurSelected = Utils.Math.WrapNum(Spectate.CurSelected + amount, 1, #Spectate.PlayersAvailable)
    if #Spectate.PlayersAvailable > 0 and not Spectate.PlayersAvailable[Spectate.CurSelected] then
        Spectate.ChangeSelection(amount ~= 0 and amount or 1)
    end
end

function Spectate._Update()
    if not Spectate.UIInstance.Visible then
        return
    end

    if #Spectate.PlayersAvailable <= 0 then
        Spectate.UIInstance.PlayerText.DisplayName.Text = "PlayerDisplayName"
        Spectate.UIInstance.PlayerText.Username.Text = "PlayerUsername"
        Spectate.UIInstance.PlayerText.CharacterName.Text = "CharacterName (SkinName)"

        Spectate.UIInstance.PlayerText.Health.Text = "100%"
        Spectate.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(75, 255, 75)
        
        return
    end

    local Char = workspace.Players:FindFirstChild(Spectate.PlayersAvailable[Spectate.CurSelected])
    if not Char then
        return
    end

    local Role = Char:FindFirstChild("Role")
    if Role.Value == "Spectator" then
        return
    end

    local Humanoid = Char:FindFirstChildWhichIsA("Humanoid")
    workspace.CurrentCamera.CameraSubject = Humanoid

    Spectate.UIInstance.PlayerText.DisplayName.Text = Players:GetPlayerFromCharacter(Char).DisplayName
    Spectate.UIInstance.PlayerText.Username.Text = Char.Name

    local CharText = Char:GetAttribute("CharacterName")
    if Char:GetAttribute("CharacterSkinName") then
        CharText = CharText.." ("..Char:GetAttribute("CharacterSkinName")..")"
    end
    Spectate.UIInstance.PlayerText.CharacterName.Text = CharText

    local HealthPercentageMagnitude = Humanoid.Health / Humanoid.MaxHealth
    Spectate.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(
        Utils.Math.MapToRange(HealthPercentageMagnitude, 0, 1, 1, 0) * 180 + 75,
        HealthPercentageMagnitude * 180 + 75,
        75
    )
    Spectate.UIInstance.PlayerText.Health.Text = tostring(HealthPercentageMagnitude * 100).."%"
end

return Spectate
