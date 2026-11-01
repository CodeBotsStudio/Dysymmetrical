--!strict
local ServerStorage = game:GetService("ServerStorage")

local ORIGIN = Vector3.new(0, 0, -2500)
local WALL_THICKNESS = 1.5
local ONLY_THIS_MAP_IN_ROTATION = true

local Maps = ServerStorage:WaitForChild("Maps")
local moved = {}
if ONLY_THIS_MAP_IN_ROTATION then
	local Disabled = ServerStorage:FindFirstChild("MapsOff") or Instance.new("Folder")
	Disabled.Name = "MapsOff"
	Disabled.Parent = ServerStorage
	for _, map in Maps:GetChildren() do
		if map.Name ~= "Instalacion" and (map:IsA("Folder") or map:IsA("Model")) then
			map.Parent = Disabled
			table.insert(moved, map.Name)
		end
	end
end
local previous = Maps:FindFirstChild("Instalacion")
if previous then
	warn("[Instalacion] Rebuilding: anything dressed inside the old Instalacion map is replaced")
	previous:Destroy()
end

local Root = Instance.new("Folder")
Root.Name = "Instalacion"
local MapModel = Instance.new("Model")
MapModel.Name = "Map"
MapModel.Parent = Root

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local Building = folder("Building", MapModel)
local Yard = folder("Yard", MapModel)
local Lamps = folder("Lamps", MapModel)

local function part(parent: Instance, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material, name: string?): Part
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(ORIGIN + pos)
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local CONCRETE = Color3.fromRGB(86, 88, 94)
local DARK_CONCRETE = Color3.fromRGB(66, 68, 75)
local RUST = Color3.fromRGB(104, 58, 38)
local METAL = Color3.fromRGB(70, 74, 80)
local WOOD = Color3.fromRGB(92, 70, 48)

local function wall(parent: Instance, a: Vector2, b: Vector2, height: number, gaps: {{number}}?, color: Color3?)
	local alongX = a.Y == b.Y
	local from, to = if alongX then math.min(a.X, b.X) else math.min(a.Y, b.Y), if alongX then math.max(a.X, b.X) else math.max(a.Y, b.Y)
	local cuts = {}
	for _, gap in gaps or {} do
		table.insert(cuts, { gap[1] - gap[2] / 2, gap[1] + gap[2] / 2 })
	end
	table.sort(cuts, function(x, y) return x[1] < y[1] end)
	local start = from
	local function piece(s: number, e: number)
		if e - s < 0.1 then
			return
		end
		local mid, len = (s + e) / 2, e - s
		local size = if alongX then Vector3.new(len, height, WALL_THICKNESS) else Vector3.new(WALL_THICKNESS, height, len)
		local pos = if alongX then Vector3.new(mid, height / 2, a.Y) else Vector3.new(a.X, height / 2, mid)
		part(parent, size, pos, color or CONCRETE, Enum.Material.Concrete, "Wall")
	end
	for _, cut in cuts do
		piece(start, cut[1])
		start = cut[2]
	end
	piece(start, to)
end

local function room(container: Instance, name: string, center: Vector2, size: Vector2, height: number, gaps: {[string]: {{number}}})
	local parent = Instance.new("Model")
	parent.Name = name
	parent.Parent = container
	local x0, x1 = center.X - size.X / 2, center.X + size.X / 2
	local z0, z1 = center.Y - size.Y / 2, center.Y + size.Y / 2
	wall(parent, Vector2.new(x0, z0), Vector2.new(x1, z0), height, gaps.north)
	wall(parent, Vector2.new(x0, z1), Vector2.new(x1, z1), height, gaps.south)
	wall(parent, Vector2.new(x0, z0), Vector2.new(x0, z1), height, gaps.west)
	wall(parent, Vector2.new(x1, z0), Vector2.new(x1, z1), height, gaps.east)
	part(parent, Vector3.new(size.X + 2, 1, size.Y + 2), Vector3.new(center.X, height + 0.5, center.Y), METAL, Enum.Material.CorrodedMetal, "Roof")
	part(parent, Vector3.new(size.X, 0.2, size.Y), Vector3.new(center.X, 0.1, center.Y), DARK_CONCRETE, Enum.Material.Concrete, "Floor")
end

