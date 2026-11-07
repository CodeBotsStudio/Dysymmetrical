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
local Buildings = folder("Buildings", MapModel)
local Yard = folder("Yard", MapModel)
folder("Lamps", MapModel)
local Generators = folder("Generators", MapModel)
local Details = folder("Details", MapModel)
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
local WOOD = Color3.fromRGB(92, 70, 48)
local CRACK = Color3.fromRGB(22, 20, 20)
local CAP = Color3.fromRGB(128, 130, 134)
local RAMP = Color3.fromRGB(118, 104, 78)
local rng = Random.new(307)

local function detail(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p:AddTag("Detail")
	return p
end

local Outside = folder("Outside", MapModel)
local Terrain = workspace.Terrain
for material, color in {
	[Enum.Material.Asphalt] = Color3.fromRGB(56, 54, 52),
	[Enum.Material.Pavement] = Color3.fromRGB(40, 42, 48),
	[Enum.Material.Mud] = Color3.fromRGB(62, 50, 38),
	[Enum.Material.Ground] = Color3.fromRGB(66, 58, 44),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(48, 62, 40),
	[Enum.Material.Rock] = Color3.fromRGB(74, 74, 78),
	[Enum.Material.Sand] = Color3.fromRGB(150, 118, 78),
} do
	Terrain:SetMaterialColor(material, color)
end

local function smooth(points: { Vector2 }, step: number): { Vector2 }
	local out = {}
	for i = 1, #points - 1 do
		local p0, p1, p2, p3 = points[math.max(i - 1, 1)], points[i], points[i + 1], points[math.min(i + 2, #points)]
		local n = math.max(1, math.ceil((p2 - p1).Magnitude / step))
		for k = 0, n - 1 do
			local t = k / n
			table.insert(out, (p1 * 2 + (p2 - p0) * t + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t ^ 2 + (p1 * 3 - p0 - p2 * 3 + p3) * t ^ 3) * 0.5)
		end
	end
	table.insert(out, points[#points])
	return out
end

local NORTH_WALL = { Vector2.new(-264, -92), Vector2.new(-217, -89), Vector2.new(-170, -97), Vector2.new(-135, -92), Vector2.new(-100, -76), Vector2.new(-60, -80), Vector2.new(-20, -90), Vector2.new(20, -101), Vector2.new(60, -106), Vector2.new(95, -97), Vector2.new(130, -96), Vector2.new(160, -107), Vector2.new(190, -110), Vector2.new(227, -101), Vector2.new(264, -100) }
local CANAL = smooth({ Vector2.new(-264, 55), Vector2.new(-180, 64), Vector2.new(-120, 50), Vector2.new(-60, 22), Vector2.new(-20, 15), Vector2.new(40, 30), Vector2.new(100, 25), Vector2.new(180, 3), Vector2.new(264, 10) }, 20)
local TERRACE_RAMPS_X = { -150, 40 }
local CANAL_HALF = 12
local STACKS: { { number } } = { { -210, 100, 0 }, { -180, 25, 90 }, { -150, 100, 180 }, { -110, 165, 90 }, { -100, 0, 0 }, { -50, -15, 270 }, { -50, 60, 0 }, { 15, 80, 0 }, { -180, -75, 270 }, { 0, -15, 90 }, { 210, 35, 90 }, { 60, 65, 270 }, { -160, 165, 90 }, { -140, 20, 0 }, { 0, 150, 180 }, { 110, 55, 0 }, { -10, 50, 0 }, { -230, -70, 270 }, { 170, 40, 0 }, { -80, -160, 0 }, { 20, 115, 180 }, { -230, 25, 90 }, { -80, 180, 0 }, { -230, 140, 270 }, { -120, -60, 90 }, { 10, 185, 90 }, { 210, 180, 180 }, { -210, 180, 90 }, { 40, -185, 90 }, { -185, 120, 270 }, { -135, -145, 0 }, { -115, 100, 0 }, { -65, 90, 180 }, { 120, -185, 0 }, { -85, 145, 90 }, { -30, 135, 180 }, { -5, -160, 0 }, { -135, 120, 0, 1 }, { -160, -60, 180, 1 }, { -80, 65, 90, 1 }, { 30, 60, 0, 1 }, { 135, 55, 270, 1 }, { 215, -85, 0 }, { -240, 90, 0 }, { -205, 30, 180, 1 }, { -190, -110, 90 }, { -100, -25, 90, 1 }, { 25, -10, 180, 1 } }
local POZO = Vector3.new(120, 4, -45)
local POZO_RADIO = 30
local TERRAIN_SURFACE_LIFT = 2
local EDGE_BEHIND_WALL = 4
local WALL_THICK = 6

local function zAt(line: { Vector2 }, x: number): number
	for i = 2, #line do
		local a, b = line[i - 1], line[i]
		if x <= b.X then
			return a.Y + (b.Y - a.Y) * math.clamp((x - a.X) / (b.X - a.X), 0, 1)
		end
	end
	return line[#line].Y
end

local function heightAt(x: number, z: number): number
	return if z < zAt(NORTH_WALL, x) then 8 elseif z < zAt(CANAL, x) - CANAL_HALF then 4 else 0
end

local function along(line: { Vector2 }, s: number): (Vector2, Vector2)
	for i = 2, #line do
		local a, b = line[i - 1], line[i]
		local len = (b - a).Magnitude
		if s <= len or i == #line then
			return a + (b - a).Unit * s, (b - a).Unit
		end
		s -= len
	end
	return line[1], Vector2.xAxis
end

local function fill(x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, material: Enum.Material)
	if material ~= Enum.Material.Air then
		y1 -= TERRAIN_SURFACE_LIFT
	end
	if x1 > x0 and y1 > y0 and z1 > z0 then
		Terrain:FillBlock(CFrame.new(ORIGIN + Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)), Vector3.new(x1 - x0, y1 - y0, z1 - z0), material)
	end
end

fill(-480, 480, -12, 0, -480, 480, Enum.Material.LeafyGrass)
fill(-340, 340, -16, 120, -300, 300, Enum.Material.Air)
task.wait()
for x = -340, 336, 4 do
	local cx = x + 2
	local wallZ, canalZ = zAt(NORTH_WALL, cx), zAt(CANAL, cx)
	local edge = math.abs(cx) > 248
	local upper = if edge then Enum.Material.LeafyGrass else Enum.Material.Pavement
	local paved = if edge then Enum.Material.LeafyGrass else Enum.Material.Asphalt
	local southBand = 186 + 12 * math.noise(cx / 30, 0.7)
	local carve = CANAL_HALF + EDGE_BEHIND_WALL
	fill(x, x + 4, -12, 8, -300, wallZ - EDGE_BEHIND_WALL, upper)
	fill(x, x + 4, -12, 4, wallZ - EDGE_BEHIND_WALL, canalZ - carve, paved)
	fill(x, x + 4, -12, -4, canalZ - carve, canalZ + carve, Enum.Material.Mud)
	fill(x, x + 4, -12, 0, canalZ + carve, southBand, if edge then Enum.Material.Ground else Enum.Material.Mud)
	fill(x, x + 4, -12, 0, southBand, 300, if edge then Enum.Material.LeafyGrass else Enum.Material.Ground)
	local front = -206 - 7 * (math.noise(cx / 37, 1.3) + 0.5)
	local top = 50 + 16 * math.noise(cx / 53, 4.1)
	fill(x, x + 4, -12, top, -300, front, Enum.Material.Rock)
	fill(x, x + 4, top, top + 14, -300, front - 16, Enum.Material.Rock)
	if x % 64 == 0 then
		task.wait()
	end
end
for _, b in { -230, -150, -40, 70, 170, 240 } do
	Terrain:FillBall(ORIGIN + Vector3.new(b, 10, -216), 9 + rng:NextNumber() * 4, Enum.Material.Rock)
end

local bowlRadius = (POZO_RADIO ^ 2 + 9) / 6
local bowlCenter = POZO + Vector3.new(0, bowlRadius - 3, 0)
Terrain:FillBall(ORIGIN + bowlCenter - Vector3.new(0, TERRAIN_SURFACE_LIFT, 0), bowlRadius, Enum.Material.Air)
for _, m in { Vector2.new(-215, 120), Vector2.new(-135, 172), Vector2.new(-5, 128) } do
	Terrain:FillBall(ORIGIN + Vector3.new(m.X, -12 - TERRAIN_SURFACE_LIFT, m.Y), 16, Enum.Material.Sand)
	Terrain:FillBall(ORIGIN + Vector3.new(m.X + 9, -8 - TERRAIN_SURFACE_LIFT, m.Y + 6), 11, Enum.Material.Sand)
end
task.wait()

local function beam(parent: Instance, a: Vector2, b: Vector2, y0: number, y1: number, thickness: number, color: Color3, material: Enum.Material, name: string): Part
	local mid = (a + b) / 2
	local p = part(parent, Vector3.new(thickness, y1 - y0, (b - a).Magnitude), Vector3.new(mid.X, (y0 + y1) / 2, mid.Y), color, material, name)
	p.CFrame = CFrame.lookAt(p.Position, p.Position + Vector3.new(b.X - a.X, 0, b.Y - a.Y))
	return p
end

local function rod(parent: Instance, a: Vector2, b: Vector2, y: number, diameter: number, color: Color3, material: Enum.Material, name: string): Part
	local p = beam(parent, a, b, y, y + diameter, diameter, color, material, name)
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(p.Size.Z, diameter, diameter)
	p.CFrame *= CFrame.Angles(0, math.rad(90), 0)
	return p
end

local function woodTone(): Color3
	return WOOD:Lerp(Color3.fromRGB(60, 46, 34), rng:NextNumber())
end

local function wallLine(line: { Vector2 }, offset: number, y0: number, y1: number, gaps: { [number]: { number } }?)
	for i = 2, #line do
		local d = (line[i] - line[i - 1]).Unit
		local n = Vector2.new(-d.Y, d.X)
		local a, b = line[i - 1] + n * offset - d * 2, line[i] + n * offset + d * 2
		local function piece(from: Vector2, to: Vector2)
			beam(TerrainParts, from, to, y0, y1, WALL_THICK, CONCRETE, Enum.Material.Concrete, "Wall")
			beam(TerrainParts, from, to, y1, y1 + 0.3, WALL_THICK, CAP, Enum.Material.Concrete, "Cap")
		end
		local cut = gaps and gaps[i]
		if cut then
			piece(a, a + d * (cut[1] + 2))
			piece(a + d * (cut[2] + 2), b)
		else
			piece(a, b)
		end
	end
end

local function ramp(low: Vector3, high: Vector3, width: number): WedgePart
	local flat = Vector3.new(high.X - low.X, 0, high.Z - low.Z)
	local center = ORIGIN + (low + high) / 2
	local w = Instance.new("WedgePart")
	w.Name = "Ramp"
	w.Anchored = true
	w.Size = Vector3.new(width, high.Y - low.Y, flat.Magnitude)
	w.CFrame = CFrame.lookAt(center, center - flat)
	w.Color = RAMP
	w.Material = Enum.Material.Concrete
	w.MaterialVariant = "AnomalisConcrete"
	w:SetAttribute("Ramp", true)
	w:SetAttribute("Low", low)
	w.Parent = TerrainParts
	return w
end

local terraceGaps = {}
for _, x in TERRACE_RAMPS_X do
	for i = 2, #NORTH_WALL do
		local a, b = NORTH_WALL[i - 1], NORTH_WALL[i]
		if x >= a.X and x <= b.X then
			local d = (b - a).Unit
			local n = Vector2.new(-d.Y, d.X)
			local t = (x - a.X) / (b.X - a.X) * (b - a).Magnitude
			local p = a + d * t
			terraceGaps[i] = { t - 6.5, t + 6.5 }
			ramp(Vector3.new(p.X + n.X * 14, 4, p.Y + n.Y * 14), Vector3.new(p.X + n.X * 2, 8, p.Y + n.Y * 2), 12)
			local landing = part(TerrainParts, Vector3.new(12, 1, WALL_THICK + 2), Vector3.new(p.X - n.X * 2, 7.5, p.Y - n.Y * 2), CONCRETE, Enum.Material.Concrete, "Landing")
			landing.CFrame = CFrame.lookAt(landing.Position, landing.Position + Vector3.new(n.X, 0, n.Y))
		end
	end
end
wallLine(NORTH_WALL, -2, 2, 8, terraceGaps)
wallLine(CANAL, -(CANAL_HALF - 1 + WALL_THICK / 2), -6, 4)
wallLine(CANAL, CANAL_HALF - 1 + WALL_THICK / 2, -6, 0)

local canalLength = 0
for i = 2, #CANAL do
	local a, b = CANAL[i - 1], CANAL[i]
	canalLength += (b - a).Magnitude
	local d = (b - a).Unit
	local water = beam(TerrainParts, a - d * 7, b + d * 7, -3.9 + (i % 2) * 0.05, -3.5, 14, Color3.fromRGB(58, 72, 48), Enum.Material.SmoothPlastic, "Water")
	water.Transparency = 0.25
	water.Reflectance = 0.15
	water.CanCollide = false
	water.CanQuery = false
	local hazard = beam(TerrainParts, a - d, b + d, -4, 0.5, 22, CONCRETE, Enum.Material.SmoothPlastic, "CanalHazard")
	hazard.Transparency, hazard.CanCollide, hazard.CanQuery, hazard.CanTouch, hazard.CastShadow = 1, false, false, false, false
end
MapModel:SetAttribute("CanalLength", canalLength)
local EXITS_PER_BANK = 8
for bank, phase in { North = 0.5, South = 0.25 } do
	local side, rise, run = if bank == "North" then -1 else 1, if bank == "North" then 8 else 4, if bank == "North" then 18 else 10
	for i = 1, EXITS_PER_BANK do
		local s = (i - phase) * canalLength / EXITS_PER_BANK
		local c, d = along(CANAL, s)
		c += Vector2.new(-d.Y, d.X) * side * (CANAL_HALF - 4)
		local low, high = c - d * run / 2, c + d * run / 2
		local w = ramp(Vector3.new(low.X, -4, low.Y), Vector3.new(high.X, -4 + rise, high.Y), 6)
		w:SetAttribute("CanalExit", bank)
		w:SetAttribute("Arc", s)
	end
end

local function bowlY(d: number): number
	return bowlCenter.Y - math.sqrt(bowlRadius ^ 2 - d ^ 2)
end
local Pozo = folder("Pozo", TerrainParts)
Pozo:SetAttribute("Zone", "Pozo")
for i = 0, 8 do
	local angle = math.rad(i * 40 + rng:NextNumber() * 20)
	local d = 8 + (i % 3) * 7
	local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local pos = ORIGIN + Vector3.new(POZO.X, bowlY(d) - 0.1, POZO.Z) + radial * d
	local slope = math.atan(d / math.sqrt(bowlRadius ^ 2 - d ^ 2))
	local slab = part(Pozo, Vector3.new(10 + (i % 3) * 2, 0.8, 8), Vector3.zero, CONCRETE, Enum.Material.Concrete, "Slab")
	slab.CFrame = CFrame.lookAt(pos, pos + radial) * CFrame.Angles(slope + math.rad(rng:NextNumber(-4, 4)), 0, math.rad(rng:NextNumber(-4, 4)))
end
for i = 0, 3 do
	local angle = math.rad(20 + i * 90 + rng:NextNumber(-8, 8))
	local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local d = 19 + rng:NextNumber(0, 3)
	local base = ORIGIN + Vector3.new(POZO.X, bowlY(d) - 1.5, POZO.Z) + radial * d
	local slab = part(Pozo, Vector3.new(13, 12, 2.5), Vector3.zero, CONCRETE, Enum.Material.Concrete, "BigSlab")
	slab.CFrame = CFrame.lookAt(base, base + radial) * CFrame.Angles(-math.rad(rng:NextNumber(10, 20)), 0, math.rad(rng:NextNumber(-6, 6))) * CFrame.new(0, 6, 0)
end
for i = 0, 4 do
	if i ~= 2 then
		local plank = detail(part(Pozo, Vector3.new(10, 0.5, 1.8), Vector3.new(POZO.X, bowlY(0) + 0.4, POZO.Z - 4 + i * 2), WOOD, Enum.Material.WoodPlanks, "Plank"))
		plank.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), math.rad(rng:NextNumber(-8, 8)), 0)
	end
end
for _ = 1, 8 do
	local angle, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(6, 28)
	local chunk = detail(part(Pozo, Vector3.new(rng:NextNumber(1, 3), rng:NextNumber(0.6, 1.4), rng:NextNumber(1, 3)), Vector3.new(POZO.X + math.cos(angle) * d, bowlY(d) + 0.4, POZO.Z + math.sin(angle) * d), CONCRETE, Enum.Material.Concrete, "Rubble"))
	chunk.CFrame *= CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4))
end
for _, heading in { 115, 140, 165 } do
	local p = Vector2.new(POZO.X, POZO.Z) + Vector2.new(math.cos(math.rad(heading)), math.sin(math.rad(heading))) * POZO_RADIO
	local width = 1.4
	for _ = 1, 5 do
		local turn = math.rad(heading + rng:NextNumber(-25, 25))
		local q = p + Vector2.new(math.cos(turn), math.sin(turn)) * rng:NextNumber(6, 9)
		detail(beam(Pozo, p, q, 4.02, 4.1, width, CRACK, Enum.Material.Slate, "Crack"))
		p, width = q, width * 0.8
	end
end

for _, r in { { -253, -128, 20 }, { -244, -20, -15 }, { -244, 30, 10 }, { 250, -60, 160 }, { 250, 192, 200 }, { -120, 202, 80 }, { 150, 203, 100 } } do
	local x, z = r[1], r[2]
	local y = heightAt(x, z)
	for k = 0, 1 do
		local root = detail(part(TerrainParts, Vector3.new(24 - k * 8, 2.6 - k * 0.8, 2.6 - k * 0.8), Vector3.new(x, y + 0.5, z), Color3.fromRGB(70, 52, 38), Enum.Material.Wood, "Root"))
		root.Shape = Enum.PartType.Cylinder
		root.CFrame *= CFrame.Angles(0, math.rad(r[3] + k * 35), math.rad(6)) * CFrame.new(k * 6, 0, 0)
	end
	local lifted = detail(part(TerrainParts, Vector3.new(10, 0.8, 6), Vector3.new(x, y + 0.9, z), Color3.fromRGB(56, 54, 52), Enum.Material.Asphalt, "LiftedAsphalt"))
	lifted.CFrame *= CFrame.Angles(math.rad(12), math.rad(r[3] + 90), 0)
end

for _, side in {
	{ Vector2.new(-263, -212), Vector2.new(-265, -60), Vector2.new(-262, 90), Vector2.new(-264, 216) },
	{ Vector2.new(263, -212), Vector2.new(265, -20), Vector2.new(262, 120), Vector2.new(264, 216) },
	{ Vector2.new(-266, 214), Vector2.new(-90, 216), Vector2.new(60, 213), Vector2.new(266, 214) },
} do
	for i = 2, #side do
		local a, b = side[i - 1], side[i]
		local d = (b - a).Unit * 1.5
		for k = 0, 9 do
			local diameter = 3.2 + rng:NextNumber() * 0.5
			rod(Outside, a - d, b + d, -6 + k * 3.3, diameter, woodTone(), Enum.Material.Wood, "Log")
		end
	end
end
for _, b in { { Vector3.new(2, 140, 440), Vector3.new(-261, 60, 0) }, { Vector3.new(2, 140, 440), Vector3.new(261, 60, 0) }, { Vector3.new(540, 140, 2), Vector3.new(0, 60, 211) }, { Vector3.new(540, 140, 2), Vector3.new(0, 60, -206) } } do
	local bound = part(TerrainParts, b[1], b[2], CONCRETE, Enum.Material.SmoothPlastic, "Bound")
	bound.Transparency = 1
	bound.CanQuery = false
	bound.CastShadow = false
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { Terrain }
local function pine(x: number, z: number, h: number, tiers: number, shadows: boolean): Part
	local hit = workspace:Raycast(ORIGIN + Vector3.new(x, 200, z), Vector3.new(0, -260, 0), terrainOnly)
	local base = Vector3.new(x, if hit then hit.Position.Y - ORIGIN.Y - 1 else 0, z)
	local trunk = part(Outside, Vector3.new(h * 0.45, h * 0.07, h * 0.07), base + Vector3.new(0, h * 0.22, 0), Color3.fromRGB(46, 34, 26), Enum.Material.Wood, "Trunk")
	trunk.Shape = Enum.PartType.Cylinder
	trunk.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	trunk.CanCollide, trunk.CanQuery, trunk.CastShadow = false, false, shadows
	local spin = rng:NextNumber(0, 90)
	for tier = 0, tiers - 1 do
		local w, th = h * (0.5 - tier * 0.13), h * (0.42 - tier * 0.07)
		local center = ORIGIN + base + Vector3.new(0, h * (0.22 + tier * 0.22) + th / 2, 0)
		for q = 0, 3 do
			local leaf = Instance.new("CornerWedgePart")
			leaf.Name = "Needles"
			leaf.Anchored = true
			leaf.CanCollide, leaf.CanQuery, leaf.CanTouch, leaf.CastShadow = false, false, false, shadows
			leaf.Size = Vector3.new(w / 2, th, w / 2)
			leaf.CFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(spin + 90 * q), 0) * CFrame.new(-w / 4, 0, w / 4)
			leaf.Color = Color3.fromRGB(34, 50, 40):Lerp(Color3.fromRGB(52, 72, 56), tier / 2)
			leaf.Material = Enum.Material.Grass
			leaf.Parent = Outside
		end
	end
	return trunk
