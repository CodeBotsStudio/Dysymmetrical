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

local HALF = Vector2.new(160, 140)
part(MapModel, Vector3.new(HALF.X * 2 + 20, 2, HALF.Y * 2 + 20), Vector3.new(0, -1, 0), Color3.fromRGB(74, 76, 82), Enum.Material.Asphalt, "Ground")

wall(Yard, Vector2.new(-HALF.X, -HALF.Y), Vector2.new(HALF.X, -HALF.Y), 20, nil, DARK_CONCRETE)
wall(Yard, Vector2.new(-HALF.X, HALF.Y), Vector2.new(HALF.X, HALF.Y), 20, { { 0, 18 } }, DARK_CONCRETE)
wall(Yard, Vector2.new(-HALF.X, -HALF.Y), Vector2.new(-HALF.X, HALF.Y), 20, nil, DARK_CONCRETE)
wall(Yard, Vector2.new(HALF.X, -HALF.Y), Vector2.new(HALF.X, HALF.Y), 20, nil, DARK_CONCRETE)
part(Yard, Vector3.new(18, 12, 0.6), Vector3.new(0, 6, HALF.Y), METAL, Enum.Material.DiamondPlate, "MainGate")
for _, side in { Vector3.new(0, 45, -HALF.Y - 1), Vector3.new(0, 45, HALF.Y + 1), Vector3.new(-HALF.X - 1, 45, 0), Vector3.new(HALF.X + 1, 45, 0) } do
	local barrier = part(Yard, if side.X == 0 then Vector3.new(HALF.X * 2 + 4, 50, 1) else Vector3.new(1, 50, HALF.Y * 2 + 4), side, CONCRETE, Enum.Material.SmoothPlastic, "Barrier")
	barrier.Transparency = 1
end

local Lab = folder("LabComplex", Building)
room(Lab, "Shell", Vector2.new(-35, -80), Vector2.new(150, 80), 16, {
	north = { { -85, 8 } },
	south = { { -95, 8 }, { -45, 12 }, { 15, 8 } },
	west = { { -80, 10 } },
	east = { { -80, 10 } },
})
wall(Lab, Vector2.new(-110, -85), Vector2.new(40, -85), 16, { { -85, 8 }, { -35, 10 }, { 15, 8 } })
wall(Lab, Vector2.new(-110, -75), Vector2.new(40, -75), 16, { { -92, 8 }, { -45, 12 }, { 12, 8 } })
wall(Lab, Vector2.new(-60, -120), Vector2.new(-60, -85), 16, { { -100, 7 } })
wall(Lab, Vector2.new(-10, -120), Vector2.new(-10, -85), 16, { { -110, 7 } })
wall(Lab, Vector2.new(-75, -75), Vector2.new(-75, -40), 16, { { -58, 7 } })
wall(Lab, Vector2.new(-15, -75), Vector2.new(-15, -40), 16, { { -50, 7 } })
local cell = Instance.new("Model")
cell.Name = "ContainmentCell"
cell.Parent = Lab
for _, side in { { Vector2.new(-43, -112), Vector2.new(-27, -112), nil }, { Vector2.new(-43, -98), Vector2.new(-27, -98), { { -35, 6 } } }, { Vector2.new(-43, -112), Vector2.new(-43, -98), nil }, { Vector2.new(-27, -112), Vector2.new(-27, -98), nil } } do
	wall(cell, side[1], side[2], 10, side[3], Color3.fromRGB(150, 190, 200))
end
for _, glass in cell:GetChildren() do
	if glass:IsA("BasePart") then
		glass.Material = Enum.Material.Glass
		glass.Transparency = 0.8
		glass.Color = Color3.fromRGB(190, 225, 235)
	end
