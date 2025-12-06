local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Signal = require(ReplicatedStorage.Utils.Signal)

--TODO: add displayed achievements of choice
return {
    New = function(Player: Player, Parent: ScreenGui)
        local Window = {
            PlayerShown = Player,
            Instance = Utils.Instance.FindFirstChild(script, "PlayerInfoWindow"):Clone(),
            Connections = {},
            Removed = Signal.new(),
        }
        Window.Instance.Size = Utils.UDim.Zero

        --user portrait
        task.spawn(function()
            Window.Instance.Portrait.PortraitLabel.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size352x352)
        end)

        --time played
        task.spawn(function()
            local HiddenTime = Utils.Instance.FindFirstChild(Player, "PlayerData.Settings.Privacy.HidePlaytime")
            local TimePlayed = Utils.PlayerData.GetPlayerStat(Player, "General.TimePlayed", false)

            Window.Instance.TimePlayed.TimeLabel.Text = HiddenTime.Value and "(Hidden)" or Utils.Math.ConvertToDHMS(TimePlayed.Value)
            Window.Instance.TimePlayed.TimeLabel.TextColor3 = HiddenTime.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)

            table.insert(Window.Connections, TimePlayed.Changed:Connect(function(value: number)
                Window.Instance.TimePlayed.TimeLabel.Text = HiddenTime.Value and "(Hidden)" or Utils.Math.ConvertToDHMS(value)
                Window.Instance.TimePlayed.TimeLabel.TextColor3 = HiddenTime.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
            end))

            table.insert(Window.Connections, HiddenTime.Changed:Connect(function(value: boolean)
                Window.Instance.TimePlayed.TimeLabel.Text = value and "(Hidden)" or Utils.Math.ConvertToDHMS(TimePlayed.Value)
                Window.Instance.TimePlayed.TimeLabel.TextColor3 = value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
            end))
        end)

        --surv wins
        task.spawn(function()
            local HiddenWins = Utils.Instance.FindFirstChild(Player, "PlayerData.Settings.Privacy.HideSurvivorWins")
            local SurvivorWins = Utils.PlayerData.GetPlayerStat(Player, "SurvivorStats.SurvivorWins", false)

            Window.Instance.Wins.Survivor.Amount.Text = HiddenWins.Value and "(Hidden)" or tostring(SurvivorWins.Value)
            Window.Instance.Wins.Survivor.Amount.TextColor3 = HiddenWins.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)

            table.insert(Window.Connections, SurvivorWins.Changed:Connect(function(value: number)
                Window.Instance.Wins.Survivor.Amount.Text = HiddenWins.Value and "(Hidden)" or tostring(value)
                Window.Instance.Wins.Survivor.Amount.TextColor3 = HiddenWins.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
            end))

            table.insert(Window.Connections, HiddenWins.Changed:Connect(function(value: boolean)
                Window.Instance.Wins.Survivor.Amount.Text = value and "(Hidden)" or tostring(SurvivorWins.Value)
                Window.Instance.Wins.Survivor.Amount.TextColor3 = value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
            end))
        end)
        --killer wins
        task.spawn(function()
            local HiddenWins = Utils.Instance.FindFirstChild(Player, "PlayerData.Settings.Privacy.HideKillerWins")
            local KillerWins = Utils.PlayerData.GetPlayerStat(Player, "KillerStats.KillerWins", false)

            Window.Instance.Wins.Killer.Amount.Text = HiddenWins.Value and "(Hidden)" or tostring(KillerWins.Value)
            Window.Instance.Wins.Killer.Amount.TextColor3 = HiddenWins.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)

            table.insert(Window.Connections, KillerWins.Changed:Connect(function(value: number)
                Window.Instance.Wins.Killer.Amount.Text = HiddenWins.Value and "(Hidden)" or tostring(value)
                Window.Instance.Wins.Killer.Amount.TextColor3 = HiddenWins.Value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
            end))

            table.insert(Window.Connections, HiddenWins.Changed:Connect(function(value: boolean)
                Window.Instance.Wins.Killer.Amount.Text = value and "(Hidden)" or tostring(KillerWins.Value)
                Window.Instance.Wins.Killer.Amount.TextColor3 = value and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(255, 255, 255)
            end))
        end)

        --equipped survivor
        task.spawn(function()
            local EquippedSurvivor = Utils.PlayerData.GetPlayerEquipped(Player, "Survivor", false)
            
            local LastSurvivor = ""

            local SkinConn

            local function Reload(Value: string)
                if LastSurvivor ~= Value then
                    if SkinConn then
                        SkinConn:Disconnect()
                    end
                    local SkinValue = Utils.PlayerData.GetPlayerEquipped(Player, "Skins."..Value, false)

                    local function ReloadSkin(Skin: string)
                        if #Skin <= 0 then
                            local Default = require(Utils.Instance.GetCharacterModule("Survivor", Value))

                            Window.Instance.CharactersUsing.Survivor.PortraitLabel.SkinLabel.Text = "Default"
                            Window.Instance.CharactersUsing.Survivor.PortraitLabel.PortraitImage.Image = Default.Config.Render

                            return
                        end

                        local SkinMod = require(Utils.Instance.GetCharacterModule("Survivor", Value, Skin))

                        Window.Instance.CharactersUsing.Survivor.PortraitLabel.SkinLabel.Text = SkinMod.Config.Name
                        Window.Instance.CharactersUsing.Survivor.PortraitLabel.PortraitImage.Image = SkinMod.Config.Render
                    end

                    SkinConn = SkinValue.Changed:Connect(ReloadSkin)
                    table.insert(Window.Connections, SkinConn)
                    ReloadSkin(SkinValue.Value)
                end

                Window.Instance.CharactersUsing.Survivor.NameLabel.Text = require(Utils.Instance.GetCharacterModule("Survivor", Value)).Config.Name
            end

            EquippedSurvivor.Changed:Connect(Reload)
            Reload(EquippedSurvivor.Value)
        end)
        --equipped killer
        task.spawn(function()
            local EquippedKiller = Utils.PlayerData.GetPlayerEquipped(Player, "Killer", false)
            
            local LastKiller = ""

            local SkinConn

            local function Reload(Value: string)
                if LastKiller ~= Value then
                    if SkinConn then
                        SkinConn:Disconnect()
                    end
                    local SkinValue = Utils.PlayerData.GetPlayerEquipped(Player, "Skins."..Value, false)

                    local function ReloadSkin(Skin: string)
                        if #Skin <= 0 then
                            local Default = require(Utils.Instance.GetCharacterModule("Killer", Value))

                            Window.Instance.CharactersUsing.Killer.PortraitLabel.SkinLabel.Text = "Default"
                            Window.Instance.CharactersUsing.Killer.PortraitLabel.PortraitImage.Image = Default.Config.Render

                            return
                        end

                        local SkinMod = require(Utils.Instance.GetCharacterModule("Killer", Value, Skin))

                        Window.Instance.CharactersUsing.Killer.PortraitLabel.SkinLabel.Text = SkinMod.Config.Name
                        Window.Instance.CharactersUsing.Killer.PortraitLabel.PortraitImage.Image = SkinMod.Config.Render
                    end

                    SkinConn = SkinValue.Changed:Connect(ReloadSkin)
                    table.insert(Window.Connections, SkinConn)
                    ReloadSkin(SkinValue.Value)
                end

                Window.Instance.CharactersUsing.Killer.NameLabel.Text = require(Utils.Instance.GetCharacterModule("Killer", Value)).Config.Name
            end

            EquippedKiller.Changed:Connect(Reload)
            Reload(EquippedKiller.Value)
        end)

        Window.Instance.NameContainer.PlayerName.Text = "@"..Player.Name
        Window.Instance.NameContainer.PlayerDisplayName.Text = Player.DisplayName

        Window.Instance.Parent = Parent

        function Window:Show()
            TweenService:Create(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.334, 0.463)}):Play()
        end

        function Window:Hide(instant: boolean?)
            if instant == nil then
                instant = false
            end

            self.Removed:Fire()
            self.Removed:DisconnectAll()

            for _, connection in self.Connections do
                if typeof(connection) == "thread" then
                    if coroutine.status(connection) ~= "running" then
                        task.cancel(connection)
                    end
                else
                    connection:Disconnect()
                end
            end

            if not instant then
                TweenService:Create(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = Utils.UDim.Zero}):Play()
            else
                self.Instance.Size = Utils.UDim.Zero
            end

            Debris:AddItem(self.Instance, 0.5)
        end

        local HideButton = Utils.Instance.FindFirstChild(Window.Instance, "Hide")
        table.insert(Window.Connections, HideButton.MouseEnter:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHover, {Volume = 0.2})
        end))
        table.insert(Window.Connections, HideButton.MouseLeave:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonHoverStop, {Volume = 0.2})
        end))
        table.insert(Window.Connections, HideButton.MouseButton1Click:Connect(function()
            Sounds:PlaySound(Sounds.CommonlyUsedSounds.ButtonPress, {Volume = 0.8})
            Window:Hide()
        end))

        Window:Show()

        return Window
    end,
}