local function fillLight(parent: Instance, pos: Vector3)
	local anchor = part(parent, Vector3.new(0.2, 0.2, 0.2), pos, CONCRETE, Enum.Material.SmoothPlastic, "FillLight")
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	local light = Instance.new("PointLight")
	light.Range = 26
	light.Brightness = 0.9
	light.Color = Color3.fromRGB(150, 165, 205)
	light.Shadows = false
	light.Parent = anchor
end

local function lamp(parent: Instance, pos: Vector3, flicker: boolean, ceiling: boolean?, shadows: boolean?)
	local model = Instance.new("Model")
	model.Name = "Lamp"
	model.Parent = parent
	local headY = pos.Y
	if not ceiling then
		part(model, Vector3.new(0.6, pos.Y, 0.6), Vector3.new(pos.X, pos.Y / 2, pos.Z), METAL, Enum.Material.Metal, "Pole")
	end
	local head = part(model, Vector3.new(2.2, 0.5, 2.2), Vector3.new(pos.X, headY, pos.Z), Color3.fromRGB(255, 196, 140), Enum.Material.Neon, "Bulb")
	head.CastShadow = false
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 100
	spot.Range = if ceiling then 26 else 42
	spot.Brightness = 6
	spot.Color = Color3.fromRGB(255, 176, 110)
	spot.Shadows = shadows == true
	spot.Parent = head
	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Brightness = 1
	glow.Color = spot.Color
	glow.Parent = head
	if flicker then
		head:SetAttribute("Flicker", true)
	end
end

part(MapModel, Vector3.new(210, 2, 210), Vector3.new(0, -1, 0), Color3.fromRGB(74, 76, 82), Enum.Material.Asphalt, "Ground")

wall(Yard, Vector2.new(-100, -100), Vector2.new(100, -100), 20, nil, DARK_CONCRETE)
wall(Yard, Vector2.new(-100, 100), Vector2.new(100, 100), 20, nil, DARK_CONCRETE)
wall(Yard, Vector2.new(-100, -100), Vector2.new(-100, 100), 20, nil, DARK_CONCRETE)
wall(Yard, Vector2.new(100, -100), Vector2.new(100, 100), 20, nil, DARK_CONCRETE)
for _, side in { Vector3.new(0, 45, -101), Vector3.new(0, 45, 101), Vector3.new(-101, 45, 0), Vector3.new(101, 45, 0) } do
	local barrier = part(Yard, if side.X == 0 then Vector3.new(204, 50, 1) else Vector3.new(1, 50, 204), side, CONCRETE, Enum.Material.SmoothPlastic, "Barrier")
	barrier.Transparency = 1
end

room(Building, "MainBuilding", Vector2.new(0, 0), Vector2.new(60, 50), 14, {
	north = { { 0, 8 } },
	south = { { -15, 8 }, { 15, 8 } },
	west = { { 0, 8 } },
	east = { { 10, 8 } },
})
local InteriorWalls = Instance.new("Model")
InteriorWalls.Name = "InteriorWalls"
InteriorWalls.Parent = Building
wall(InteriorWalls, Vector2.new(-10, -25), Vector2.new(-10, 25), 14, { { -12, 6 }, { 12, 6 } })
wall(InteriorWalls, Vector2.new(10, -25), Vector2.new(10, 25), 14, { { -5, 6 }, { 18, 6 } })
wall(InteriorWalls, Vector2.new(10, 0), Vector2.new(30, 0), 14, { { 20, 6 } })
for _, p in { Vector3.new(0, 8, -32), Vector3.new(-15, 8, 32), Vector3.new(15, 8, 32), Vector3.new(-37, 8, 0), Vector3.new(37, 8, 10), Vector3.new(-70, 7, -55), Vector3.new(55, 7, 65) } do
	fillLight(Building, p)
end
for _, p in { Vector3.new(-20, 13.2, -12), Vector3.new(-20, 13.2, 12), Vector3.new(0, 13.2, -14), Vector3.new(0, 13.2, 14), Vector3.new(20, 13.2, -12), Vector3.new(20, 13.2, 12) } do
	lamp(Building, p, p.X == 0 and p.Z > 0 or p.X == 20 and p.Z < 0, true)
end

local Sheds = folder("Sheds", MapModel)
room(Sheds, "ShedNorthWest", Vector2.new(-70, -70), Vector2.new(24, 20), 10, { south = { { -70, 7 } }, east = { { -70, 6 } } })
room(Sheds, "ShedSouthEast", Vector2.new(70, 65), Vector2.new(20, 24), 10, { west = { { 65, 7 } }, north = { { 70, 6 } } })
lamp(Sheds, Vector3.new(-70, 9.2, -70), true, true)
lamp(Sheds, Vector3.new(70, 9.2, 65), false, true)

