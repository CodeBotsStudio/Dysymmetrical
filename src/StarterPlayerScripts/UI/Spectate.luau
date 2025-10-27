local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local SideBar = require(script.Parent.SideBar)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local Spectate = {
    Opened = false,
    Enabled = true,
    UIInstance = nil,

    PlayersAvailable = {},
    --{[string]: {RBXScriptConnection}}
    PlayerConnections = {
        Name = {},
    },
    SelectedPlayer = {
        Name = "",
        Index = 0,
    },
}

local UIParent = Utils:FindFirstChild(LocalPlayer.PlayerGui, "Menus")

function Spectate:Init()
    if self.UIInstance then
        self.UIInstance.Visible = false
        return
    end

    self.PlayersAvailable = {}

    local UI = Utils:FindFirstChild(script, "SpectateUI")
    UI.Visible = false
    UI.Parent = UIParent
    self.UIInstance = UI

    UI.Buttons.Left.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    UI.Buttons.Right.MouseEnter:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
    end)
    UI.Buttons.Left.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)
    UI.Buttons.Right.MouseLeave:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
    end)

    UI.Buttons.Left.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        self:ChangeSelection(-1)
    end)
    UI.Buttons.Right.MouseButton1Click:Connect(function()
        Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
        self:ChangeSelection(1)
    end)

    self:ReloadPlayers()
    self:ChangeSelection()
end

function Spectate:Open()
    if not self.Enabled or not SideBar.Enabled then
        return
    end

    self.Opened = true
    self.UIInstance.Visible = true
    self:ReloadPlayers()
    self:ChangeSelection()
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

function Spectate:ReloadPlayers()
    local PlayersInTable = {}
    for _, i in workspace.Players:GetChildren() do
        local Role = Utils:FindFirstChild(i, "Role")
        Role = Role and Role.Value or "Spectator"

        if Role ~= "Spectator" then
            local Hum = Utils:FindFirstChild(i, "Humanoid")
            
            local Conns = {}

            table.insert(Conns, Hum.Died:Connect(function()
                task.wait(3)

                local Ind = table.find(self.PlayersAvailable, i.Name)
                if not Ind then
                    return
                end

                self.PlayersAvailable[i.Name] = nil
                table.remove(self.PlayersAvailable, Ind)
                if self.SelectedPlayer.Index == Ind then
                    self:ChangeSelection()
                end
            end))

            table.insert(Conns, Hum:GetPropertyChangedSignal("Health"):Connect(function()
                if self.SelectedPlayer == i.Name then
                    local Magnitude = Hum.Health / Hum.MaxHealth
                    self.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(
                        Utils:MapToRange(Magnitude, 0, 1, 1, 0) * 180 + 75,
                        Magnitude * 180 + 75,
                        75
                    )
                    self.UIInstance.PlayerText.Health.Text = tostring(Magnitude * 100).."%"
                end
            end))
            
            table.insert(Conns, Players:GetPlayerFromCharacter(i).CharacterAdded:Connect(function()
                for _, i in Conns do
                    i:Disconnect()
                end
            end))

            PlayersInTable[i.Name] = Conns
        end
    end

    self.PlayersAvailable = PlayersInTable
end

function Spectate:ChangeSelection(amount: number?)
    amount = amount or 0

    if #self.PlayersAvailable <= 0 then
        self.UIInstance.PlayerText.Username.Text = "Username"
        self.UIInstance.PlayerText.DisplayName.Text = "Player Name"
        self.UIInstance.PlayerText.CharacterName.Text = "Character"
        self.UIInstance.PlayerText.Health.Text = "100%"
        self.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(75, 255, 75)

        return
    end

    self.SelectedPlayer.Index = Utils:WrapNum(self.SelectedPlayer.Index + amount, 1, #self.PlayersAvailable)

    if self.PlayersAvailable[self.SelectedPlayer.Index] and workspace.Players:FindFirstChild(self.PlayersAvailable[self.SelectedPlayer.Index]) then

        self.SelectedPlayer.Name = self.PlayersAvailable[self.SelectedPlayer.Index]

        local Char = workspace.Players[self.SelectedPlayer.Name]

        self.UIInstance.PlayerText.DisplayName.Text = Players:GetPlayerFromCharacter(Char).DisplayName
        self.UIInstance.PlayerText.Username.Text = self.SelectedPlayer.Name

        self.UIInstance.PlayerText.CharacterName.Text = Char:GetAttribute("CharacterName")

        if Char:GetAttribute("CharacterSkinName") then
            self.UIInstance.PlayerText.CharacterName.Text = self.UIInstance.PlayerText.CharacterName.Text.." ("..Char:GetAttribute("CharacterSkinName")..")"
        end

        local Hum = Utils:FindFirstChild(Char, "Humanoid")
        local Mag = Hum.Health / Hum.MaxHealth
        self.UIInstance.PlayerText.Health.Text = tostring(Mag * 100).."%"
        self.UIInstance.PlayerText.Health.TextColor3 = Color3.fromRGB(
            Utils:MapToRange(Mag, 0, 1, 1, 0) * 180 + 75,
            Mag * 180 + 75,
            75
        )

        if self.Opened then
            workspace.CurrentCamera.CameraSubject = workspace.Players[self.SelectedPlayer.Name]:FindFirstChild("Humanoid")
        end
    else
        --making a fallback for amount so that selene stops fucking crying
        self:ChangeSelection(1 * (amount or 1))
    end
end

return Spectate
