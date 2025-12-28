--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local LocalPlayer = Players.LocalPlayer
local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local Radiuses = {
	["L4Upcoming"] = -1e10, ["L4"] = 15,
	["L3Upcoming"] = 15, ["L3"] = 30,
	["L2Upcoming"] = 30, ["L2"] = 45,
	["L1Upcoming"] = 45, ["L1"] = 60,
}

local TerrorRadiusManager = {
    AbleToInit = true,
    LayerMagnitudes = {},
    InChase = false,
    Playing = false,
    ThemeFolder = nil,
    LocalPlayerProps = {
        Role = "",
        Char = nil,
        Humanoid = nil,
        HRP = nil,
    },
    MapAmbience = nil,
    MapAmbienceVolume = 0,
    MapAmbienceTweenState = "Play",
    Janitor = nil,
}

local function CalculateSound(Distance)
	return 4.96 / (Distance + 10.26)
end

function TerrorRadiusManager:Init()
    local ThemeFolder = SoundService:FindFirstChild("ChaseThemes")
    if ThemeFolder then
        ThemeFolder:Destroy()
    end

    if not self.AbleToInit then
        return
    end
    local Char = LocalPlayer.Character
    local Role = Char:FindFirstChild("Role").Value
    if Role == "Spectator" then
        return
    end
    local Humanoid = Char:FindFirstChildWhichIsA("Humanoid")
    self.LocalPlayerProps = {
        Role = Role,
        Char = Char,
        Humanoid = Humanoid,
        HRP = Char:FindFirstChild("HumanoidRootPart") or Humanoid.RootPart,
    }

    self.MapAmbience = workspace.Themes:FindFirstChild("MapAmbience")
    self.MapAmbienceVolume = self.MapAmbience and self.MapAmbience.Volume or 0

    ThemeFolder = Instance.new("Folder")
    ThemeFolder.Name = "ChaseThemes"
    ThemeFolder.Parent = SoundService
    self.ThemeFolder = ThemeFolder

    while RoundState.Value ~= "InRound" do
        task.wait()
    end

    for _, PlayerChar in workspace.Players:GetChildren() do
        if not PlayerChar:FindFirstChild("Role") or PlayerChar.Role.Value ~= "Killer" then
            continue
        end

        local PlayerLayerFolder = Instance.new("Folder")
        PlayerLayerFolder.Name = PlayerChar.Name
        PlayerLayerFolder.Parent = self.ThemeFolder

        local ChaseThemes = require(Utils.Instance.GetCharacterModule("Killer", PlayerChar:GetAttribute("CharacterName"), PlayerChar:GetAttribute("CharacterSkinName"))).Config.ChaseThemes
        for layerName, ID in ChaseThemes do
            local Sound = Instance.new("Sound")
            Sound.Name = layerName
            Sound.SoundId = ID
            Sound.Volume = 0
            Sound.Looped = true
            Sound.SoundGroup = SoundService.SoundGroups.Master.Music
            Sound.Parent = PlayerLayerFolder

	    	if not Sound.IsLoaded then
	    		Sound.Loaded:Wait()
	    	end

            self:SetLayerMagnitude(Sound, PlayerChar.Name, Radiuses[layerName])
        end
    end

    for _, Theme in self.ThemeFolder:GetDescendants() do
        if Theme:IsA("Sound") and Theme.Name ~= "L4" then
            Theme:Play()
        end
    end

    local TerrorRadiusJanitor = Janitor.new()

    --slow down on death fx
    TerrorRadiusJanitor:Add(self.LocalPlayerProps.Humanoid.Died:Connect(function()
        for _, s in self.ThemeFolder:GetDescendants() do
            if not s:IsA("Sound") then
                continue
            end
            TweenService:Create(s, TweenInfo.new(0.4), {PlaybackSpeed = 0}):Play()
        end
    end))

    TerrorRadiusJanitor:Add(RunService.PreRender:Connect(function(delta: number)
        self:CheckInRadius(delta)
    end))

    TerrorRadiusJanitor:Add(function()
        if self.ThemeFolder then
            self.ThemeFolder:Destroy()
        end
    end, true)

    TerrorRadiusJanitor:LinkToInstance(Char)

    self.Janitor = TerrorRadiusJanitor