local function container(pos: Vector3, rotY: number, color: Color3)
	local c = part(Yard, Vector3.new(16, 8, 7), pos + Vector3.new(0, 4, 0), color, Enum.Material.CorrodedMetal, "Container")
	c.CFrame = CFrame.new(ORIGIN + pos + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(rotY), 0)
end
container(Vector3.new(55, 0, -40), 20, RUST)
container(Vector3.new(-65, 0, 35), 90, Color3.fromRGB(46, 66, 78))
container(Vector3.new(-35, 0, 80), 5, RUST)
container(Vector3.new(-35, 8, 80), 0, Color3.fromRGB(70, 74, 52))
container(Vector3.new(35, 0, -82), -10, Color3.fromRGB(46, 66, 78))
container(Vector3.new(82, 0, 15), 80, RUST)

for _, p in { Vector3.new(-45, 0, -45), Vector3.new(45, 0, 40), Vector3.new(-50, 0, 10), Vector3.new(30, 0, 60), Vector3.new(-20, 0, -60), Vector3.new(65, 0, -10) } do
	local barrier = part(Yard, Vector3.new(9, 3, 1.5), p + Vector3.new(0, 1.5, 0), CONCRETE, Enum.Material.Concrete, "JerseyBarrier")
	barrier.CFrame = CFrame.new(ORIGIN + p + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, math.rad((p.X * 7 + p.Z * 3) % 90), 0)
end

for _, p in { Vector3.new(-82, 0, -30), Vector3.new(48, 0, 82), Vector3.new(-12, 0, 52), Vector3.new(84, 0, -60) } do
	part(Yard, Vector3.new(4, 4, 4), p + Vector3.new(0, 2, 0), WOOD, Enum.Material.WoodPlanks, "Crate")
	part(Yard, Vector3.new(4, 4, 4), p + Vector3.new(4.2, 2, 0.5), WOOD, Enum.Material.WoodPlanks, "Crate")
	part(Yard, Vector3.new(4, 4, 4), p + Vector3.new(2, 6, 0.2), WOOD, Enum.Material.WoodPlanks, "Crate")
end

for i, p in { Vector3.new(-50, 12, -45), Vector3.new(50, 12, 45), Vector3.new(-50, 12, 45), Vector3.new(50, 12, -45), Vector3.new(0, 12, 70), Vector3.new(0, 12, -70), Vector3.new(-85, 12, 0), Vector3.new(85, 12, -30) } do
	lamp(Lamps, p, i % 3 == 0, false, i % 2 == 1)
end

local Generators = folder("Generators", MapModel)
local function generator(name: string, pos: Vector3, rotY: number)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = Generators
	local base = part(model, Vector3.new(5, 4, 3), Vector3.new(0, 2, 0), Color3.fromRGB(120, 104, 52), Enum.Material.DiamondPlate, "Base")
	part(model, Vector3.new(3.2, 2.2, 0.3), Vector3.new(0, 2.4, -1.6), Color3.fromRGB(30, 32, 36), Enum.Material.Metal, "Panel")
	part(model, Vector3.new(0.4, 2.5, 0.4), Vector3.new(1.8, 5.2, 0.8), METAL, Enum.Material.Metal, "Exhaust")
	local status = part(model, Vector3.new(0.8, 0.8, 0.8), Vector3.new(-1.6, 4.4, -1), Color3.fromRGB(200, 40, 30), Enum.Material.Neon, "Status")
	status.CastShadow = false
	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 1.5
	light.Color = status.Color
	light.Parent = status
	model.PrimaryPart = base
	model:PivotTo(CFrame.new(ORIGIN + pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(rotY), 0))
end
generator("WestRoom", Vector3.new(-22, 0, 16), 0)
generator("EastRoom", Vector3.new(22, 0, -16), 180)
generator("ShedNorthWest", Vector3.new(-73, 0, -74), 90)
generator("ShedSouthEast", Vector3.new(72, 0, 70), -90)
generator("Yard", Vector3.new(8, 0, 84), 0)

