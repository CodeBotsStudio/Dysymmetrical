local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Rand = Random.new()

local Utils = require(script.Parent.Utils)

local LoadedSounds = Utils.Instance.AwaitChild(script, "LoadedSounds")

local Sounds = {
    CommonSounds = {
        ButtonHover = "rbxassetid://7249904928",
        ButtonHoverStop = "rbxassetid://7249903719",
        ButtonPress = "rbxassetid://112754501285226",
    },
}

function Sounds:Init()
end

--- Tries to get a `Sound` instance from the loaded sounds folder.
--- 
--- If it's not present, it'll be created unless `ID` isn't a `rbxassetid`.
--- 
--- In the case of the latter, it'll look for the sound directly in the folder with its name without any numbers.
--- 
--- A sound that is considered not to be a `rbxassetid` is one that doesn't start with `rbxassetid://`.
function Sounds.GetSound(ID: string, Clone: boolean?): Sound
    --defaults
    if Clone == nil then
        Clone = true
    end

    --if the asset url prefix is already written, use the string directly
    if ID:find("rbxassetid://") then
        --try to find it in the already loaded sounds
        local Sound = LoadedSounds:FindFirstChild(ID)
        --if it's found, return it (clone if asked to)
        if Sound then
            return Clone and Sound:Clone() or Sound
        end

        --if it wasn't found, make a new instance instead
        Sound = Instance.new("Sound")
        Sound.Name = ID
        Sound.SoundId = ID
        Sound.SoundGroup = SoundService.SoundGroups.Master.SFX
        Sound.RollOffMode = SoundService.RollOffMode.Linear
        Sound.RollOffMinDistance = 12
        Sound.RollOffMaxDistance = 60
        Sound.Parent = LoadedSounds
        --again, if asked to clone, clone
        return Clone and Sound:Clone() or Sound
    end

    --if the id doesn't have the prefix already, strip numbers off of the end of `ID`
    -- * `^` gets the characters from the beginning
    -- * `%D` is the opposite of %d which means any characters except for digits
    -- * `+` mandatorily matches 1 and possibly matches more occurences of non-digit characters
    local final = ID:match("^%D+") or ID
    local arr = {}
    --search for every `Sound` in LoadedSounds that has a matching name to `final` by also stripping off its numbers
    for _, Sound in LoadedSounds:GetDescendants() do
        --quick sanity check
        if not (Sound:IsA("Sound") and (Sound.Name:match("^%D+") or Sound.Name) == final) then
            continue
        end

        table.insert(arr, Sound)
    end
    --return the sound if it found one or a random one from the list if it found multiple
    if #arr > 0 then
        local Sound = #arr > 1 and arr[math.random(1, #arr)] or arr[1]
        return Clone and Sound:Clone() or Sound
    end

    --nothing was found, so return nothing
    return
end

