--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)

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
    Connections = {},
    InChase = false,
    PlayerClose = false,
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
}

local function CalculateSound(Distance)
	return 4.96 / (Distance + 10.26)
end

function TerrorRadiusManager:Init()
    if not self.AbleToInit then
        return
    end
    local Char = LocalPlayer.Character
    local Role = Utils:FindFirstChild(Char, "Role").Value
    if Role == "Spectator" then
        return
    end
    self.LocalPlayerProps = {
        Role = Role,
        Char = Char,
        Humanoid = Utils:FindFirstChild(Char, "Humanoid"),
        HRP = Utils:FindFirstChild(Char, "HumanoidRootPart"),
    }

    self.MapAmbience = workspace.Themes:FindFirstChild("MapAmbience")
    self.MapAmbienceVolume = self.MapAmbience and self.MapAmbience.Volume or 0

    local ThemeFolder = Instance.new("Folder")
    ThemeFolder.Name = "ChaseThemes"
    ThemeFolder.Parent = SoundService
    self.ThemeFolder = ThemeFolder

    --slow down on death fx
    table.insert(self.Connections, self.LocalPlayerProps.Humanoid.Died:Connect(function()
        for _, s in self.ThemeFolder:GetDescendants() do
            if not s:IsA("Sound") then
                continue
            end
            TweenService:Create(s, TweenInfo.new(0.4), {PlaybackSpeed = 0}):Play()
        end
    end))

    if RoundState.Value ~= "InRound" then
        repeat task.wait()
        until RoundState.Value == "InRound"
    end

    for _, i in workspace.Players:GetChildren() do
        if not i:FindFirstChild("Role") or i.Role.Value ~= "Killer" then
            continue
        end

        local F = Instance.new("Folder")
        F.Name = i.Name
        F.Parent = self.ThemeFolder

        local ChaseThemes = require(Utils:GetCharacterModule("Killer", i:GetAttribute("CharacterName"), i:GetAttribute("CharacterSkinName"))).Config.ChaseThemes
        for l, v in ChaseThemes do
            local Sound = Instance.new("Sound")
            Sound.Name = l
            Sound.SoundId = v
            Sound.Volume = 0
            Sound.Looped = true
            Sound.SoundGroup = SoundService.SoundGroups.Master.Music
            Sound.Parent = F

	    	if not Sound.IsLoaded then
	    		Sound.Loaded:Wait()
	    	end

            self:SetLayerMagnitude(Sound, i.Name, Radiuses[l])
        end
    end

    for _, i in self.ThemeFolder:GetDescendants() do
        if i:IsA("Sound") and i.Name ~= "L4" then
            i:Play()
        end
    end

    table.insert(self.Connections, RunService.PreRender:Connect(function(delta: number)
        self:CheckInRadius(delta)
    end))

    table.insert(self.Connections, LocalPlayer.CharacterAdded:Connect(function()
        self:Destroy()
    end))
end

function TerrorRadiusManager:Destroy()
    if self.ThemeFolder then
        self.ThemeFolder:Destroy()
    end
    for _, c in self.Connections do
        c:Disconnect()
    end
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
        Sound.Volume = Utils:Lerp(Sound.Volume, TargetVolume, delta * 14)
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
            conn = s.Changed:Connect(function()
                if s.Volume <= 0 then
                    conn:Disconnect()
                end
            end)
            table.insert(self.Connections, conn)
        else
            self:TweenVolume(s, 0, delta)
        end
    end
end