end
local alarm = part(cell, Vector3.new(1.2, 1.2, 1.2), Vector3.new(-35, 10.6, -105), Color3.fromRGB(255, 40, 30), Enum.Material.Neon, "Alarm")
alarm.CastShadow = false
local alarmLight = Instance.new("PointLight")
alarmLight.Color = alarm.Color
alarmLight.Range = 24
alarmLight.Brightness = 2
alarmLight.Parent = alarm
for _, p in { Vector3.new(-85, 15.2, -102), Vector3.new(15, 15.2, -102), Vector3.new(-92, 15.2, -58), Vector3.new(-45, 15.2, -58), Vector3.new(12, 15.2, -58), Vector3.new(-80, 15.2, -80), Vector3.new(-20, 15.2, -80), Vector3.new(25, 15.2, -80) } do
	lamp(Lab, p, p.X == -20 or p.X == 15, true)
end

local Reactor = folder("ReactorHall", Building)
room(Reactor, "Shell", Vector2.new(105, -85), Vector2.new(90, 70), 22, {
	west = { { -80, 12 } },
	south = { { 85, 10 }, { 130, 8 } },
})
local core = part(Reactor, Vector3.new(18, 14, 14), Vector3.new(105, 9, -92), METAL, Enum.Material.DiamondPlate, "ReactorCore")
core.Shape = Enum.PartType.Cylinder
core.CFrame = CFrame.new(ORIGIN + Vector3.new(105, 9, -92)) * CFrame.Angles(0, 0, math.rad(90))
local ring = part(Reactor, Vector3.new(1, 15, 15), Vector3.new(105, 12, -92), Color3.fromRGB(70, 170, 255), Enum.Material.Neon, "CoreRing")
ring.Shape = Enum.PartType.Cylinder
ring.CFrame = CFrame.new(ORIGIN + Vector3.new(105, 12, -92)) * CFrame.Angles(0, 0, math.rad(90))
ring.CanCollide = false
local coreLight = Instance.new("PointLight")
coreLight.Color = ring.Color
coreLight.Range = 45
coreLight.Brightness = 2.2
for _, p in { Vector3.new(75, 10, -95), Vector3.new(135, 10, -95), Vector3.new(105, 10, -60) } do
	fillLight(Reactor, p)
end
coreLight.Parent = ring
local chimney = part(Reactor, Vector3.new(60, 9, 9), Vector3.new(100, 30, -131), DARK_CONCRETE, Enum.Material.Concrete, "Chimney")
chimney.Shape = Enum.PartType.Cylinder
chimney.CFrame = CFrame.new(ORIGIN + Vector3.new(100, 30, -131)) * CFrame.Angles(0, 0, math.rad(90))
local beacon = part(Reactor, Vector3.new(1.5, 1.5, 1.5), Vector3.new(100, 61, -131), Color3.fromRGB(255, 40, 30), Enum.Material.Neon, "Beacon")
beacon.CastShadow = false
beacon:SetAttribute("Flicker", true)
part(Reactor, Vector3.new(20, 1, 14), Vector3.new(50, 10.5, -80), METAL, Enum.Material.CorrodedMetal, "WalkwayRoof")
for _, p in { Vector3.new(80, 21.2, -70), Vector3.new(130, 21.2, -70), Vector3.new(80, 21.2, -105), Vector3.new(130, 21.2, -105) } do
	lamp(Reactor, p, p.X == 130 and p.Z == -105, true)
end

local Warehouse = folder("Warehouse", Building)
room(Warehouse, "Shell", Vector2.new(-110, 100), Vector2.new(80, 60), 18, {
	north = { { -125, 10 }, { -90, 14 } },
	east = { { 110, 8 } },
})
for _, z in { 85, 100, 115 } do
	wall(Warehouse, Vector2.new(-142, z), Vector2.new(-104, z), 9, { { -123, 5 } }, WOOD)
end
for _, p in { Vector3.new(-130, 17.2, 92), Vector3.new(-95, 17.2, 92), Vector3.new(-130, 17.2, 120), Vector3.new(-95, 17.2, 120) } do
	lamp(Warehouse, p, p.X == -130 and p.Z == 120, true)
end

