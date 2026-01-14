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
        Utils.Misc.PreloadAssets(Sounds.CommonlyUsedSounds)
    end
    Utils.Instance.ObserveChildren(workspace.Themes, function()
        Sounds.UpdateThemes()
    end):Add(workspace.Themes.ChildRemoved:Connect(function()
        Sounds.UpdateThemes()
    end))
end

--- Returns a sound with the ID `ID` originating from the sound folder in `ReplicatedStorage` for proper preloading.
--- 
--- Will return a clone of the sound instead if `clone` is `true`.
function Sounds.GetSound(ID: string, clone: boolean?): Sound?
    if clone == nil then --not using `clone = clone or true` because if you pass in `false` it gets turned to `true`
        --clone it by default for obvious reasons
        clone = true
    end

    if ID:find("rbxassetid://") then
        local Sound = SoundFolder:FindFirstChild(ID)
        --return it if it already exists
        if Sound then
            --return a clone if stated
            return clone and Sound:Clone() or Sound
        else
            --set all props
            Sound = Instance.new("Sound")
            Sound.Name = ID
            Sound.SoundId = ID
            Sound.SoundGroup = SoundService.SoundGroups.Master.SFX
            Sound.RollOffMode = Enum.RollOffMode.Linear
            Sound.RollOffMinDistance = 12
            Sound.RollOffMaxDistance = 60
            Sound.Parent = SoundFolder
            --return a clone if stated
            return clone and Sound:Clone() or Sound
        end
    else
        --strip numbers off of the end of `ID`
        -- * `^` gets the characters from the beginning
        -- * `%D` is the opposite of %d which means any characters except for digits
        -- * `+` mandatorily matches 1 and possibly matches more occurences of non-digit characters
        local final = ID:match("^%D+") or ID
        local arr = {}
        --search for every `Sound` in the SoundFolder that has a matching name to `final` by also stripping off its numbers
        for _, Sound in SoundFolder:GetDescendants() do
            if Sound:IsA("Sound") and (Sound.Name:match("^%D+") or Sound.Name) == final then
                table.insert(arr, Sound)
            end
        end
        --return the sound if it found one or a random one from the list if it found multiple
        if #arr > 0 then
            return #arr > 1 and arr[math.random(1, #arr)] or arr[1]
        end
    end

    return
end