function TerrorRadiusManager:_CheckAsSurvivor(delta: number)
    local PlayersFound = {}
    for _, i in workspace.Players:GetChildren() do
        if not self.ThemeFolder:FindFirstChild(i.Name) and i:FindFirstChild("Role") and i.Role.Value == "Killer" then
            local F = Instance.new("Folder")
            F.Name = i.Name
            F.Parent = self.ThemeFolder

            local ChaseThemes = require(Utils:GetCharacterModule("Killer", i:GetAttribute("CharacterName"), i:GetAttribute("CharacterSkinName"))).Config.ChaseThemes
            for l, v in ChaseThemes do
                local Sound = Instance.new("Sound")
                Sound.Name = l
                Sound.SoundId = v
                Sound.Volume = 0
                Sound.Looped = true
                Sound.SoundGroup = SoundService.SoundGroups.Master.Music
                Sound.Parent = F

	        	if not Sound.IsLoaded then
	        		Sound.Loaded:Wait()
	        	end

                self:SetLayerMagnitude(Sound, i.Name, Radiuses[l])
            end
        end
        table.insert(PlayersFound, i.Name)
    end
    for _, i in self.ThemeFolder:GetChildren() do
        if not table.find(PlayersFound, i.Name) then
            i:Destroy()
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
        for _, i in workspace.Players:GetChildren() do
            if not i:FindFirstChild("Role") or i.Role.Value ~= "Killer" then
                continue
            end

            local Distance = self.LocalPlayerProps.Humanoid and self.LocalPlayerProps.Humanoid.Health > 0 and (self.LocalPlayerProps.HRP.Position - i:FindFirstChild("HumanoidRootPart").Position).Magnitude or 1e999
            if Distance <= Radiuses["L1"] and (not CurrentKillerChosen or Distance <= CurrentKillerChosen.Distance) then
                CurrentKillerChosen = {
                    Player = i,
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

    local Distance = self.LocalPlayerProps.Humanoid and self.LocalPlayerProps.Humanoid.Health > 0 and (self.LocalPlayerProps.HRP.Position - KillerHRP.Position).Magnitude or 1e999

    local Playing = false
    for n, i in self.LayerMagnitudes do
        if tostring(n) == tostring(CurrentKillerChosen) then
            for r, s in i do
                local Upcoming = Radiuses[s.Name.."Upcoming"] or -1e10

                if self.InChase then
                    if Distance < Radiuses["L1"] and not Utils:FindFirstChild(KillerHRP.Parent, "Effects.Undetectable", false) then
                        if s.Name == "L4" then
                            Playing = true
                            self:TweenVolume(s, Distance < 55 and 0.5 or CalculateSound(Distance), delta)
                        else
                            self:TweenVolume(s, 0, delta)
                        end
                    else
                        self.InChase = false
                        if s.Name == "L4" then
                            self.Playing = false
                            self:TweenVolume(s, 0, delta)
                        end
                    end
                else
                    if Distance <= r and Distance > Upcoming and not Utils:FindFirstChild(KillerHRP.Parent, "Effects.Undetectable", false) then
                        if s.Name == "L4" then
                            Playing = true
                            self.InChase = true
                            self:PlayLayer4(tostring(CurrentKillerChosen), delta)
                            self:TweenVolume(s, 0.5, delta)
                        else
                            Playing = true
                            self:TweenVolume(s, CalculateSound(Distance), delta)
                        end
                    else
                        self:TweenVolume(s, 0, delta)
                    end
                end
            end
            continue
        end
        
        for _, s in i do
            self:TweenVolume(s, 0, delta)
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
    local ClosestDistance = 1e999

    for _, char in workspace.Players:GetChildren() do
        if char ~= self.LocalPlayerProps.Char
        and char:FindFirstChild("Role") and char.Role.Value == "Survivor"
        and char:FindFirstChildOfClass("Humanoid").Health > 0
        and not Utils:FindFirstChild(char, "Effects.Undetectable", false) then
            
            local Distance = (Utils:FindFirstChild(char, "HumanoidRootPart").Position - self.LocalPlayerProps.HRP.Position).Magnitude
            if ClosestDistance > Distance then
                ClosestDistance = Distance
            end
        end
    end

    self.PlayerClose = ClosestDistance <= Radiuses.L1
    self.InChase = self.InChase and ClosestDistance <= Radiuses.L2 or ClosestDistance <= Radiuses.L4

    for r: number, s: Sound in self.LayerMagnitudes[self.LocalPlayerProps.Char.Name] do
        if s.Name == "L4" then
            self:TweenVolume(s, (self.PlayerClose and self.InChase) and 0.5 or 0, delta)
        end
    end

    if self.InChase then
        self:PlayLayer4(self.LocalPlayerProps.Char.Name, delta)
    else
        self.Playing = false
    end
end

return TerrorRadiusManager
