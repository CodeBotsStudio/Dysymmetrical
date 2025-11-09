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

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")
local ButtonTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

function Spectate:Init()
    if self.UIInstance then
        self.UIInstance.Visible = false
        return
    end

    local UI = Utils:FindFirstChild(script, "SpectateUI")
    UI.Visible = false
    UI.Parent = UIParent
    self.UIInstance = UI

    UI.Buttons.Left.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Left, ButtonTweenInfo, {Size = UDim2.fromScale(0.14, 0.44)}):Play()
    end)
    UI.Buttons.Right.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Right, ButtonTweenInfo, {Size = UDim2.fromScale(0.14, 0.44)}):Play()
    end)
    UI.Buttons.Left.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Left, ButtonTweenInfo, {Size = UDim2.fromScale(0.12, 0.377)}):Play()
    end)
    UI.Buttons.Right.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        TweenService:Create(UI.Buttons.Right, ButtonTweenInfo, {Size = UDim2.fromScale(0.12, 0.377)}):Play()
    end)

    UI.Buttons.Left.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        self:ChangeSelection(-1)
    end)
    UI.Buttons.Right.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        self:ChangeSelection(1)
    end)

    RunService.PreRender:Connect(function(_delta: number)
        self:_Update()
    end)

    local function OnPlayerAdded(Player: Player)
        local function OnCharacterAdded(Character: Model)
            local Role = Utils:FindFirstChild(Character, "Role")

            if Role.Value == "Spectator" then

                local I = table.find(self.PlayersAvailable, Player.Name)
                if I then

                    table.remove(self.PlayersAvailable, I)

                    if self.CurSelected <= I then
                        self:ChangeSelection(-1)
                    end

                end

            elseif not table.find(self.PlayersAvailable, Player.Name) then
                
                table.insert(self.PlayersAvailable, Player.Name)
                self:ChangeSelection()
            end
        end

        Player.CharacterAdded:Connect(OnCharacterAdded)
        if Player.Character then
            OnCharacterAdded(Player.Character)
        end
    end

    Players.PlayerAdded:Connect(OnPlayerAdded)
    for _, i in Players:GetPlayers() do
        if i ~= Players.LocalPlayer then
            OnPlayerAdded(i)
        end
    end

    self:ChangeSelection()
end

function Spectate:Open()
    if not self.Enabled or not SideBar.Enabled or RoundState.Value == "Lobby" then
        return "Prevented"
    end

    self.Opened = true
    self.UIInstance.Visible = true
    self:ChangeSelection()
    self:_Update()

    return
end

function Spectate:Close()
    self.Opened = false
    self.UIInstance.Visible = false
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end

function Spectate:Toggle(toggle: boolean)
    self:Close()
    self.Enabled = toggle
end

function Spectate:ChangeSelection(amount: number?)
    amount = amount or 0
    
    self.CurSelected = Utils:WrapNum(self.CurSelected + amount, 1, #self.PlayersAvailable)
    if #self.PlayersAvailable > 0 and not self.PlayersAvailable[self.CurSelected] then
        self:ChangeSelection(amount ~= 0 and amount or 1)
    end
end

function Spectate:_Update()
    if not self.UIInstance.Visible then
        return
    end

    if #self.PlayersAvailable <= 0 then
        self.UIInstance.PlayerText.DisplayName.Text = "PlayerDisplayName"
        self.UIInstance.PlayerText.Username.Text = "PlayerUsername"
        self.UIInstance.PlayerText.CharacterName.Text = "CharacterName (SkinName)"

        self.UIInstance.PlayerText.Health.Text = "100%"
        self.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(75, 255, 75)
        
        return
    end

    local Char = workspace.Players:FindFirstChild(self.PlayersAvailable[self.CurSelected])
    if not Char then
        return
    end

    local Role = Utils:FindFirstChild(Char, "Role")
    if Role.Value == "Spectator" then
        return
    end

    local Humanoid = Utils:FindFirstChild(Char, "Humanoid")
    workspace.CurrentCamera.CameraSubject = Humanoid

    self.UIInstance.PlayerText.DisplayName.Text = Players:GetPlayerFromCharacter(Char).DisplayName
    self.UIInstance.PlayerText.Username.Text = Char.Name

    local CharText = Char:GetAttribute("CharacterName")
    if Char:GetAttribute("CharacterSkinName") then
        CharText = CharText.." ("..Char:GetAttribute("CharacterSkinName")..")"
    end
    self.UIInstance.PlayerText.CharacterName.Text = CharText

    local HealthPercentageMagnitude = Humanoid.Health / Humanoid.MaxHealth
    self.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(
        Utils:MapToRange(HealthPercentageMagnitude, 0, 1, 1, 0) * 180 + 75,
        HealthPercentageMagnitude * 180 + 75,
        75
    )
    self.UIInstance.PlayerText.Health.Text = tostring(HealthPercentageMagnitude * 100).."%"
end

return Spectate