--- Plays a sound with the ID `ID`.
--- 
--- Most of the times it should be a string starting with `rbxassetid://`. Read `Sounds.GetSound()`'s docs to understand why-
--- 
--- `ID` can also be a `table` / `dictionary` to choose a random sound from its values.
--- 
--- @param `Properties` - Any properties you want to set in the sound like `Volume`. `MinPitch` and `MaxPitch` are available in a magnitude of 1 to automatically create a pitch shifter.
function Sounds.PlaySound(ID: string | {string} | {[any]: string}, Properties: {[any]: any?}?): Sound
    --if there's a type mismatch, halt
    if typeof(ID) ~= "string" and typeof(ID) ~= "table" then
        return
    end

    --if it's a table, reset the function with one of its values
    if typeof(ID) == "table" then
        --turn into a table because you legitimately can't get a random member from a dictionary unless you take all of its values and put them in a new table
        local IdTable = Utils.Type.DictToTable(ID)
        return Sounds.PlaySound(IdTable[Rand:NextInteger(1, #IdTable)], Properties)
    end

    --from here, ID must be a string, so if it's empty, halt
    if #ID <= 0 then
        return
    end

    --if this sound's ID param isn't a rbxassetid, it should already be instanced so, if it's not, halt
    local Sound = Sounds.GetSound(ID, true)
    if not Sound then
        return
    end
    --setting parent later
    Sound.Parent = nil

    --if it's a common ID, since the ones inside the table by default are all UI, set it to the UI sound group automatically
    for _, CommonID in Sounds.CommonSounds do
        if CommonID == ID then
            Sound.SoundGroup = SoundService.SoundGroups.Master.UI
            break
        end
    end

    --define a local for the part containing the sound
    local Part
    
    --destroy the sound when it ends
    Sound.Ended:Connect(function()
        task.wait()
        Sound:Destroy()
        --if the part is there, destroy it
        if not Part then
            return
        end
        Part:Destroy()
    end)
    
    --spawning this so that it executes at the end immediately
    task.spawn(function()
        Sound:Play()
    end)

    --if there are no sound properties to be set, return the sound
    if not Properties then
        return Sound
    end

    --if there's a specific position in the properties, 
    if Properties.Position then
        --make an invis part to parent the sound to at the correspondant CFrame, parented to workspace.Sounds 
        Part = Utils.Instance.GetInvisPart(typeof(Properties.Position) == "Vector3" and CFrame.new(Properties.Position) or Properties.Position, workspace.Sounds)
        --naming n shi
        Part.Name = Sound.Name
        Sound.Parent = Part
        --set the parent from the properties to nil to prevent it from being reparented to another part instead of the invis one at the desired position
        Properties.Parent = nil
        --also set this to nil to prevent errors later
        Properties.Position = nil
    end

    --checking for random pitch
    if Properties.MinPitch or Properties.MaxPitch then
        --creating the pitch shifter
        local PitchShifter = Instance.new("PitchShiftSoundEffect")
        PitchShifter.Parent = Sound
        --octaves are in a magnitude of 1
        PitchShifter.Octave = Rand:NextNumber(Properties.MinPitch or 1, Properties.MaxPitch or 1)

        --setting to nil to prevent errors later
        Properties.MinPitch = nil
        Properties.MaxPitch = nil
    end

    --overwrite the rest of the properties
    Utils.Type.DeepTableOverwrite(Sound, Properties)

    --setting the parent if it's not set
    if not Sound.Parent then
        Sound.Parent = workspace.Sounds
    end

    --return the damn thing
    return Sound
end

--- Plays a voiceline inside of a rig.
--- 
--- If the rig is a `Model`, the parent of the voiceline will be its root part.
--- 
--- If `Properties.Priority` is a higher value than the currently playing voiceline's priority, it'll interrupt it and play the new one instead.
--- 
--- If `Properties.Chance` is present, a random float will be generated between 0 and 1. If this random number is higher than `Properties.Chance`, the voiceline won't play.
function Sounds.PlayVoiceline(Rig: Model | BasePart, ID: string | {string} | {[any]: string}, Properties: {[string]: any}): Sound
    --find the root if Rig is a model
    local Root = if Rig and Rig:IsA("Model") then Utils.Character.GetRootPart(Rig) else Rig
    --if there's nowhere to parent the voiceline to, halt
    if not Root then
        return
    end

    --some default values for the sound instance, including the parent
    local Defaults = {
        Name = "Voiceline",
        Parent = Root,
        SoundGroup = SoundService.SoundGroups.Master.Voicelines,
        Volume = 0.5,
        Priority = 1,
    }

    --write all of the defaults into the properties table
    --properties already present in Properties won't be overwritten
    Properties = Utils.Type.DeepTableWrite(Properties or {}, Defaults)

    --check if the chance is on the voiceline's side
    if Properties.Chance then
        --if it's lower than the number generated between 0 and 1, halt
        if Properties.Chance < Rand:NextNumber() then
            return
        end
        Properties.Chance = nil
    end

    --store the priority in a local variable for later use
    --then remove it from the properties table to prevent errors later
    local Priority = Properties.Priority or 0
    Properties.Priority = nil

    --if there's a voiceline, check:
    local Voiceline = Root:FindFirstChild("Voiceline")
    if Voiceline then
        --if it's a higher priority than the current voiceline (as long as it's higher than 0), halt
        if Priority <= 0 or Priority <= Voiceline:GetAttribute("Priority") then
            return
        end

        --if not, remove the voiceline
        Debris:AddItem(Voiceline, 0.25)

        --tween it out because idk man i like it
        TweenService:Create(Voiceline, TweenInfo.new(0.25), {Volume = 0}):Play()
        --rename to allow for later checking the real current voiceline
        Voiceline.Name = "OldVoiceline"
    end

    --play the voiceline
    Voiceline = Sounds.PlaySound(ID, Properties)
    --if it played successfully, set its priority attribute
    if Voiceline then
        Voiceline:SetAttribute("Priority", Priority)
    end
    --return the damn thing, doesn't matter if it's nil because it won't error
    return Voiceline
end

--variable to hold the current tweening time for fading themes
local ThemeTweenDurationHolder = 0.8

--- Plays a theme using `Sounds.PlaySound()`.
--- 
--- It's better for background music than straight up using `Sounds.PlaySound()` due to it being managed between every other theme already playing.
--- 
--- @return The correspondant `Sound` instance if the `ID` parameter is correct.
--- 
--- @return A `boolean` indicating if `ID` already existed in the Themes folder.
function Sounds.PlayTheme(ID: string | {string} | {[any]: string}, Properties: {[string]: any}): (Sound, boolean)
    --if the ID isn't valid, halt
    if typeof(ID) ~= "table" and typeof(ID) ~= "string" then
        --return `false` because, since there's no theme to play, it can't be already found
        --i love explaining stuff like shit -dys
        return nil, false
    end
    
    --if the ID is a table, choose a random string from it
    if typeof(ID) == "table" then
        local IdTable = Utils.Type.DictToTable(ID)
        ID = IdTable[Rand:NextInteger(1, #IdTable)]
    end

    --if there's already an existing theme, return it with `true`
    do
        local ExistingTheme = workspace.Themes:FindFirstChild(ID)
        if ExistingTheme then
            return ExistingTheme, true
        end
    end

    --defaults
    local DefaultProperties = {
        Name = ID,
        Parent = workspace.Themes,
        SoundGroup = SoundService.SoundGroups.Master.Music,
        Looped = true,
        Priority = 1,
        TweenTime = 0.8,
        Volume = 0.5,
    }

    --setting missing default values
    Properties = Utils.Type.DeepTableWrite(Properties or {}, DefaultProperties)

    --set the tween duration for UpdateThemes() to the TweenTime of this theme and remove it from the properties table to prevent property conflicts
    ThemeTweenDurationHolder = Properties.TweenTime
    Properties.TweenTime = nil

    --save the priority for later usage and remove it from the properties table to prevent property conflicts
    local Priority = Properties.Priority
    Properties.Priority = nil

    --play the thingamagic
    local Theme = Sounds.PlaySound(ID, Properties)
    
    --if it got correctly instanced, set all of the needed attributes
    if Theme then
        Theme:SetAttribute("Priority", Priority)
        Theme:SetAttribute("Volume", Properties.Volume)
        Theme:SetAttribute("ServerMade", RunService:IsServer())
    end

    --return the damn thing with `false` because it's brand new
    return Theme, false
end

--- Updates every theme currently playing based on their priorities to only play the one with most priority.
--- 
--- @return The top priority theme in this update cycle.
function Sounds.UpdateThemes(): Sound
    --get all existing themes in the folder
    local ExistingThemes = workspace.Themes:GetChildren()
    --if there are none, halt
    if #ExistingThemes <= 0 then
        return
    end

    --variable declaring
    local TopPriorityTheme
    local AvailableThemes = {}

    --iterate over every theme
    for _, Theme in ExistingThemes do
        --if it's getting destroyed, move on
        if Theme.Name:lower() == "destroying" then
            continue
        end

        --mark it as available
        table.insert(AvailableThemes, Theme)

        --if there's no top priority theme yet, or if this theme's priority is higher than the top one, replace the top one with the current one
        if not TopPriorityTheme or Theme:GetAttribute("Priority") > TopPriorityTheme:GetAttribute("Priority") then
            TopPriorityTheme = Theme
        end
    end

    --if there are no available themes or no theme with the top priority, halt
    if #AvailableThemes <= 0 or not TopPriorityTheme then
        return
    end

    --get the current tween duration for usage now and reset it
    local TweenDuration = ThemeTweenDurationHolder or 0.8
    ThemeTweenDurationHolder = nil

    --iterate over every theme to mute it if it's not the top priority one and make the latter heard
    for _, Theme in AvailableThemes do
        TweenService:Create(Theme, TweenInfo.new(TweenDuration), {
            Volume = Theme == TopPriorityTheme and (Theme:GetAttribute("Volume") or 0.5) or 0
        }):Play()
    end

    return TopPriorityTheme
end

--- If existent, stops the playing theme named after `ID`.
--- 
--- `FadeOut`, if specified, is the duration of the exit tween duration-
--- 
--- If `UpdateThemes` is `true`, it'll call `Sounds.UpdateThemes()` after.
--- 
--- @return The theme that's about to be destroyed.
function Sounds.StopTheme(ID: string, FadeOut: number?, UpdateThemes: boolean?): Sound
    --if the ID isn't a string on this one, halt
    if typeof(ID) ~= "string" then
        return
    end

    --defaults
    FadeOut = FadeOut or 0.8

    --if there's no theme named after ID, halt
    local ThemeToRemove = workspace.Themes:FindFirstChild(ID)
    if not ThemeToRemove then
        return
    end

    --rename to exclude in UpdateThemes()
    ThemeToRemove.Name = "Destroying"
    --just in case
    ThemeToRemove:SetAttribute("Priority", -999)
    --update themes if applicable
    if UpdateThemes then
        Sounds.UpdateThemes()
    end

    --fade it out
    TweenService:Create(ThemeToRemove, TweenInfo.new(FadeOut), {Volume = 0}):Play()
    --queue for deletion
    Debris:AddItem(ThemeToRemove, FadeOut + 0.1)

    --return the damn thing just in case
    return ThemeToRemove
end

return Sounds
