--!strict
local ServerStorage = game:GetService("ServerStorage")
local MaterialService = game:GetService("MaterialService")

local ORIGIN = Vector3.new(2500, 0, -2500)
local ONLY_THIS_MAP_IN_ROTATION = true

local Maps = ServerStorage:WaitForChild("Maps")
local moved = {}
if ONLY_THIS_MAP_IN_ROTATION then
	local Disabled = ServerStorage:FindFirstChild("MapsOff") or Instance.new("Folder")
	Disabled.Name = "MapsOff"
	Disabled.Parent = ServerStorage
	for _, map in Maps:GetChildren() do
		if map.Name ~= "Papelera" and (map:IsA("Folder") or map:IsA("Model")) then
			map.Parent = Disabled
			table.insert(moved, map.Name)
		end
	end
end
local previous = Maps:FindFirstChild("Papelera")
if previous then
	previous:Destroy()
end

local Root = Instance.new("Folder")
Root.Name = "Papelera"
local MapModel = Instance.new("Model")
MapModel.Name = "Map"
MapModel.Parent = Root

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local TerrainParts = folder("Terrain", MapModel)
folder("Buildings", MapModel)
folder("Yard", MapModel)
folder("Lamps", MapModel)
folder("Generators", MapModel)
folder("Details", MapModel)
local SpawnPoints = folder("SpawnPoints", MapModel)

for _, m in {
	{ "AnomalisLabTile", "CeramicTiles", "rbxassetid://81243399359695", "rbxassetid://93392214421283", "rbxassetid://109790649107314", "rbxassetid://87299537724194", "Regular" },
	{ "AnomalisRustMetal", "CorrodedMetal", "rbxassetid://92472211671271", "rbxassetid://103811817023703", "rbxassetid://81878616278695", "rbxassetid://114269752282446", "Organic" },
	{ "AnomalisConcrete", "Concrete", "rbxassetid://72409752443113", "rbxassetid://97656916839878", "rbxassetid://122561031610057", "rbxassetid://91752265013131", "Organic" },
	{ "AnomalisAsphalt", "Asphalt", "rbxassetid://115052350389321", "rbxassetid://126753607852078", "rbxassetid://117477470501608", "rbxassetid://139318763711632", "Organic" },
} do
	if not MaterialService:FindFirstChild(m[1], true) then
		local variant = Instance.new("MaterialVariant")
		variant.Name = m[1]
		variant.BaseMaterial = (Enum.Material :: any)[m[2]]
		variant.ColorMap, variant.NormalMap, variant.RoughnessMap, variant.MetalnessMap = m[3], m[4], m[5], m[6]
		variant.StudsPerTile = 10
		variant.MaterialPattern = (Enum.MaterialPattern :: any)[m[7]]
		variant.Parent = MaterialService
	end
end

local VARIANTS = {
	[Enum.Material.Concrete] = "AnomalisConcrete",
	[Enum.Material.CorrodedMetal] = "AnomalisRustMetal",
	[Enum.Material.Asphalt] = "AnomalisAsphalt",
	[Enum.Material.CeramicTiles] = "AnomalisLabTile",
}

local function part(parent: Instance, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material, name: string?): Part
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(ORIGIN + pos)
	p.Color = color
	p.Material = material
	p.MaterialVariant = VARIANTS[material] or ""
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local CONCRETE = Color3.fromRGB(86, 88, 94)

part(TerrainParts, Vector3.new(520, 1, 420), Vector3.new(0, -0.5, 0), Color3.fromRGB(70, 66, 58), Enum.Material.Asphalt, "Floor")

local function spawnPoint(parent: Instance, pos: Vector3)
	local p = part(parent, Vector3.new(1, 1, 1), pos + Vector3.new(0, 3, 0), CONCRETE, Enum.Material.SmoothPlastic, if parent.Name == "Killers" then "KillerSpawn" else "SurvivorSpawn")
	p.CFrame = CFrame.lookAt(ORIGIN + pos + Vector3.new(0, 3, 0), ORIGIN + Vector3.new(0, 3, 0))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end
for i, layout in { { survivors = Vector3.new(-60, 0, 195), killer = Vector3.new(90, 4, -20) }, { survivors = Vector3.new(-150, 0, 120), killer = Vector3.new(160, 4, -70) } } do
	local l = folder("Layout" .. i, SpawnPoints)
	local survivors, killers = folder("Survivors", l), folder("Killers", l)
	for _, offset in { Vector3.new(-4, 0, -4), Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4), Vector3.new(4, 0, 4) } do
		spawnPoint(survivors, layout.survivors + offset)
	end
	spawnPoint(killers, layout.killer)
end

local Config = Instance.new("ModuleScript")
Config.Name = "Config"
Config.Source = [[return {
	Ambience = "rbxassetid://95706527553140",
	AmbienceProperties = {
		Volume = 0.3,
	},
}]]
Config.Parent = Root

local LightingModule = Instance.new("ModuleScript")
LightingModule.Name = "Lighting"
LightingModule.Source = [[return {
	ClockTime = 20,
	GeographicLatitude = 55,
	Brightness = 1.4,
	Ambient = Color3.fromRGB(56, 58, 70),
	OutdoorAmbient = Color3.fromRGB(92, 98, 118),
	EnvironmentDiffuseScale = 0.3,
	EnvironmentSpecularScale = 1,
	GlobalShadows = true,
	ShadowSoftness = 0.25,
	ExposureCompensation = 0.05,
	ColorShift_Top = Color3.fromRGB(165, 172, 200),
	ColorShift_Bottom = Color3.fromRGB(18, 16, 24),
}]]
LightingModule.Parent = Root

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.12
atmosphere.Color = Color3.fromRGB(96, 102, 124)
atmosphere.Decay = Color3.fromRGB(30, 30, 44)
atmosphere.Glare = 0
atmosphere.Haze = 1.5
atmosphere.Parent = LightingModule

local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "Grade"
grade.Contrast = 0.14
grade.Brightness = grade.Contrast / 2
grade.Saturation = -0.18
grade.TintColor = Color3.fromRGB(240, 240, 252)
grade.Parent = LightingModule

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.55
bloom.Size = 28
bloom.Threshold = 1.25
bloom.Parent = LightingModule

local sky = Instance.new("Sky")
sky.StarCount = 1200
sky.CelestialBodiesShown = true
sky.MoonAngularSize = 16
sky.Parent = LightingModule

local Behaviour = Instance.new("ModuleScript")
Behaviour.Name = "Behaviour"
Behaviour.Source = [[--!strict
local RunService = game:GetService("RunService")

return {
	Init = function()
		if not RunService:IsClient() then
			return
		end
	end,
}]]
Behaviour.Parent = Root

Root.Parent = Maps
local _, size = MapModel:GetBoundingBox()
return "Papelera built: " .. #MapModel:GetDescendants() .. " instances, size " .. tostring(size) .. ", moved out of rotation: " .. (if #moved > 0 then table.concat(moved, ", ") else "none")