end
for _, t in { { -292, -150 }, { -300, -30 }, { -288, 70 }, { -296, 170 }, { 292, -140 }, { 300, 0 }, { 290, 130 }, { -200, 246 }, { -40, 250 }, { 120, 244 }, { 230, 256 }, { -150, -250 }, { 90, -245 } } do
	pine(t[1], t[2], rng:NextNumber(150, 190), 3, true)
end
for x = -416, 416, 64 do
	for z = -400, 400, 64 do
		local px, pz = x + rng:NextNumber(-20, 20), z + rng:NextNumber(-20, 20)
		if math.abs(px) > 300 or math.abs(pz) > 250 then
			pine(px, pz, rng:NextNumber(90, 130), 2, false)
		end
	end
end

local METAL = Color3.fromRGB(70, 72, 78)
local PAPER = Color3.fromRGB(196, 186, 164)
local CRANE = Color3.fromRGB(150, 120, 50)
local DOOR_H = 12
type Gaps = { [number]: { { number } } }

local function rot(c: Vector2, angle: number, p: Vector2): Vector2
	local a = math.rad(angle)
	return c + Vector2.new(p.X * math.cos(a) - p.Y * math.sin(a), p.X * math.sin(a) + p.Y * math.cos(a))
end

local function rect(c: Vector2, angle: number, w: number, d: number): { Vector2 }
	local out = {}
	for _, k in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(1, 1), Vector2.new(-1, 1) } do
		table.insert(out, rot(c, angle, k * Vector2.new(w, d) / 2))
	end
	return out