local Barracks = folder("Barracks", Building)
for i, c in { Vector2.new(70, 90), Vector2.new(115, 90), Vector2.new(70, 122), Vector2.new(115, 122) } do
	local door = if c.Y < 100 then { north = { { c.X, 6 } }, south = { { c.X + 6, 6 } } } else { north = { { c.X - 5, 6 } }, east = { { c.Y, 6 } } }
	room(Barracks, "Hut" .. i, c, Vector2.new(24, 16), 10, door)
	lamp(Barracks, Vector3.new(c.X, 9.2, c.Y), i == 3, true)
end
room(Barracks, "GuardBooth", Vector2.new(24, 126), Vector2.new(12, 10), 9, { north = { { 24, 5 } }, west = { { 126, 4 } } })

local Loops = folder("Loops", Yard)
local function lshape(center: Vector3, rotY: number)
	local model = Instance.new("Model")
	model.Name = "LWall"
	model.Parent = Loops
	local long = part(model, Vector3.new(20, 8, WALL_THICKNESS), center + Vector3.new(0, 4, -6), CONCRETE, Enum.Material.Concrete, "Wall")
	part(model, Vector3.new(WALL_THICKNESS, 8, 10), center + Vector3.new(-9.25, 4, -0.25), CONCRETE, Enum.Material.Concrete, "Wall")
	part(model, Vector3.new(WALL_THICKNESS, 3, 4), center + Vector3.new(9.25, 1.5, -3.25), CONCRETE, Enum.Material.Concrete, "LowWall")
	model.PrimaryPart = long
	model:PivotTo(long.CFrame * CFrame.Angles(0, math.rad(rotY), 0))
end
for _, l in { { Vector3.new(-120, 0, 5), 0 }, { Vector3.new(60, 0, 0), 90 }, { Vector3.new(-60, 0, 45), 180 }, { Vector3.new(120, 0, 30), -90 }, { Vector3.new(5, 0, 60), 45 } } do
	lshape(l[1], l[2])
end
local function tshape(center: Vector3, rotY: number)
	local model = Instance.new("Model")
	model.Name = "TWall"
	model.Parent = Loops
	local bar = part(model, Vector3.new(22, 8, WALL_THICKNESS), center + Vector3.new(0, 4, -6), CONCRETE, Enum.Material.Concrete, "Wall")
	part(model, Vector3.new(WALL_THICKNESS, 8, 12), center + Vector3.new(0, 4, 0.5), CONCRETE, Enum.Material.Concrete, "Wall")
	model.PrimaryPart = bar
	model:PivotTo(bar.CFrame * CFrame.Angles(0, math.rad(rotY), 0))
end
tshape(Vector3.new(-25, 0, 82), 0)
tshape(Vector3.new(38, 0, 120), 90)
lshape(Vector3.new(-55, 0, 128), 0)

local tower = folder("WaterTower", Yard)
for _, o in { Vector3.new(-5, 0, -5), Vector3.new(5, 0, -5), Vector3.new(-5, 0, 5), Vector3.new(5, 0, 5) } do
	part(tower, Vector3.new(1.2, 30, 1.2), Vector3.new(-20, 15, 10) + o, METAL, Enum.Material.CorrodedMetal, "Leg")
end
local tank = part(tower, Vector3.new(12, 16, 16), Vector3.new(-20, 36, 10), RUST, Enum.Material.CorrodedMetal, "Tank")
tank.Shape = Enum.PartType.Cylinder
tank.CFrame = CFrame.new(ORIGIN + Vector3.new(-20, 36, 10)) * CFrame.Angles(0, 0, math.rad(90))

local function container(pos: Vector3, rotY: number, color: Color3)
	local c = part(Yard, Vector3.new(16, 8, 7), pos + Vector3.new(0, 4, 0), color, Enum.Material.CorrodedMetal, "Container")
	c.CFrame = CFrame.new(ORIGIN + pos + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(rotY), 0)
end
container(Vector3.new(-90, 0, -20), 20, RUST)
container(Vector3.new(-140, 0, 40), 90, Color3.fromRGB(46, 66, 78))
container(Vector3.new(30, 0, 25), 5, RUST)
container(Vector3.new(30, 8, 25), 0, Color3.fromRGB(70, 74, 52))
container(Vector3.new(95, 0, -25), -10, Color3.fromRGB(46, 66, 78))
container(Vector3.new(145, 0, 60), 80, RUST)
container(Vector3.new(-40, 0, 110), 90, Color3.fromRGB(70, 74, 52))
container(Vector3.new(48, 0, 70), 0, RUST)
container(Vector3.new(48, 0, 86), 0, Color3.fromRGB(46, 66, 78))