end

function TerrorRadiusManager:SetLayerMagnitude(SoundInstance: Sound, Parent: string, Radius: number)
    if not self.LayerMagnitudes[Parent] then
        self.LayerMagnitudes[Parent] = {}
    end
    self.LayerMagnitudes[Parent][Radius] = SoundInstance
end

function TerrorRadiusManager:CheckInRadius(delta: number)
    if self.LocalPlayerProps.Role == "Survivor" then
        self:_CheckAsSurvivor(delta)
    elseif self.LocalPlayerProps.Role == "Killer" then
        self:_CheckAsKiller(delta)
    end
end

function TerrorRadiusManager:TweenVolume(Sound: Sound, TargetVolume: number, delta: number)
    if math.abs(Sound.Volume - TargetVolume) > 0.01 then
        Sound.Volume = Utils.Math.Lerp(Sound.Volume, TargetVolume, delta * 14)
    end
end

function TerrorRadiusManager:PlayLayer4(Subfolder: string, delta: number)
    if self.Playing then
        return
    end
    self.Playing = true

    for _, s: Sound in self.LayerMagnitudes[Subfolder] do
        if s.Name == "L4" then
            s:Play()
            self:TweenVolume(s, 0.5, delta)
            local conn
            conn = self.Janitor:Add(s.Changed:Connect(function()
                if s.Volume <= 0 then
                    conn:Disconnect()
                end
            end))
        else
            self:TweenVolume(s, 0, delta)
        end
    end
end

