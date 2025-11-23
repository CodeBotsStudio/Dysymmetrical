--!nocheck

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Rand = Random.new()

local Utils = require(ReplicatedStorage.Modules.Utils)

local SoundFolder = game:GetService("ReplicatedStorage").Assets.Sounds

local Sounds = {
    CommonlyUsedSounds = {
        ButtonHover = "rbxassetid://7249904928",
        ButtonHoverStop = "rbxassetid://7249903719",
        ButtonPress = "rbxassetid://112754501285226",
    },
}

function Sounds:Init()
    if not RunService:IsServer() then
        Utils:PreloadAssets(self.CommonlyUsedSounds)
    end
    workspace.Themes.ChildAdded:Connect(function()
        self:UpdateThemes()
    end)
    workspace.Themes.ChildRemoved:Connect(function()
        self:UpdateThemes()
    end)
end

--- Returns a sound with the ID `ID` originating from the sound folder in `ReplicatedStorage` for proper preloading.
--- Will return a clone of the sound instead if `clone` is `true`.
function Sounds:GetSound(ID: string, clone: boolean?): Sound?
    if clone == nil then --not using `clone = clone or true` because if you pass in `false` it gets turned to `true`
        clone = true
    end

    if ID:find("rbxassetid://") then
        local Sound = SoundFolder:FindFirstChild(ID)
        if Sound then
            return clone and Sound:Clone() or Sound
        else
            Sound = Instance.new("Sound")
            Sound.Name = ID
            Sound.SoundId = ID
            Sound.SoundGroup = SoundService.SoundGroups.Master.SFX
            Sound.RollOffMode = Enum.RollOffMode.Linear
            Sound.RollOffMinDistance = 12
            Sound.RollOffMaxDistance = 60
            Sound.Parent = SoundFolder
            return clone and Sound:Clone() or Sound
        end
    else
        local final = ID:match("^%D+") or ID
        local arr = {}
        for _, i in SoundFolder:GetDescendants() do
            if i:IsA("Sound") and (i.Name:match("^%D+") or i.Name) == final then
                table.insert(arr, i)
            end
        end
        if #arr > 0 then
            return #arr > 1 and arr[math.random(1, #arr)] or arr[1]
        end
    end

    return
end