local Props = folder("ReactiveProps", MapModel)
local function looseProp(pos: Vector3, barrel: boolean)
	local size = if barrel then Vector3.new(2.6, 2, 2) else Vector3.new(2, 2, 2)
	local p = part(Props, size, pos + Vector3.new(0, size.Y / 2, 0), if barrel then RUST else WOOD, if barrel then Enum.Material.CorrodedMetal else Enum.Material.WoodPlanks, if barrel then "Barrel" else "Crate")
	if barrel then
		p.Shape = Enum.PartType.Cylinder
		p.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	end
	p.Anchored = false
	p:AddTag("Reactive")
end
for _, spot in {
	{Vector3.new(-26, 0, 12), false}, {Vector3.new(-25, 0, 20), true},
	{Vector3.new(26, 0, -12), true}, {Vector3.new(18, 0, -20), false},
	{Vector3.new(-69, 0, -78), false}, {Vector3.new(68, 0, 66), true},
	{Vector3.new(4, 0, 88), true}, {Vector3.new(13, 0, 80), false},
	{Vector3.new(-40, 0, 60), false}, {Vector3.new(45, 0, -55), true},
} do
	looseProp(spot[1], spot[2])
end

local SpawnPoints = folder("SpawnPoints", MapModel)
local function spawnPoint(parent: Instance, pos: Vector3)
	local p = part(parent, Vector3.new(1, 1, 1), pos + Vector3.new(0, 3, 0), CONCRETE, Enum.Material.SmoothPlastic, if parent.Name == "Killers" then "KillerSpawn" else "SurvivorSpawn")
	p.CFrame = CFrame.lookAt(ORIGIN + pos + Vector3.new(0, 3, 0), ORIGIN + Vector3.new(0, 3, 0))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end
for i, layout in { { survivors = Vector3.new(-80, 0, 80), killer = Vector3.new(80, 0, -80) }, { survivors = Vector3.new(80, 0, -80), killer = Vector3.new(-80, 0, 80) } } do
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
	ClockTime = 0.2,
	Brightness = 1.4,
	Ambient = Color3.fromRGB(80, 82, 102),
	OutdoorAmbient = Color3.fromRGB(100, 106, 136),
	EnvironmentDiffuseScale = 0.35,
	EnvironmentSpecularScale = 0.6,
	GlobalShadows = true,
	ShadowSoftness = 0.35,
	ExposureCompensation = 0.7,
	ColorShift_Top = Color3.fromRGB(0, 0, 0),
	ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
}]]
LightingModule.Parent = Root

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.05
atmosphere.Color = Color3.fromRGB(96, 104, 124)
atmosphere.Decay = Color3.fromRGB(36, 38, 52)
atmosphere.Glare = 0
atmosphere.Haze = 1
atmosphere.Parent = LightingModule

local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "Grade"
grade.Brightness = -0.02
grade.Contrast = 0.2
grade.Saturation = -0.35
grade.TintColor = Color3.fromRGB(214, 224, 255)
grade.Parent = LightingModule

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.7
bloom.Size = 28
bloom.Threshold = 1.4
bloom.Parent = LightingModule

local sky = Instance.new("Sky")
sky.StarCount = 1200
sky.CelestialBodiesShown = true
sky.Parent = LightingModule

local Behaviour = Instance.new("ModuleScript")
Behaviour.Name = "Behaviour"
Behaviour.Source = [[--!strict
local RunService = game:GetService("RunService")

local function flicker(bulb: BasePart)
	local lights = bulb:GetChildren()
	local rand = Random.new()
	local function set(on: boolean)
		bulb.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		for _, light in lights do
			if light:IsA("Light") then
				light.Enabled = on
			end
		end
	end
	while bulb:IsDescendantOf(workspace) do
		task.wait(rand:NextNumber(0.4, 4))
		for _ = 1, rand:NextInteger(1, 4) do
			set(false)
			task.wait(rand:NextNumber(0.03, 0.12))
			set(true)
			task.wait(rand:NextNumber(0.03, 0.2))
		end
	end
end

return {
	Init = function()
		if not RunService:IsClient() then
			return
		end
		for _, bulb in workspace:WaitForChild("Map"):GetDescendants() do
			if bulb:IsA("BasePart") and bulb:GetAttribute("Flicker") then
				task.spawn(flicker, bulb)
			end
		end
	end,
}]]
Behaviour.Parent = Root

Root.Parent = Maps
local _, size = MapModel:GetBoundingBox()
return "Instalacion built: " .. #MapModel:GetDescendants() .. " parts, size " .. tostring(size) .. ", moved out of rotation: " .. (if #moved > 0 then table.concat(moved, ", ") else "none")