function TerrorRadiusManager:_CheckAsSurvivor(delta: number)
    local PlayersFound = {}
    for _, PlayerChar in workspace.Players:GetChildren() do
        if not self.ThemeFolder:FindFirstChild(PlayerChar.Name) and PlayerChar:FindFirstChild("Role") and PlayerChar.Role.Value == "Killer" then
            local PlayerThemeFolder = Instance.new("Folder")
            PlayerThemeFolder.Name = PlayerChar.Name
            PlayerThemeFolder.Parent = self.ThemeFolder

            local ChaseThemes = require(Utils:GetCharacterModule("Killer", PlayerChar:GetAttribute("CharacterName"), PlayerChar:GetAttribute("CharacterSkinName"))).Config.ChaseThemes
            for layerName, ID in ChaseThemes do
                local Sound = Instance.new("Sound")
                Sound.Name = layerName
                Sound.SoundId = ID
                Sound.Volume = 0
                Sound.Looped = true
                Sound.SoundGroup = SoundService.SoundGroups.Master.Music
                Sound.Parent = PlayerThemeFolder

	        	if not Sound.IsLoaded then
	        		Sound.Loaded:Wait()
	        	end

                self:SetLayerMagnitude(Sound, PlayerChar.Name, Radiuses[layerName])
            end
        end
        table.insert(PlayersFound, PlayerChar.Name)
    end
    for _, Theme in self.ThemeFolder:GetChildren() do
        if not table.find(PlayersFound, Theme.Name) then
            Theme:Destroy()
        end
    end

    local CurrentKillerChosen
    for _, s in self.ThemeFolder:GetDescendants() do
        if s:IsA("Sound") and s.Volume > 0 then
            CurrentKillerChosen = s.Parent.Name
            break
        end
    end
    if not CurrentKillerChosen then
        for _, PlayerChar in workspace.Players:GetChildren() do
            if not PlayerChar:FindFirstChild("Role") or PlayerChar.Role.Value ~= "Killer" then
                continue
            end

            local Distance = self.LocalPlayerProps.Humanoid and self.LocalPlayerProps.Humanoid.Health > 0 and (self.LocalPlayerProps.HRP.Position - PlayerChar:FindFirstChild("HumanoidRootPart").Position).Magnitude or 50000
            if Distance <= Radiuses["L1"] and (not CurrentKillerChosen or Distance <= CurrentKillerChosen.Distance) then
                CurrentKillerChosen = {
                    Player = PlayerChar,
                    Distance = Distance,
                }
            end
        end

        if not CurrentKillerChosen then
            return
        end
        CurrentKillerChosen = CurrentKillerChosen.Player
    else
        CurrentKillerChosen = workspace.Players:FindFirstChild(CurrentKillerChosen)
    end

    local KillerHRP = CurrentKillerChosen:FindFirstChild("HumanoidRootPart")

    local Distance = self.LocalPlayerProps.Humanoid and self.LocalPlayerProps.Humanoid.Health > 0 and (self.LocalPlayerProps.HRP.Position - KillerHRP.Position).Magnitude or 50000

    local Playing = false
    for Killer, Layers in self.LayerMagnitudes do
        if tostring(Killer) == tostring(CurrentKillerChosen) then
            local HasUndetectable = Utils.Instance.FindFirstChild(CurrentKillerChosen, "Effects.Undetectable", 0)
            for radius, sound in Layers do
                local Upcoming = Radiuses[sound.Name.."Upcoming"] or -1e10

                if self.InChase then
                    if Distance <= Radiuses["L1"] and not HasUndetectable then
                        if sound.Name == "L4" then
                            Playing = true
                            self:TweenVolume(sound, Distance < 55 and 0.5 or CalculateSound(Distance), delta)
                        else
                            self:TweenVolume(sound, 0, delta)
                        end
                    else
                        self.InChase = false
                        if sound.Name == "L4" then
                            self.Playing = false
                            self:TweenVolume(sound, 0, delta)
                        end
                    end
                else
                    if Distance <= radius and Distance >= Upcoming and not HasUndetectable then
                        if sound.Name == "L4" then
                            Playing = true
                            self.InChase = true
                            self:PlayLayer4(tostring(CurrentKillerChosen), delta)
                            self:TweenVolume(sound, 0.5, delta)
                        else
                            Playing = true
                            self:TweenVolume(sound, CalculateSound(Distance), delta)
                        end
                    else
                        self:TweenVolume(sound, 0, delta)
                    end
                end
            end
            continue
        end
        
        for _, sound in Killer do
            self:TweenVolume(sound, 0, delta)
        end
    end

    if self.MapAmbience then
        if Playing then
            if self.MapAmbienceTweenState ~= "Stop" then
                self.MapAmbienceTweenState = "Stop"
                TweenService:Create(self.MapAmbience, TweenInfo.new(0.4), {Volume = 0}):Play()
            end
        else
            if self.MapAmbienceTweenState ~= "Play" then
                self.MapAmbienceTweenState = "Play"
                TweenService:Create(self.MapAmbience, TweenInfo.new(0.4), {Volume = self.MapAmbienceVolume}):Play()
            end
        end
    end

    return
end

function TerrorRadiusManager:_CheckAsKiller(delta: number)
    local ClosestDistance = 50000

    for _, char in workspace.Players:GetChildren() do
        if char == self.LocalPlayerProps.Char then
            continue
        end

        local Hum = char:FindFirstChildWhichIsA("Humanoid")
        if not Hum or Hum.Health <= 0 then
            continue
        end

        local Role = char:FindFirstChild("Role")
        if not Role or Role.Value == "Survivor" then
            continue
        end

        if not Utils.Instance.FindFirstChild(char, "Effects.Undetectable", 0) then
            continue
        end

        local Root = char:FindFirstChild("HumanoidRootPart") or Hum.RootPart
        if not Root then
            continue
        end
            
        local Distance = (Root.Position - self.LocalPlayerProps.HRP.Position).Magnitude
        if ClosestDistance > Distance then
            ClosestDistance = Distance
        end
    end

    self.InChase = if self.InChase then ClosestDistance <= Radiuses.L1 else ClosestDistance <= Radiuses.L4

    for r: number, s: Sound in self.LayerMagnitudes[self.LocalPlayerProps.Char.Name] do
        if s.Name == "L4" then
            self:TweenVolume(s, self.InChase and 0.5 or 0, delta)
        end
    end

    if self.InChase then
        self:PlayLayer4(self.LocalPlayerProps.Char.Name, delta)
    else
        self.Playing = false
    end
end

return TerrorRadiusManager
