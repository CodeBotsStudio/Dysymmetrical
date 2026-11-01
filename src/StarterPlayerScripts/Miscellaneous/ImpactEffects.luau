--!strict
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer

local MAX_CHUNKS = 40
local MAX_MARKS = 24
local CULL_DISTANCE = 220
local MARK_LIFETIME = 10
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SPARKY = {
    [Enum.Material.Metal] = true,
    [Enum.Material.DiamondPlate] = true,
    [Enum.Material.CorrodedMetal] = true,
    [Enum.Material.Foil] = true,
}

local random = Random.new()
local folder = Instance.new("Folder")
folder.Name = "LocalImpacts"
local chunks: { BasePart } = {}
local marks: { BasePart } = {}

local function lowQuality(): boolean
    local quality = UserSettings().GameSettings.SavedQualityLevel
    return quality ~= Enum.SavedQualitySetting.Automatic and quality.Value <= 3
end

local function calmMode(): boolean
    return Utils.PlayerData.GetPlayerSetting(LocalPlayer, "Accessibility.EpilepsyMode") == true
end

local function track(list: { BasePart }, part: BasePart, limit: number)
    table.insert(list, part)
    if #list > limit then
        local oldest = table.remove(list, 1)
        if oldest then
            oldest:Destroy()
        end
    end
end

local function decor(size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
    local part = Instance.new("Part")
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Parent = folder
    return part
end

local function fadeOut(part: BasePart, after: number, duration: number)
    task.delay(after, function()
        if part.Parent then
            TweenService:Create(part, TweenInfo.new(duration), { Transparency = 1 }):Play()
            Debris:AddItem(part, duration)
        end
    end)
end

local function burst(position: Vector3, normal: Vector3, texture: string, color: Color3, amount: number, speed: number, size: number, glow: boolean)
    local anchor = decor(Vector3.one * 0.2, CFrame.lookAt(position, position + normal), color, Enum.Material.SmoothPlastic)
    anchor.Transparency = 1
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = texture
    emitter.Color = ColorSequence.new(color)
    emitter.EmissionDirection = Enum.NormalId.Front
    emitter.SpreadAngle = Vector2.new(60, 60)
    emitter.Speed = NumberRange.new(speed * 0.5, speed)
    emitter.Drag = 4
    emitter.Lifetime = NumberRange.new(0.4, 1)
    emitter.Size = NumberSequence.new(size * 0.4, size)
    emitter.Transparency = NumberSequence.new(0.35, 1)
    emitter.LightEmission = if glow then 1 else 0.2
    emitter.Brightness = if glow then 3 else 1.5
    emitter.Rate = 0
    emitter.Parent = anchor
    emitter:Emit(amount)
    Debris:AddItem(anchor, 1.5)
end

local function scatterChunks(position: Vector3, normal: Vector3, color: Color3, material: Enum.Material, count: number, strength: number)
    for _ = 1, count do
        local edge = random:NextNumber(0.2, 0.45) * (0.6 + strength)
        local chunk = decor(Vector3.one * edge, CFrame.new(position + normal * 0.4) * CFrame.Angles(random:NextNumber(0, 6.3), random:NextNumber(0, 6.3), 0), color, material)
        chunk.Anchored = false
        chunk.CanCollide = true
        chunk.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.5, 0.2)
        local spread = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-0.2, 1), random:NextNumber(-1, 1)) * 0.7
        chunk.AssemblyLinearVelocity = (normal + spread).Unit * random:NextNumber(12, 24) * strength
        track(chunks, chunk, MAX_CHUNKS)
        fadeOut(chunk, 2, 0.8)
    end
end

local function markSurface(kind: string, position: Vector3, normal: Vector3, color: Color3, strength: number)
    local base = CFrame.lookAt(position + normal * 0.03, position + normal * 2) * CFrame.Angles(0, 0, random:NextNumber(0, math.pi))
    local scarColor = if kind == "Shot" then color:Lerp(Color3.new(0, 0, 0), 0.75) else color:Lerp(Color3.fromRGB(215, 208, 196), 0.45)
    if kind == "Shot" then
        local hole = decor(Vector3.new(0.45, 0.45, 0.05), base, scarColor, Enum.Material.SmoothPlastic)
        track(marks, hole, MAX_MARKS)
        fadeOut(hole, MARK_LIFETIME, 2)
        return
    end
    local length = 2.5 + 3 * strength
    for offset = -1, 1 do
        local tilt = CFrame.Angles(0, 0, math.rad(random:NextNumber(-7, 7)))
        local scratch = decor(Vector3.new(0.13, length - math.abs(offset) * 0.7, 0.02), base * CFrame.new(offset * 0.5, 0, -0.02) * tilt, scarColor, Enum.Material.SmoothPlastic)
        track(marks, scratch, MAX_MARKS)
        fadeOut(scratch, MARK_LIFETIME, 2)
    end
end

local function hitStop(character: Model)
    local animator = character:FindFirstChildWhichIsA("Animator", true)
    if not animator then
        return
    end
    local paused = {}
    for _, track in animator:GetPlayingAnimationTracks() do
        paused[track] = track.Speed
        track:AdjustSpeed(0)
    end
    task.delay(0.07, function()
        for track, speed in paused do
            track:AdjustSpeed(speed)
        end
    end)
end

local function hurtFlash()
    local flash = Instance.new("ColorCorrectionEffect")
    flash.TintColor = Color3.fromRGB(255, 190, 180)
    flash.Brightness = 0.12
    flash.Parent = Lighting
    TweenService:Create(flash, TweenInfo.new(0.25), { TintColor = Color3.new(1, 1, 1), Brightness = 0 }):Play()
    Debris:AddItem(flash, 0.3)
end

local function onImpact(kind: string, position: Vector3, normal: Vector3, color: Color3, material: Enum.Material, strength: number, source: Player?, target: Model?, surfaceAnchored: boolean?)
    local camera = workspace.CurrentCamera
    if not camera or (camera.CFrame.Position - position).Magnitude > CULL_DISTANCE then
        return
    end
    local scale = if lowQuality() then 0.5 else 1
    local calm = calmMode()
    local dust = color:Lerp(Color3.fromRGB(205, 198, 186), 0.6)

    if kind == "Body" then
        burst(position, normal, SMOKE, dust, math.ceil(8 * scale), 6, 2.2, false)
        if target and target == LocalPlayer.Character and not calm then
            hurtFlash()
        end
    else
        if surfaceAnchored then
            markSurface(kind, position, normal, color, strength)
        end
        burst(position, normal, SMOKE, dust, math.ceil((if kind == "Shot" then 6 else 14) * scale), 9, 3 * strength + 1.2, false)
        if SPARKY[material] then
            burst(position, normal, SPARK, Color3.fromRGB(255, 190, 90), math.ceil(14 * scale), 26, 0.35, true)
        else
            scatterChunks(position, normal, color, material, math.ceil((if kind == "Shot" then 3 else 6) * strength * scale), strength)
        end
    end

    local character = LocalPlayer.Character
    if source == LocalPlayer and character and not calm then
        Utils.Player.ShakeCamera(0.35 * strength, 0.15)
        if kind == "Body" then
            hitStop(character)
        end
    end
end

return {
    Init = function(_)
        folder.Parent = workspace
        Network:SetConnection("Impact", "REMOTE_EVENT", onImpact)
    end,
}