--- Plays a sound with the ID `ID`.
--- 
--- Check `Sound`'s properties for further usage.
function Sounds.PlaySound(ID: string | {string}, SoundProperties: {[string]: any?}?): Sound?
    if typeof(ID) ~= "string" and typeof(ID) ~= "table" then
        return
    end

    if typeof(ID) == "table" then
        return Sounds.PlaySound(ID[Rand:NextInteger(1, #ID)], SoundProperties)
    elseif #ID <= 0 then
        return
    end

    --the sound SHOULD be preloaded if `ID` isn't an actual `rbxassetid://xxxxxxxxxx` string
    local Sound = Sounds.GetSound(ID, true)
    if not Sound then
        return
    end
    Sound.Parent = nil --for setting the parent later
    Sound.Volume = SoundProperties.Volume or 0.5

    for _, CommonID in Sounds.CommonlyUsedSounds do --weird hack but fuck it
        if ID == CommonID then
            Sound.SoundGroup = SoundService.SoundGroups.Master.UI
            break
        end
    end

    local Part = nil
    if SoundProperties then
        --instancing a part for the position stated in the props
        if SoundProperties.Position then
            Part = Utils.Instance.GetInvisPart(typeof(SoundProperties.Position) == "Vector3" and CFrame.new(SoundProperties.Position) or SoundProperties.Position)
            Part.Name = Sound.Name
            Part.Parent = workspace.Sounds
            Sound.Parent = Part
        end
        --removing properties to not conflict with DeepTableOverwrite
        SoundProperties.Position = nil

        --adding pitch shifting if the pitch has a range
        if SoundProperties.MinPitch or SoundProperties.MaxPitch then
            local PitchShifter = Instance.new("PitchShiftSoundEffect")
            PitchShifter.Parent = Sound
            PitchShifter.Octave = Rand:NextNumber(SoundProperties.MinPitch or 1, SoundProperties.MaxPitch or 1)
        end
        --removing properties to not conflict with DeepTableOverwrite
        SoundProperties.MinPitch = nil
        SoundProperties.MaxPitch = nil

        --fun fact: DeepTableOverwrite can also be used with `Instance`s!
        Utils.Type.DeepTableOverwrite(Sound, SoundProperties)
    end
    
    --setting a parent as a default value
    if not Sound.Parent then
        Sound.Parent = workspace.Sounds
    end
    
    --auto-destroys the sound on end
    Sound.Ended:Connect(function()
        task.wait()
        Sound:Destroy()
        if Part then
            Part:Destroy()
        end
    end)

    Sound:Play()

    return Sound
end

local ThemeTweenDurationHolder = 0.8

--- Plays a theme using `Sounds.PlaySound()`.
--- 
--- It's better for background music than straight up using `Sounds.PlaySound()` due to it being managed between every other theme playing.
--- 
--- @return The correspondant `Sound` instance if the `ID` parameter is correct.
--- @return A `boolean` indicating if `ID` already existed in the Themes folder.
function Sounds.PlayTheme(ID: string | Instance, properties: {[string]: any}): (Sound, boolean)
    local name = tostring(ID)
    if typeof(ID) ~= "Instance" and typeof(ID) ~= "string" then
        return nil, false
    elseif workspace.Themes:FindFirstChild(name) then
        return workspace.Themes:FindFirstChild(name), true
    else
        local DefaultProperties = {
            Name = name,
            Parent = workspace.Themes,
            SoundGroup = SoundService.SoundGroups.Master.Music,
            Looped = true,
            Priority = 1,
            TweenTime = 0.8,
            Volume = 0.5,
        }
        if not properties then
            properties = DefaultProperties
        else
            Utils.Type.DeepTableWrite(properties, DefaultProperties)
        end

        ThemeTweenDurationHolder = properties.TweenTime
        properties.TweenTime = nil
        local Priority = properties.Priority
        properties.Priority = nil

        local SoundInstance = Sounds.PlaySound(name, properties)

        if SoundInstance then
            if properties.TimePosition then
                SoundInstance.TimePosition = properties.TimePosition
            end
            
            SoundInstance:SetAttribute("Priority", Priority)
            SoundInstance:SetAttribute("Volume", properties.Volume)
            SoundInstance:SetAttribute("ServerMade", RunService:IsServer())
        end

        return SoundInstance, false
    end
end

--- Updates every theme to play the top priority one.
function Sounds.UpdateThemes()
    --if there are no existing themes don't do anything
    local ExistingThemes = workspace.Themes:GetChildren()
    if #ExistingThemes <= 0 then
        return
    end

    local TopMusic
    local ChosenThemes = {}

    --check if there are any eligible ones and save the top one
    for _, Theme in ExistingThemes do
        if Theme.Name:lower() == "destroying" then
            continue
        end
        
        --adds it to a diff table to not re-check the ones named `Destroying` after
        table.insert(ChosenThemes, Theme)

        --checks if the priority of the currently indexed theme is higher than the current top one
        if not TopMusic or Theme:GetAttribute("Priority") > TopMusic:GetAttribute("Priority") then
            TopMusic = Theme
        end
    end

    --if there are no eligible themes then don't do anything
    if #ChosenThemes <= 0 or not TopMusic then
        return
    end

    --cool sauce
    local TweenDuration = ThemeTweenDurationHolder or 0.8
    ThemeTweenDurationHolder = nil

    --tweening every chosen theme to 0 if it's not the top priority one
    for _, Theme in ChosenThemes do
        TweenService:Create(Theme, TweenInfo.new(TweenDuration), {
            Volume = Theme == TopMusic and (Theme:GetAttribute("Volume") or 1) or 0
        }):Play()
    end
end

--- Stops a playing theme with the ID `ID`.
function Sounds.StopTheme(ID: string, FadeOut: number?, UpdateThemes: boolean?)
    if typeof(ID) ~= "string" then
        return
    end

    --fadeout default value
    FadeOut = FadeOut and typeof(FadeOut) == "number" and FadeOut or 0.8

    --if the theme exists then do cool stuff
    local ThemeToRemove = workspace.Themes:FindFirstChild(ID)
    if ThemeToRemove and not (ThemeToRemove:GetAttribute("ServerMade") and not RunService:IsServer()) then
        --mark it to be destroyed with impossible to reach priority
        ThemeToRemove.Name = "Destroying"
        ThemeToRemove:SetAttribute("Priority", -999)

        --update all themes
        if UpdateThemes then
            Sounds.UpdateThemes()
        end

        --tween it out and queue it for removal
        TweenService:Create(ThemeToRemove, TweenInfo.new(FadeOut), {Volume = 0}):Play()
        Debris:AddItem(ThemeToRemove, FadeOut + 0.1)
    end

    return ThemeToRemove
end

--- Plays a voice line inside of a rig. Used instead of `Sounds.PlaySound()` since it has a priority system.
function Sounds.PlayVoiceline(Rig: Model, ID: string | {[string]: string | {string}}, SoundSettings: {[string]: any}?)
    --get the root
    local Primary = Utils.Character.GetRootPart(Rig)
    if not Primary then
        return
    end

    local Defaults = {
        Name = "Voiceline",
        Parent = Primary,
        SoundGroup = SoundService.SoundGroups.Master.VoiceLines,
        Volume = 0.5,
        Priority = 1,
    }

    --set default values in non-existent ones
    if not SoundSettings then
        SoundSettings = Defaults
    else
        Utils.Type.DeepTableWrite(SoundSettings, Defaults)
    end

    --make priority a local variable to not pass it to `Sounds.PlaySound` later
    local Priority = SoundSettings.Priority
    SoundSettings.Priority = nil

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

    local SoundInstance = Sounds.PlaySound(ID, SoundSettings)
    if SoundInstance then
        SoundInstance:SetAttribute("Priority", Priority)
    end
    return SoundInstance
end

return Sounds
