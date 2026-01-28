local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)

local Hitmarker = {}

local HitmarkerPrefab = Utils.Instance.AwaitChild(script, "Hitmarker")
local HitmarkerFolder = workspace.TempObjectFolders.Hitmarkers

local HitmarkerValues = {
    SoundGroup = SoundService.SoundGroups.Master.UI,
    TweenInfo = {
        Appear = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        Disappear = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
    },
    FinalBillboardSize = UDim2.fromScale(0.7, 0.7),
}

type HitmarkerParameters = {
    --- The position in the 3D world where this hitmarker should be located at.
    Position: Vector3,
    --- The displayed text in the hitmarker.
    --- 
    --- If it's a `number`, it'll be floored with a 2 decimals margin (e.g. `7.987` would display as `7.98`).
    Display: string | number,
    --- If `true`, and if it's created in client, this hitmarker will reproduce the player's configured hitsound in its settings.
    --- 
    --- This won't work in server.
    PlaySound: boolean?,
}
--- Creates a new hitmarker instance and returns it for external usage.
--- 
--- FX and destroying will still be automatic.
function Hitmarker.New(Params: HitmarkerParameters): Part
    --play a sound by default
    if Params.PlaySound == nil then
        Params.PlaySound = true
    end

    --sound playing
    task.defer(function()
        --server wouldn't play global sounds because FUCK NO. NOT WASTING MEMORY IN THIS. REMOVE THIS SANITY CHECK IF YOU WANT TO.
        if RunService:IsServer() then
            return
        end

        --if the sound can't be played because it's set not to, halt
        if not Params.PlaySound then
            return
        end

        --try to fetch the sound id in the player's settings
        local SoundID = Utils.PlayerData.GetPlayerSetting(Players.LocalPlayer, "Miscellaneous.HitsoundID")
        --if it isn't there or it's not an id, halt
        if not SoundID or #SoundID <= 0 then
            return
        end

        --play the sound
        Sounds.PlaySound(SoundID, {SoundGroup = HitmarkerValues.SoundGroup})
    end)

    --take the display and guess that it's a string
    local Display = Params.Display
    --if it's not a string but rather a number, then floor it with a 2 decimal margin and use that
    if typeof(Display) == "number" then
        Display = tostring(math.floor(Display * 100) / 100)
    end

    --clone le prefab
    local HitmarkerInstance = HitmarkerPrefab:Clone()
    --get the text label separately for later use
    local HitmarkerText = HitmarkerInstance:FindFirstChildWhichIsA("TextLabel", true)
    --properties
    HitmarkerInstance.Position = Params.Position
    HitmarkerText.Text = Display
    HitmarkerInstance.Parent = HitmarkerFolder
    --add hitmarker to debris to automatically destroy it after 5 seconds and prevent errors if it's destroyed before those 5 seconds for any reason
    Debris:AddItem(HitmarkerInstance, 5)

    --tweening is low priority so just defer it
    task.defer(function()
        --small tween to add effect
        TweenService:Create(HitmarkerText, HitmarkerValues.TweenInfo.Appear, {Size = HitmarkerValues.FinalBillboardSize}):Play()
        --wait until there is one second left
        task.wait(4)
        --if the text has already been destroyed, halt
        if not HitmarkerText then
            return
        end
        --fade it out
        TweenService:Create(HitmarkerText, HitmarkerValues.TweenInfo.Disappear, {TextTransparency = 1}):Play()
    end)

    --return the damn thing for external usage
    return HitmarkerInstance
end

return Hitmarker
