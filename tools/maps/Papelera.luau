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

for _, r in { { -246, -130, 20 }, { -244, -20, -15 }, { -244, 30, 10 }, { 246, -60, 160 }, { 244, 150, 200 }, { -120, 202, 80 }, { 150, 203, 100 } } do
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
		for k = 0, 9 do
			local diameter = 3.2 + rng:NextNumber() * 0.5
			local log = beam(Outside, a, b, -6 + k * 3.3, -6 + k * 3.3 + diameter, diameter, WOOD:Lerp(Color3.fromRGB(60, 46, 34), rng:NextNumber()), Enum.Material.Wood, "Log")
			log.Shape = Enum.PartType.Cylinder
			log.Size = Vector3.new(log.Size.Z + 3, diameter, diameter)
			log.CFrame *= CFrame.Angles(0, math.rad(90), 0)
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
local function pine(x: number, z: number, h: number, tiers: number, shadows: boolean)
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
