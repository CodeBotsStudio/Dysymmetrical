--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

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
    Layers = {},
    Killer = nil,
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
}

local function CalculateSound(Distance)
	return 4.96 / (Distance + 10.26)
end

function TerrorRadiusManager:Init()
    if not self.AbleToInit then
        return
    end
    local Char = LocalPlayer.Character
    local Role = CommonUtils:FindFirstChild(Char, "Role").Value
    if Role == "Spectator" then
        return
    end
    self.LocalPlayerProps = {
        Role = Role,
        Char = Char,
        Humanoid = CommonUtils:FindFirstChild(Char, "Humanoid"),
        HRP = CommonUtils:FindFirstChild(Char, "HumanoidRootPart"),
    }

    local ThemeFolder = Instance.new("Folder")
    ThemeFolder.Name = "ChaseThemes"
    ThemeFolder.Parent = SoundService
    self.ThemeFolder = ThemeFolder

    table.insert(self.Connections, LocalPlayer.CharacterAdded:Connect(function()
        self:Destroy()
    end))

    --slow down on death fx
    table.insert(self.Connections, self.LocalPlayerProps.Humanoid.Died:Connect(function()
        for _, s in self.ThemeFolder do
            TweenService:Create(s, TweenInfo.new(0.4), {PlaybackSpeed = 0}):Play()
        end
    end))

    if RoundState.Value ~= "InRound" then
        repeat task.wait()
        until RoundState.Value == "InRound"
    end

    --TODO: multi-killer support
    for _, character in workspace.Players:GetChildren() do
        local OtherRole = CommonUtils:FindFirstChild(character, "Role").Value
        if OtherRole == "Killer" then
            self.Killer = character
            break
        end
    end

    if not self.Killer then
        return
    end

    local ChaseThemes = require(CommonUtils:GetCharacterModule("Killer", self.Killer:GetAttribute("CharacterName"), self.Killer:GetAttribute("CharacterSkinName"))).Config.ChaseThemes
    for l, i in ChaseThemes do
        local Sound = Instance.new("Sound")
        Sound.Name = l
        Sound.SoundId = i
        Sound.Volume = 0
        Sound.Looped = true
        Sound.SoundGroup = SoundService.SoundGroups.Master.Music
        Sound.Parent = self.ThemeFolder

		if not Sound.IsLoaded then
			Sound.Loaded:Wait()
		end

        self:SetLayerMagnitude(Sound, Radiuses[l])
    end

    for _, i in self.ThemeFolder:GetChildren() do
        if i:IsA("Sound") and i.Name ~= "L4" then
            i:Play()
        end
    end

    table.insert(self.Connections, RunService.PreRender:Connect(function()
        self:CheckInRadius()
    end))

    table.insert(self.Connections, CommonUtils:FindFirstChild(self.Killer, "Humanoid").Died:Connect(function()
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

function TerrorRadiusManager:SetLayerMagnitude(SoundInstance: Sound, Radius: number)
    self.LayerMagnitudes[Radius] = SoundInstance
end

function TerrorRadiusManager:CheckInRadius()
    if self.LocalPlayerProps.Role == "Survivor" then
        self:_CheckAsSurvivor()
    elseif self.LocalPlayerProps.Role == "Killer" then
        self:_CheckAsKiller()
    end
end

function TerrorRadiusManager:TweenVolume(Sound: Sound, TargetVolume: number)
    if math.abs(Sound.Volume - TargetVolume) > 0.01 then
        TweenService:Create(Sound, TweenInfo.new(0.2), {Volume = TargetVolume}):Play()
    end
end

function TerrorRadiusManager:PlayLayer4()
    if self.Playing then
        return
    end
    self.Playing = true

    for _, s: Sound in self.LayerMagnitudes do
        if s.Name == "L4" then
            s:Play()
            self:TweenVolume(s, 0.5)
            local conn
            conn = s.Changed:Connect(function()
                if s.Volume <= 0 then
                    conn:Disconnect()
                end
            end)
            table.insert(self.Connections, conn)
        else
            self:TweenVolume(s, 0)
        end
    end
end

function TerrorRadiusManager:_CheckAsSurvivor()
    local KillerHRP = CommonUtils:FindFirstChild(self.Killer, "HumanoidRootPart")
    if not (self.LocalPlayerProps.HRP and KillerHRP) then
        return
    end

    local Distance = self.LocalPlayerProps.Humanoid and self.LocalPlayerProps.Humanoid.Health > 0 and (self.LocalPlayerProps.HRP.Position - KillerHRP.Position).Magnitude or 1e999

    for r: number, s: Sound in self.LayerMagnitudes do
        local Upcoming = Radiuses[s.Name.."Upcoming"] or -1e10

        if self.InChase then
            if Distance < Radiuses["L1"] and not CommonUtils:FindFirstChild(KillerHRP.Parent, "Effects.Undetectable", false) then
                if s.Name == "L4" then
                    self:TweenVolume(s, Distance < 55 and 0.5 or CalculateSound(Distance))
                else
                    self:TweenVolume(s, 0)
                end
            else
                self.InChase = false
                if s.Name == "L4" then
                    self:TweenVolume(s, 0)
                end
            end
        else
            if Distance <= r and Distance > Upcoming and not CommonUtils:FindFirstChild(KillerHRP.Parent, "Effects.Undetectable", false) then
                if s.Name == "L4" then
                    self.InChase = true
                    self:PlayLayer4()
                else
                    self:TweenVolume(s, CalculateSound(Distance))
                end
            else
                self:TweenVolume(s, 0)
            end
        end
    end
end

function TerrorRadiusManager:_CheckAsKiller()
    for _, char in workspace.Players:GetChildren() do
        if char ~= self.LocalPlayerProps.Char
        and char:FindFirstChild("Role") and char.Role.Value == "Survivor"
        and char:FindFirstChildOfClass("Humanoid").Health > 0
        and not CommonUtils:FindFirstChild(char, "Effects.Undetectable", false) then
            
            local Distance = (CommonUtils:FindFirstChild(char, "HumanoidRootPart").Position - self.LocalPlayerProps.HRP.Position).Magnitude
            self.PlayerClose = Distance <= 60
            self.InChase = Distance <= 25 or self.InChase and Distance <= 35

            for r: number, s: Sound in self.LayerMagnitudes do
                if s.Name == "L4" then
                    self:TweenVolume(s, (self.PlayerClose and self.InChase) and 0.5 or 0)
                end
            end

            if self.InChase then
                self:PlayLayer4()
            end
        end
    end
end

return TerrorRadiusManager