for _, p in { Vector3.new(-100, 0, 25), Vector3.new(80, 0, 40), Vector3.new(-30, 0, -20), Vector3.new(40, 0, -30), Vector3.new(-60, 0, 85), Vector3.new(20, 0, 95), Vector3.new(140, 0, -10), Vector3.new(-145, 0, -20) } do
	local barrier = part(Yard, Vector3.new(9, 3, 1.5), p + Vector3.new(0, 1.5, 0), CONCRETE, Enum.Material.Concrete, "JerseyBarrier")
	barrier.CFrame = CFrame.new(ORIGIN + p + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, math.rad((p.X * 7 + p.Z * 3) % 90), 0)
end

for _, p in { Vector3.new(-150, 0, -60), Vector3.new(146, 0, 125), Vector3.new(-12, 0, 130), Vector3.new(60, 0, 60) } do
	part(Yard, Vector3.new(4, 4, 4), p + Vector3.new(0, 2, 0), WOOD, Enum.Material.WoodPlanks, "Crate")
	part(Yard, Vector3.new(4, 4, 4), p + Vector3.new(4.2, 2, 0.5), WOOD, Enum.Material.WoodPlanks, "Crate")
	part(Yard, Vector3.new(4, 4, 4), p + Vector3.new(2, 6, 0.2), WOOD, Enum.Material.WoodPlanks, "Crate")
end

for i, p in { Vector3.new(-130, 12, -20), Vector3.new(-60, 12, -20), Vector3.new(10, 12, -25), Vector3.new(75, 12, -30), Vector3.new(140, 12, -30), Vector3.new(-120, 12, 55), Vector3.new(-50, 12, 70), Vector3.new(15, 12, 40), Vector3.new(90, 12, 60), Vector3.new(-10, 12, 115), Vector3.new(140, 12, 105), Vector3.new(-150, 12, -125) } do
	lamp(Lamps, p, i % 3 == 0, false, i % 3 == 1)
end
for _, p in { Vector3.new(-45, 8, -33), Vector3.new(-95, 8, -33), Vector3.new(15, 8, -33), Vector3.new(-117, 8, -80), Vector3.new(50, 8, -80), Vector3.new(85, 8, -43), Vector3.new(-90, 8, 63), Vector3.new(-125, 8, 63), Vector3.new(92, 8, 100) } do
	fillLight(Building, p)
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
generator("LabA", Vector3.new(-100, 0, -102), -90)
generator("Reactor", Vector3.new(85, 0, -70), 180)
generator("Warehouse", Vector3.new(-85, 0, 120), 0)
generator("Barracks", Vector3.new(92, 0, 106), 0)
generator("WaterTower", Vector3.new(-20, 0, 20), 180)

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
	{Vector3.new(-104, 0, -95), false}, {Vector3.new(-103, 0, -110), true},
	{Vector3.new(78, 0, -76), true}, {Vector3.new(92, 0, -76), false},
	{Vector3.new(-80, 0, 126), false}, {Vector3.new(-92, 0, 126), true},
	{Vector3.new(86, 0, 110), true}, {Vector3.new(98, 0, 112), false},
	{Vector3.new(-26, 0, 26), false}, {Vector3.new(-14, 0, 27), true},
	{Vector3.new(-45, 0, -80), true}, {Vector3.new(-5, 0, -80), false},
	{Vector3.new(-40, 0, -55), false}, {Vector3.new(130, 0, 70), true},
	{Vector3.new(-125, 0, 108), false}, {Vector3.new(25, 0, 112), true},
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
for i, layout in { { survivors = Vector3.new(-12, 0, 104), killer = Vector3.new(-35, 0, -105) }, { survivors = Vector3.new(-120, 0, 50), killer = Vector3.new(130, 0, -60) } } do
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