end

local function zone(name: string, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Zone", name)
	m.Parent = parent
	return m
end

local function walls(parent: Instance, poly: { Vector2 }, y: number, h: number, gaps: Gaps?)
	for i, a in poly do
		local b = poly[i % #poly + 1]
		local d = (b - a).Unit
		local from = -0.75
		for _, g in (gaps and gaps[i]) or {} do
			local t, w, top = g[1], g[2], math.min(g[3] or DOOR_H, h)
			beam(parent, a + d * from, a + d * (t - w / 2), y, y + h, 1.5, CONCRETE, Enum.Material.Concrete, "Wall")
			if top < h then
				beam(parent, a + d * (t - w / 2), a + d * (t + w / 2), y + top, y + h, 1.5, CONCRETE, Enum.Material.Concrete, "Lintel")
			end
			from = t + w / 2
		end
		beam(parent, a + d * from, b + d * 0.75, y, y + h, 1.5, CONCRETE, Enum.Material.Concrete, "Wall")
	end
end

local function slab(parent: Instance, c: Vector2, angle: number, w: number, d: number, top: number, name: string): Part
	local p = part(parent, Vector3.new(w, 1, d), Vector3.new(c.X, top - 0.5, c.Y), CONCRETE, Enum.Material.Concrete, name)
	p.CFrame *= CFrame.Angles(0, -math.rad(angle), 0)
	p:SetAttribute(if name == "Roof" then "Roof" else "Walk", true)
	return p
end

local function room(parent: Instance, c: Vector2, angle: number, w: number, d: number, y: number, h: number, gaps: Gaps): { Vector2 }
	local poly = rect(c, angle, w, d)
	walls(parent, poly, y, h, gaps)
	slab(parent, c, angle, w + 1.5, d + 1.5, y + h + 1, "Roof")
	return poly
end

local function block(parent: Instance, size: Vector3, x: number, y: number, z: number, angle: number?, color: Color3?, material: Enum.Material?, name: string?): Part
	local p = part(parent, size, Vector3.new(x, y + size.Y / 2, z), color or CONCRETE, material or Enum.Material.Concrete, name)
	p.CFrame *= CFrame.Angles(0, -math.rad(angle or 0), 0)
	return p
end

local function tank(parent: Instance, diameter: number, height: number, x: number, y: number, z: number, name: string?, color: Color3?, material: Enum.Material?): Part
	local p = part(parent, Vector3.new(height, diameter, diameter), Vector3.new(x, y + height / 2, z), color or METAL, material or Enum.Material.Metal, name or "Tank")
	p.Shape = Enum.PartType.Cylinder
	p.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	return p
end

local function pile(parent: Instance, c: Vector2, angle: number, length: number, y: number, layers: { number })
	for layer, count in layers do
		for k = 1, count do
			local v = (k - (count + 1) / 2) * 4
			rod(parent, rot(c, angle, Vector2.new(-length / 2, v)), rot(c, angle, Vector2.new(length / 2, v)), y + (layer - 1) * 3.4, 4, woodTone(), Enum.Material.Wood, "Log")
		end
	end
end

local function crates(parent: Instance, x: number, y: number, z: number, levels: number)
	for level = 0, levels - 1 do
		block(parent, Vector3.new(4.5, 4.5, 4.5), x, y + level * 4.5, z, rng:NextNumber(-15, 15), WOOD, Enum.Material.WoodPlanks, "Crate")
	end
end

local function lumber(parent: Instance, x: number, y: number, z: number, angle: number)
	block(parent, Vector3.new(14, 7, 6), x, y, z, angle, Color3.fromRGB(150, 120, 84), Enum.Material.WoodPlanks, "Lumber")
end

local function bales(parent: Instance, x: number, y: number, z: number)
	for i = 0, 7 do
		block(parent, Vector3.new(5.8, 4.9, 5.8), x + (i % 2 - 0.5) * 6, y + (i // 4) * 5, z + (i // 2 % 2 - 0.5) * 6, rng:NextNumber(-4, 4), PAPER, Enum.Material.Fabric, "Bale")
	end
end

local function stack(parent: Instance, x: number, z: number, angle: number, logs: boolean, low: boolean)
	local c, y = Vector2.new(x, z), heightAt(x, z)
	local function at(u: number, v: number): Vector2
		return rot(c, angle, Vector2.new(u, v))
	end
	local box = at(if logs then 4.5 else 3.5, if logs then 6 else 0)
	crates(parent, box.X, y, box.Y, if low then 1 else 2)
	if logs then
		pile(parent, at(-2, -1), angle + 90, 18, y, if low then { 2, 1 } else { 2, 2, 1 })
		return
	end
	local a, b = at(0, -7), at(-4, 3)
	lumber(parent, a.X, y, a.Y, angle)
	if not low then
		lumber(parent, a.X, y + 7, a.Y, angle + rng:NextNumber(-4, 4))
	end
	lumber(parent, b.X, y, b.Y, angle + 90)
end

local function truck(parent: Instance, c: Vector2, angle: number, y: number, logs: boolean)
	local cab, bed = rot(c, angle, Vector2.new(15, 0)), rot(c, angle, Vector2.new(-2, 0))
	block(parent, Vector3.new(8, 9, 8), cab.X, y, cab.Y, angle, METAL, Enum.Material.Metal, "TruckCab")
	block(parent, Vector3.new(24, 4, 8), bed.X, y, bed.Y, angle, METAL, Enum.Material.Metal, "TruckBed")
	if logs then
		pile(parent, bed, angle, 22, y + 4, { 2, 1 })
	else
		block(parent, Vector3.new(22, 8, 8), bed.X, y + 4, bed.Y, angle, METAL, Enum.Material.CorrodedMetal, "TruckBox")
	end
end

local function panel(parent: Instance, poly: { Vector2 }, i: number, t: number, w: number, y: number, h: number, name: string): (Part, Vector3)
	local a, b = poly[i], poly[i % #poly + 1]
	local d = (b - a).Unit
	return beam(parent, a + d * (t - w / 2), a + d * (t + w / 2), y, y + h, 0.4, METAL, Enum.Material.DiamondPlate, name), Vector3.new(d.Y, 0, -d.X)
end

local function fireExit(parent: Instance, poly: { Vector2 }, i: number, t: number, y: number)
	local m = Instance.new("Model")
	m.Name = "FireExit"
	local door, out = panel(m, poly, i, t, 6, y, 8, "Panel")
	m.PrimaryPart = door
	m:SetAttribute("OneWayDoor", true)
	m:SetAttribute("OpenDirection", out)
	m.Parent = parent
end

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

local function sign(text: string, pos: Vector3, face: Enum.NormalId, color: Color3)
	local s = detail(part(Details, Vector3.new(#text * 0.8 + 2, 2.4, 0.2), pos, Color3.fromRGB(28, 30, 34), Enum.Material.Metal, "Sign"))
	s:RemoveTag("Detail")
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	gui.Parent = s
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.Parent = gui
end

local function crossing(x: number, isLog: boolean)
	local c = Vector2.new(x, zAt(CANAL, x))
	local d = Vector2.new(2, zAt(CANAL, x + 1) - zAt(CANAL, x - 1)).Unit
	local n = Vector2.new(-d.Y, d.X)
	local width = if isLog then 4 else 8
	local function at(t: number, y: number): Vector3
		local p = c + n * t
		return Vector3.new(p.X, y, p.Y)
	end
	local deck = beam(TerrainParts, c - n * 22, c + n * 18, 3.5, 4.5, width, METAL, Enum.Material.DiamondPlate, "Deck")
	deck:SetAttribute("Walk", true)
	for _, w in { ramp(at(-26, 4), at(-22, 4.5), width), ramp(at(30, 0), at(18, 4.5), width) } do
		if isLog then
			w.Color, w.Material, w.MaterialVariant = WOOD, Enum.Material.Wood, ""
		end
	end
	if isLog then
		deck.Transparency = 1
		detail(rod(TerrainParts, c - n * 24, c + n * 24, 0.5, 4, woodTone(), Enum.Material.Wood, "FallenLog"))
	else
		for _, side in { -1, 1 } do
			beam(TerrainParts, c - n * 22 + d * side * 3.8, c + n * 18 + d * side * 3.8, 4.5, 7.5, 0.4, METAL, Enum.Material.Metal, "Rail")
		end
	end
end
crossing(-190, false)
crossing(140, false)
crossing(20, true)

local Nave = zone("Nave", Buildings)
local navePoly = { Vector2.new(-245, -195), Vector2.new(-155, -195), Vector2.new(-155, -155), Vector2.new(-205, -155), Vector2.new(-205, -110), Vector2.new(-245, -110) }
walls(Nave, navePoly, 8, 22, { [2] = { { 20, 12 } }, [3] = { { 25, 6, 8 } }, [4] = { { 25, 12 } }, [5] = { { 20, 12 } }, [6] = { { 55, 6, 8 } } })
slab(Nave, Vector2.new(-200, -175), 0, 91.5, 41.5, 31, "Roof")
slab(Nave, Vector2.new(-225, -131.75), 0, 41.5, 45, 31, "Roof")
fireExit(Nave, navePoly, 6, 55, 8)
for _, v in { Vector2.new(-225, -173), Vector2.new(-195, -178), Vector2.new(-225, -125) } do
	tank(Nave, 14, 16, v.X, 8, v.Y, "Vat")
end
detail(beam(Nave, Vector2.new(-225, -173), Vector2.new(-195, -178), 19, 20.5, 1.5, METAL, Enum.Material.Metal, "Pipe"))
detail(beam(Nave, Vector2.new(-225, -173), Vector2.new(-225, -125), 21, 22.5, 1.5, METAL, Enum.Material.Metal, "Pipe"))
generator("NaveA", Vector3.new(-170, 8, -178), 90)
generator("NaveB", Vector3.new(-212, 8, -143), 0)

local Oficinas = zone("Oficinas", Buildings)
local oficinasPoly = room(Oficinas, Vector2.new(195, -182), 0, 50, 36, 8, 18, { [2] = { { 8, 6, 7 } }, [3] = { { 25, 6, 7 } }, [4] = { { 26, 6, 7 } } })
local killerDoor = panel(Oficinas, oficinasPoly, 4, 26, 6, 8, 7, "KillerDoor")
killerDoor.CollisionGroup = "KillerPassthrough"
killerDoor.Color = Color3.fromRGB(96, 36, 34)
killerDoor:SetAttribute("KillerDoor", true)
slab(Oficinas, Vector2.new(195, -192), 0, 48.5, 16, 17, "Floor")
for _, r in { { 170, 174 }, { 180, 210 }, { 216, 220 } } do
	beam(Oficinas, Vector2.new(r[1], -184.2), Vector2.new(r[2], -184.2), 17, 20, 0.4, METAL, Enum.Material.Metal, "Rail")
end
for _, x in { 177, 213 } do
	ramp(Vector3.new(x, 8, -166), Vector3.new(x, 17, -184), 6)
end
generator("Oficinas", Vector3.new(195, 17, -194), 180)
walls(Oficinas, rect(Vector2.new(195, -193), 0, 20, 14), 8, 8, { [2] = { { 9, 4, 7 } }, [3] = { { 5, 4, 7 }, { 15, 4, 7 } }, [4] = { { 5, 4, 7 } } })
for _, z in { { -200, -193 }, { -189, -186 } } do
	beam(Oficinas, Vector2.new(195, z[1]), Vector2.new(195, z[2]), 8, 16, 1, CONCRETE, Enum.Material.Concrete, "Partition")
end

local Chimenea = zone("Pozo", Buildings)
block(Chimenea, Vector3.new(12, 150, 12), 150, 8, -122, 0, CONCRETE, Enum.Material.Brick, "Chimney")
room(Chimenea, Vector2.new(126, -139), 0, 28, 22, 8, 14, { [2] = { { 11, 6, 7 } }, [3] = { { 14, 12 } }, [4] = { { 11, 6, 7 } } })
tank(Chimenea, 10, 10, 126, 8, -139, "Boiler")
room(Chimenea, Vector2.new(215, -57), 0, 30, 24, 4, 12, { [1] = { { 15, 6, 7 } }, [3] = { { 15, 12 } }, [4] = { { 12, 6, 7 } } })
tank(Chimenea, 10, 14, 196, 4, -88)
tank(Chimenea, 10, 14, 248, 4, -24)
generator("Pozo", Vector3.new(182, 4, -28), -30)
room(Chimenea, Vector2.new(178, -78), 0, 12, 10, 4, 9, { [2] = { { 5, 6, 7 } }, [4] = { { 5, 6, 7 } } })
block(Chimenea, Vector3.new(8, 8, 6), 160, 4, -22, 0, METAL, Enum.Material.Metal, "Transformer")
block(Chimenea, Vector3.new(6, 7, 6), 205, 4, -24, 0, METAL, Enum.Material.Metal, "Valves")

local Rodillos = zone("Rodillos", Buildings)
local RC = Vector2.new(40, -55)
local function R(s: number, v: number, y: number): Vector3
	local p = rot(RC, 13, Vector2.new(s, v))
	return Vector3.new(p.X, y, p.Y)
end
local function R2(s: number, v: number): Vector2
	local p = R(s, v, 0)
	return Vector2.new(p.X, p.Z)
end
room(Rodillos, R2(-2.5, 0), 13, 105, 26, 4, 20, { [1] = { { 45, 6, 7 }, { 95, 12 } }, [2] = { { 15.5, 21, 99 } }, [3] = { { 30, 12 } }, [4] = { { 13, 12 } } })
for _, seg in { { -45, -25 }, { -17, 3 }, { 11, 26 }, { 34, 44 } } do
	beam(Rodillos, R2(seg[1], 0), R2(seg[2], 0), 4, 11, 8, METAL, Enum.Material.Metal, "Machine")
	for s = seg[1] + 2, seg[2] - 2, 5 do
		detail(rod(Rodillos, R2(s, -4.5), R2(s, 4.5), 11, 2.4, CAP, Enum.Material.Metal, "Roller"))
	end
end
for _, w in { beam(Rodillos, R2(-20, 10.5), R2(62, 10.5), 13, 14, 4, METAL, Enum.Material.DiamondPlate, "Catwalk"), beam(Rodillos, R2(7, -12.5), R2(7, 8.5), 13, 14, 8, METAL, Enum.Material.DiamondPlate, "Catwalk") } do
	w:SetAttribute("Walk", true)
end
for _, r in { { -20, 3 }, { 11, 50 } } do
	beam(Rodillos, R2(r[1], 8.7), R2(r[2], 8.7), 14, 17, 0.4, METAL, Enum.Material.Metal, "Rail")
end
ramp(R(-40, 10.5, 4), R(-20, 10.5, 14), 4)
ramp(R(31, -10.5, 4), R(11, -10.5, 14), 4)
generator("Rodillos", R(4.6, -1.5, 4), 257)

local Patio = zone("Patio", Yard)
for _, x in { -200, -180, -160, -140 } do
	for _, z in { -45, -15 } do
		block(Patio, Vector3.new(1.5, 16, 1.5), x, 4, z, 0, WOOD, Enum.Material.Wood, "Post")
	end
end
slab(Patio, Vector2.new(-170, -30), 0, 64, 34, 21, "Roof")
beam(Patio, Vector2.new(-200, -45), Vector2.new(-168, -45), 4, 20, 1, WOOD, Enum.Material.WoodPlanks, "Wall")
block(Patio, Vector3.new(32, 3.5, 5), -170, 4, -34, 0, METAL, Enum.Material.Metal, "SawTable")
detail(rod(Patio, Vector2.new(-165, -34.3), Vector2.new(-165, -33.7), 5, 9, CAP, Enum.Material.Metal, "Saw"))
pile(Patio, Vector2.new(-170, -23), 0, 26, 4, { 3, 2 })
pile(Patio, Vector2.new(-225, 160), 0, 30, 0, { 2, 2, 1 })
pile(Patio, Vector2.new(-95, 100), 90, 30, 0, { 2, 2, 1 })
pile(Patio, Vector2.new(-45, 160), 20, 30, 0, { 2, 2, 1 })
for _, x in { -105, -85 } do
	for _, z in { 78, 128 } do
		block(Patio, Vector3.new(2, 26, 2), x, 0, z, 0, CRANE, Enum.Material.Metal, "CraneLeg")
	end
	beam(Patio, Vector2.new(x, 77), Vector2.new(x, 129), 26, 28, 2, CRANE, Enum.Material.Metal, "CraneRail")
end
beam(Patio, Vector2.new(-106, 103), Vector2.new(-84, 103), 26.5, 29, 3, CRANE, Enum.Material.Metal, "CraneBridge")
detail(block(Patio, Vector3.new(0.3, 9, 0.3), -95, 17.5, 103, 0, METAL, Enum.Material.Metal, "Cable"))
detail(block(Patio, Vector3.new(3, 2, 3), -95, 15.5, 103, 0, METAL, Enum.Material.Metal, "Hook"))
truck(Patio, Vector2.new(-172, 140), 180, 0, true)
truck(Patio, Vector2.new(-20, 95), 90, 0, true)
for i = 0, 7 do
	local x = -138 + i * 16
	local z = -32 - (i * 16 + 2) * 30 / 114
	block(Patio, Vector3.new(1.2, 8, 1.2), x, 4, z, 0, METAL, Enum.Material.Metal, "ConveyorPost")
end
beam(Patio, Vector2.new(-140, -31.5), Vector2.new(-24, -62), 12, 13, 3, METAL, Enum.Material.DiamondPlate, "Conveyor")
detail(rod(Patio, Vector2.new(-228, -27), Vector2.new(-228, 7), 5, 10, METAL, Enum.Material.CorrodedMetal, "Debarker")).CanQuery = true
for _, z in { -20, 0 } do
	block(Patio, Vector3.new(12, 3, 3), -228, 4, z, 0, CONCRETE, Enum.Material.Concrete, "Cradle")
end
truck(Patio, Vector2.new(55, -12), 0, 4, true)
for i, s in STACKS do
	stack(Yard, s[1], s[2], s[3], i % 2 == 0, s[4] == 1)
end
for _, t in { { -234, 116 }, { -174, -88 }, { -144, 184 }, { 49, -76 }, { 148, -20 } } do
	tank(Yard, 8, 12, t[1], heightAt(t[1], t[2]), t[2])
end
block(Patio, Vector3.new(10, 8, 8), -50, 0, 115, 30, METAL, Enum.Material.Metal, "Chipper")
detail(tank(Patio, 7, 5, -50, 8, 115, "Hopper"))
tank(Patio, 8, 10, 100, 4, -6)
room(Patio, Vector2.new(-20, 185), 0, 14, 12, 0, 10, { [2] = { { 6, 6, 7 } }, [4] = { { 6, 6, 7 } } })
for _, x in { -72, -48 } do
	block(Patio, Vector3.new(4, 18, 4), x, 0, 206, 0, CONCRETE, Enum.Material.Concrete, "GatePost")
end
for x = -69, -51, 2 do
	block(Patio, Vector3.new(0.4, 14, 0.4), x, 0, 206, 0, METAL, Enum.Material.Metal, "GateBar")
end
sign("LA PAPELERA DEL BOSQUE", Vector3.new(-60, 16, 205.5), Enum.NormalId.Front, Color3.fromRGB(214, 190, 140))
generator("Patio", Vector3.new(-128, 0, 140), 0)

local Bosquecillo = zone("Bosquecillo", Yard)
for _, t in { { 55, 90, 118 }, { 85, 130, 132 }, { 60, 170, 124 }, { 100, 185, 140 }, { 105, 85, 112 } } do
	local trunk = pine(t[1], t[2], t[3], 3, true)
	trunk.CanCollide, trunk.CanQuery, trunk.Parent = true, true, Bosquecillo
end
for _, t in { { 80, 105, 70 }, { 66, 118, 64 }, { 92, 158, 58 }, { 35, 190, 60 } } do
	local trunk = pine(t[1], t[2], t[3], 2, false)
	trunk.CanCollide, trunk.CanQuery, trunk.Parent = true, true, Bosquecillo
end
rod(Bosquecillo, Vector2.new(28, 140), Vector2.new(58, 150), 0, 6.5, woodTone(), Enum.Material.Wood, "FallenLog")
rod(Bosquecillo, Vector2.new(112, 122), Vector2.new(118, 152), 0, 6.5, woodTone(), Enum.Material.Wood, "FallenLog")
generator("Bosquecillo", Vector3.new(80, 0, 160), 40)

local Almacen = zone("Almacen", Buildings)
local AC, AA = Vector2.new(185, 125), -12
local function A(u: number, v: number): Vector2
	return rot(AC, AA, Vector2.new(u, v))
end
local almacenPoly = room(Almacen, AC, AA, 110, 70, 0, 18, { [1] = { { 55, 12 } }, [2] = { { 45, 6, 8 } }, [3] = { { 30, 12 } }, [4] = { { 35, 12 } } })
fireExit(Almacen, almacenPoly, 2, 45, 0)
for _, side in { -1, 1 } do
	local c = A(side * 23, -40.75)
	block(Almacen, Vector3.new(34, 4, 10), c.X, 0, c.Y, AA, CONCRETE, Enum.Material.Concrete, "Dock"):SetAttribute("Walk", true)
	local low, high = A(side * 52, -40.75), A(side * 40, -40.75)
	ramp(Vector3.new(low.X, 0, low.Y), Vector3.new(high.X, 4, high.Y), 10)
	detail(beam(Almacen, A(side * 16, -35.9), A(side * 30, -35.9), 4, 14, 0.3, METAL, Enum.Material.CorrodedMetal, "Shutter"))
end
for _, cell in { { -40, -22 }, { -28, -22 }, { -40, -10 }, { -6, -4 }, { 6, -4 }, { 18, -4 }, { 6, 8 }, { 40, -22 }, { 40, -10 }, { 28, -22 }, { -40, 22 }, { -28, 22 }, { -16, 22 }, { -28, 10 } } do
	for _, o in { Vector2.new(-3, -3), Vector2.new(3, -3), Vector2.new(-3, 3), Vector2.new(3, 3) } do
		local p = A(cell[1] + o.X, cell[2] + o.Y)
		for layer = 0, 1 do
			tank(Almacen, 5.8, 5.9, p.X, layer * 6, p.Y, "Bobbin", PAPER, Enum.Material.SmoothPlastic)
		end
	end
end
local dockTruck = A(-18, -55)
truck(Almacen, dockTruck, AA, 0, false)
for _, c in { { 28, -52, 2 }, { 34, -49, 1 } } do
	local p = A(c[1], c[2])
	crates(Almacen, p.X, 0, p.Y, c[3])
end
local almacenGen = A(38, 20)
generator("Almacen", Vector3.new(almacenGen.X, 0, almacenGen.Y), -AA)

tank(Yard, 12, 18, -120, 8, -170)
tank(Yard, 10, 16, -70, 8, -185)
tank(Yard, 12, 18, 95, 8, -180)
room(Yard, Vector2.new(-95, -122), 0, 16, 12, 8, 10, { [3] = { { 8, 6, 7 } } })
room(Yard, Vector2.new(25, -160), 0, 20, 14, 8, 10, { [2] = { { 7, 6, 7 } }, [4] = { { 7, 6, 7 } } })
pile(Yard, Vector2.new(-35, -140), 15, 24, 8, { 3, 2, 1 })
for _, c in { { 60, -128, 2 }, { 65, -124, 1 }, { 59, -122, 1 }, { 245, -140, 2 }, { 249, -135, 1 } } do
	crates(Yard, c[1], 8, c[2], c[3])
end
for _, c in { { 70, -85, 2 }, { 76, -82, 1 }, { 145, -88, 2 } } do
	crates(Yard, c[1], 4, c[2], c[3])
end
bales(Yard, -178, 8, -128)
bales(Yard, -62, 8, -128)
tank(Yard, 8, 12, -148, 8, -120)
tank(Chimenea, 10, 12, 178, 4, -52)
tank(Yard, 8, 10, 5, 8, -190)
tank(Yard, 10, 14, -30, 8, -172)
tank(Yard, 8, 12, 112, 4, -82)
block(Yard, Vector3.new(6, 7, 6), 80, 8, -150, 0, METAL, Enum.Material.Metal, "Pump")
truck(Yard, Vector2.new(205, -132), 0, 8, false)
for x = -135, 120, 15 do
	local zw, zn = zAt(NORTH_WALL, x), zAt(NORTH_WALL, x + 15)
	if math.abs(x - 40) > 10 then
		for _, o in { -8, -18 } do
			block(Yard, Vector3.new(1.2, 10, 1.2), x, 8, zw + o, 0, METAL, Enum.Material.Metal, "RackPost")
		end
	end
	beam(Yard, Vector2.new(x, zw - 7), Vector2.new(x, zw - 19), 17, 18, 1, METAL, Enum.Material.Metal, "RackBeam")
	if x < 120 then
		beam(Yard, Vector2.new(x, zw - 13), Vector2.new(x + 15, zn - 13), 18, 18.4, 11, METAL, Enum.Material.DiamondPlate, "RackDeck")
		for _, o in { -9.5, -13, -16.5 } do
			detail(rod(Yard, Vector2.new(x, zw + o), Vector2.new(x + 15, zn + o), 18.4, 1.6, CAP, Enum.Material.Metal, "Pipe"))
		end
	end
end
block(Yard, Vector3.new(20, 18, 12), -20, 8, -210, 0, CONCRETE, Enum.Material.Concrete, "LabPortal")
detail(block(Yard, Vector3.new(12, 12, 0.4), -20, 8, -203.9, 0, METAL, Enum.Material.DiamondPlate, "LabDoor"))

local Props = folder("ReactiveProps", MapModel)
for _, spot in { { -178, -186, false }, { -182, -183, true }, { -134, 146, false }, { -120, 132, true }, { 88, 166, false }, { 190, -36, true }, { -50, -140, false }, { -46, -136, true } } do
	local x, z, barrel = spot[1], spot[2], spot[3]
	local size = if barrel then Vector3.new(2.6, 2, 2) else Vector3.new(2, 2, 2)
	local p = part(Props, size, Vector3.new(x, heightAt(x, z) + 1, z), if barrel then METAL else WOOD, if barrel then Enum.Material.CorrodedMetal else Enum.Material.WoodPlanks, if barrel then "Barrel" else "Crate")
	if barrel then
		p.Shape = Enum.PartType.Cylinder
		p.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	end
	p.Anchored = false
	p:AddTag("Reactive")
end

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
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function tagged(name: string): { Instance }
	local found = {}
	for _, d in script.Parent:GetDescendants() do
		if d.Name == name or d:GetAttribute(name) then
			table.insert(found, d)
		end
	end
	return found
end

local function hurtInCanal()
	local hazards = tagged("CanalHazard")
	while script:IsDescendantOf(workspace) do
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local role = character and character:FindFirstChild("Role") :: StringValue?
			if humanoid and root and humanoid.Health > 1 and not (role and role.Value == "Killer") then
				for _, hazard in hazards do
					local box = hazard :: BasePart
					local p = box.CFrame:PointToObjectSpace(root.Position)
					if math.abs(p.X) < box.Size.X / 2 and math.abs(p.Y) < box.Size.Y / 2 and math.abs(p.Z) < box.Size.Z / 2 then
						humanoid.Health = math.max(humanoid.Health - 5, 1)
						break
					end
				end
			end
		end
		task.wait(1)
	end
end

local function oneWayDoors()
	local doors = tagged("OneWayDoor")
	local passing: { [Instance]: boolean } = {}
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if not script:IsDescendantOf(workspace) then
			connection:Disconnect()
			return
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		for _, door in doors do
			local panel = (door :: Model).PrimaryPart :: BasePart
			local side = (root.Position - panel.Position):Dot(door:GetAttribute("OpenDirection") :: Vector3)
			if side < -1 then
				passing[door] = true
			elseif side > 3 then
				passing[door] = false
			end
			panel.CanCollide = not passing[door]
		end
	end)
end

return {
	Init = function()
		if RunService:IsServer() then
			task.spawn(hurtInCanal)
		else
			oneWayDoors()
		end
	end,
}]]
Behaviour.Parent = Root

Root.Parent = Maps
local _, size = MapModel:GetBoundingBox()
return "Papelera built: " .. #MapModel:GetDescendants() .. " instances, size " .. tostring(size) .. ", moved out of rotation: " .. (if #moved > 0 then table.concat(moved, ", ") else "none")