--- Plays a sound with the ID `ID`.
--- Check `Sound`'s properties for further usage.
function Sounds:PlaySound(ID: string | {string}, SoundProperties: {[string]: any?}?): Sound?
    if typeof(ID) ~= "string" and typeof(ID) ~= "table" then
        return
    end

    if typeof(ID) == "table" then
        return self:PlaySound(ID[Rand:NextInteger(1, #ID)], SoundProperties)
    elseif #ID <= 0 then
        return
    end

    local Sound = self:GetSound(ID, true)
    if not Sound then
        return
    end
    Sound.Parent = nil --for setting the parent later
    Sound.Volume = SoundProperties.Volume or 0.5

    for _, i in self.CommonlyUsedSounds do --weird hack but fuck it
        if ID == i then
            Sound.SoundGroup = SoundService.SoundGroups.Master.UI
            break
        end
    end

    local Part = nil
    if SoundProperties then
        for name, value in SoundProperties do
            if name == "Position" then
                Part = Utils:GetInvisPart(typeof(value) == "Vector3" and CFrame.new(value) or value)
                Part.Name = Sound.Name
                Part.Parent = workspace.Sounds
                Sound.Parent = Part
            elseif name:lower():find("pitch") then
                continue
            else
                Sound[name] = value
            end
        end

        if SoundProperties.MinPitch or SoundProperties.MaxPitch then
            local PitchShifter = Instance.new("PitchShiftSoundEffect")
            PitchShifter.Parent = Sound
            PitchShifter.Octave = Rand:NextNumber(SoundProperties.MinPitch or 1, SoundProperties.MaxPitch or 1)
        end
    end
    
    if not Sound.Parent then
        Sound.Parent = workspace.Sounds
    end

    Sound:Play()
    --also auto-destroys the sound on end
    Sound.Ended:Connect(function()
        task.wait()
        Sound:Destroy()
        if Part then
            Part:Destroy()
        end
    end)

    return Sound
end

local ThemeTweenDurationHolder = 0.8

--- Plays a theme using `Sounds:PlaySound()`.
--- It's better for background music than straight up using `Sounds:PlaySound()` due to it being managed between every other theme playing.
function Sounds:PlayTheme(ID: string | Instance, properties: {[string]: any}): Sound
    local name = tostring(ID)
    if typeof(ID) ~= "Instance" and typeof(ID) ~= "string" then
        return
    elseif workspace.Themes:FindFirstChild(name) then
        return workspace.Themes:FindFirstChild(name), true
    else
        if not properties then
            properties = {}
        end
        if not properties.Name then
            properties.Name = name
        end
        if not properties.SoundGroup then
            properties.SoundGroup = SoundService.SoundGroups.Master.Music
        end
        if properties.Looped == nil then
            properties.Looped = true
        end

        properties = Utils:CopyTable(properties)

        local Priority = properties.Priority or 1
        properties.Priority = nil

        ThemeTweenDurationHolder = properties.TweenTime or 0.8
        properties.TweenTime = nil

        local Volume = properties.Volume or 0.5
        properties.Volume = nil

        local SoundInstance = self:PlaySound(name, properties)

        if SoundInstance then
            if properties.TimePosition then
                SoundInstance.TimePosition = properties.TimePosition
            end
            
            SoundInstance:SetAttribute("Priority", Priority)
            SoundInstance:SetAttribute("Volume", Volume)
            SoundInstance:SetAttribute("ServerMade", RunService:IsServer())

            SoundInstance.Parent = properties.Parent or workspace.Themes
        end

        return SoundInstance
    end
end

--- Updates every theme to play the top priority one.
function Sounds:UpdateThemes()
    local TopMusic
    for _, i in workspace.Themes:GetChildren() do
        if i.Name == "Destroying" then
            continue
        end
        if not TopMusic or i:GetAttribute("Priority") > TopMusic:GetAttribute("Priority") then
            TopMusic = i
        end
    end
    if not TopMusic then
        return
    end

    local TweenDuration = ThemeTweenDurationHolder or 0.8
    ThemeTweenDurationHolder = nil
    for _, i in workspace.Themes:GetChildren() do
        if i.Name == "Destroying" then
            continue
        end

        if i == TopMusic then
            TweenService:Create(i, TweenInfo.new(TweenDuration), {
                Volume = i:GetAttribute("Volume") or 1
            }):Play()
        else
            TweenService:Create(i, TweenInfo.new(TweenDuration), {
                Volume = 0
            }):Play()
        end
    end
end

--- Stops a playing theme with the ID `ID`.
function Sounds:StopTheme(ID: string, FadeOut: number?, UpdateThemes: boolean?)
    if typeof(ID) ~= "string" then
        return
    end

    if type(FadeOut) ~= "number" then
        FadeOut = 0.8
    end
    local First = workspace.Themes:FindFirstChild(ID)
    if First and not (First:GetAttribute("ServerMade") and not RunService:IsServer()) then
        First.Name = "Destroying"
        First:SetAttribute("Priority", -999)
        if UpdateThemes ~= false then
            self:UpdateThemes()
        end
        TweenService:Create(First, TweenInfo.new(FadeOut), {Volume = 0}):Play()
        game.Debris:AddItem(First, FadeOut + 0.1)
    end
    return First
end

--- Plays a voice line inside of a rig. Used instead of `Sounds:PlaySound()` since it has a priority system.
function Sounds:PlayVoiceline(Rig: Model, ID: string | {[string]: string | {string}}, SoundSettings: {[string]: any}?)
    local Primary = Rig.PrimaryPart or Rig:FindFirstChild("HumanoidRootPart")
    if not Primary then
        return
    end

    if not SoundSettings then
        SoundSettings = {}
    end
    if not SoundSettings.Name then
        SoundSettings.Name = "Voiceline"
    end
    if not SoundSettings.Parent then
        SoundSettings.Parent = Primary
    end
    if not SoundSettings.SoundGroup then
        SoundSettings.SoundGroup = SoundService.SoundGroups.Master.VoiceLines
    end
    local Priority = SoundSettings.Priority or 1
    SoundSettings.Priority = nil
    if not SoundSettings.Volume then
        SoundSettings.Volume = 0.5
    end
    local Voiceline = Primary:FindFirstChild("Voiceline")
    
    if Voiceline then
        if Priority <= 0 or Priority <= Voiceline:GetAttribute("Priority") then
            return
        end

        Debris:AddItem(Voiceline, 0.25)
        TweenService:Create(Voiceline, TweenInfo.new(0.25), {
            Volume = 0
        }):Play()
        Voiceline.Name = "OldVoiceline"
        Voiceline = Primary:FindFirstChild("Voiceline")
    end

    if SoundSettings.Chance then
        if SoundSettings.Chance < Rand:NextNumber() then
            return
        end
        SoundSettings.Chance = nil
    end

    if typeof(ID) == "table" then
        ID = ID[1] ~= nil and ID or next(ID)
    end

    local SoundInstance = self:PlaySound(ID, SoundSettings)
    if SoundInstance then
        SoundInstance:SetAttribute("Priority", Priority)
    end
    return SoundInstance
end

return Sounds
