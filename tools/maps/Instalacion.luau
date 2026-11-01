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

local MaterialService = game:GetService("MaterialService")
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
	local lab = container.Name == "LabComplex"
	part(parent, Vector3.new(size.X, 0.2, size.Y), Vector3.new(center.X, 0.1, center.Y), if lab then Color3.fromRGB(96, 98, 94) else DARK_CONCRETE, if lab then Enum.Material.CeramicTiles else Enum.Material.Concrete, "Floor").Reflectance = if lab then 0.12 else 0
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
	local tint = if ceiling then Color3.fromRGB(150, 205, 255) else Color3.fromRGB(205, 215, 255)
	local head = part(model, if ceiling then Vector3.new(6, 0.35, 0.8) else Vector3.new(2.2, 0.5, 2.2), Vector3.new(pos.X, headY, pos.Z), tint, Enum.Material.Neon, "Bulb")
	head.CastShadow = false
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 100
	spot.Range = if ceiling then 26 else 42
	spot.Brightness = if ceiling then 3.5 else 6
	spot.Color = tint
	spot.Shadows = shadows == true
	spot.Parent = head
	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Brightness = 1
	glow.Color = spot.Color
	glow.Parent = head
	local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -headY + 0.2, 0)
	top.Parent, bottom.Parent = head, head
	local cone = Instance.new("Beam")
	cone.Attachment0, cone.Attachment1 = top, bottom
	cone.FaceCamera = true
	cone.Width0, cone.Width1 = 1.8, if ceiling then 9 else 16
	cone.LightEmission = 1
	cone.Color = ColorSequence.new(spot.Color)
	cone.Transparency = NumberSequence.new(0.92, 1)
	cone.Segments = 1
	cone:AddTag("Detail")
	cone.Parent = head
	if flicker then
		head:SetAttribute("Flicker", true)
	end
end

local HALF = Vector2.new(230, 210)
local CORE = Vector2.new(160, 140)
local BEACON_RED = Color3.fromRGB(255, 40, 30)
part(MapModel, Vector3.new(CORE.X * 2 + 20, 2, CORE.Y * 2 + 20), Vector3.new(0, -1, 0), Color3.fromRGB(74, 76, 82), Enum.Material.Asphalt, "Ground")
part(MapModel, Vector3.new(HALF.X * 2 + 500, 2, HALF.Y * 2 + 500), Vector3.new(0, -1.15, 0), Color3.fromRGB(64, 72, 52), Enum.Material.Grass, "Grass")
part(MapModel, Vector3.new(20, 2, 300), Vector3.new(0, -0.98, CORE.Y + 150), Color3.fromRGB(58, 60, 66), Enum.Material.Asphalt, "Road")
for z = CORE.Y + 6, CORE.Y + 296, 10 do
	local stripe = part(MapModel, Vector3.new(0.5, 0.05, 5), Vector3.new(0, 0.05, z), Color3.fromRGB(220, 180, 50), Enum.Material.SmoothPlastic, "RoadLine")
	stripe.CanCollide = false
	stripe.CastShadow = false
end
for _, z in { CORE.Y + 20, CORE.Y + 45, HALF.Y + 30, HALF.Y + 70 } do
	for _, x in { -12, 12 } do
		local post = part(MapModel, Vector3.new(0.6, 14, 0.6), Vector3.new(x, 7, z), METAL, Enum.Material.Metal, "StreetLamp")
		local head = part(MapModel, Vector3.new(2.4, 0.5, 1.2), Vector3.new(x - math.sign(x) * 1.2, 14, z), Color3.fromRGB(255, 205, 140), Enum.Material.Neon, "StreetLampHead")
		head.CastShadow = false
		local warm = Instance.new("SpotLight")
		warm.Face = Enum.NormalId.Bottom
		warm.Angle = 110
		warm.Range = 26
		warm.Brightness = 3
		warm.Color = Color3.fromRGB(255, 190, 120)
		warm.Parent = head
		post.CastShadow = true
	end
end

local function beacon(parent: Instance, pos: Vector3)
	local bulb = part(parent, Vector3.new(0.9, 0.9, 0.9), pos, BEACON_RED, Enum.Material.Neon, "Beacon")
	bulb.Shape = Enum.PartType.Ball
	bulb.CastShadow = false
	local glow = Instance.new("PointLight")
	glow.Color = BEACON_RED
	glow.Range = 12
	glow.Brightness = 2.6
	glow.Parent = bulb
end

local Fence = folder("Fence", Yard)
local function fenceSide(alongX: boolean, fixed: number, from: number, to: number, gap: number?)
	local function at(t: number, y: number): Vector3
		return if alongX then Vector3.new(t, y, fixed) else Vector3.new(fixed, y, t)
	end
	local runs = if gap then { { from, -gap / 2 }, { gap / 2, to } } else { { from, to } }
	for _, run in runs do
		local len = run[2] - run[1]
		local mid = (run[1] + run[2]) / 2
		local function span(height: number, y: number, thick: number, name: string, material: Enum.Material): Part
			return part(Fence, if alongX then Vector3.new(len, height, thick) else Vector3.new(thick, height, len), at(mid, y), METAL, material, name)
		end
		local mesh = span(10, 5.4, 0.12, "Mesh", Enum.Material.DiamondPlate)
		mesh.Color = Color3.fromRGB(130, 136, 148)
		mesh.Transparency = 0.62
		mesh.CastShadow = false
		span(0.35, 10.6, 0.35, "Rail", Enum.Material.Metal)
		span(0.25, 0.6, 0.25, "Rail", Enum.Material.Metal)
		local wire = span(0.9, 11.6, 0.9, "BarbedWire", Enum.Material.Metal)
		wire.Shape = Enum.PartType.Cylinder
		wire.CFrame *= if alongX then CFrame.identity else CFrame.Angles(0, math.rad(90), 0)
		wire.Color = Color3.fromRGB(150, 155, 165)
		wire.Transparency = 0.2
		local posts = math.ceil(len / 12)
		for i = 0, posts do
			local t = run[1] + len * i / posts
			part(Fence, Vector3.new(0.6, 12, 0.6), at(t, 6), METAL, Enum.Material.Metal, "Post")
			if i % 5 == 0 then
				beacon(Fence, at(t, 12.5))
			end
		end
	end
end
fenceSide(true, -HALF.Y, -HALF.X, HALF.X)
fenceSide(true, HALF.Y, -HALF.X, HALF.X, 26)
fenceSide(false, -HALF.X, -HALF.Y, HALF.Y)
fenceSide(false, HALF.X, -HALF.Y, HALF.Y)

local Gate = folder("Gate", Yard)
for _, x in { -14, 14 } do
	part(Gate, Vector3.new(4, 16, 4), Vector3.new(x, 8, HALF.Y), DARK_CONCRETE, Enum.Material.Concrete, "Pillar")
	beacon(Gate, Vector3.new(x, 16.6, HALF.Y))
	lamp(Gate, Vector3.new(x, 0, HALF.Y - 3), false)
end
for _, x in { -6, 6 } do
	local leaf = part(Gate, Vector3.new(12, 12, 0.3), Vector3.new(x, 6.2, HALF.Y), METAL, Enum.Material.DiamondPlate, "GateLeaf")
	leaf.Transparency = 0.55
	part(Gate, Vector3.new(12, 0.5, 0.5), Vector3.new(x, 12.2, HALF.Y), RUST, Enum.Material.CorrodedMetal, "GateFrame")
	part(Gate, Vector3.new(12, 0.5, 0.5), Vector3.new(x, 0.4, HALF.Y), RUST, Enum.Material.CorrodedMetal, "GateFrame")
	part(Gate, Vector3.new(0.5, 12, 0.5), Vector3.new(x + (if x < 0 then -5.8 else 5.8), 6.2, HALF.Y), RUST, Enum.Material.CorrodedMetal, "GateFrame")
end
part(Gate, Vector3.new(32, 4, 1), Vector3.new(0, 18, HALF.Y), DARK_CONCRETE, Enum.Material.Concrete, "Lintel")

local function watchtower(c: Vector2, faceTo: Vector2)
	local m = Instance.new("Model")
	m.Name = "Watchtower"
	m.Parent = Yard
	for _, o in { Vector2.new(-4, -4), Vector2.new(4, -4), Vector2.new(-4, 4), Vector2.new(4, 4) } do
		part(m, Vector3.new(0.9, 24, 0.9), Vector3.new(c.X + o.X, 12, c.Y + o.Y), WOOD, Enum.Material.Wood, "Leg")
	end
	for y = 7, 19, 6 do
		part(m, Vector3.new(9, 0.4, 0.4), Vector3.new(c.X, y, c.Y - 4), WOOD, Enum.Material.Wood, "Brace")
		part(m, Vector3.new(9, 0.4, 0.4), Vector3.new(c.X, y, c.Y + 4), WOOD, Enum.Material.Wood, "Brace")
		part(m, Vector3.new(0.4, 0.4, 9), Vector3.new(c.X - 4, y, c.Y), WOOD, Enum.Material.Wood, "Brace")
		part(m, Vector3.new(0.4, 0.4, 9), Vector3.new(c.X + 4, y, c.Y), WOOD, Enum.Material.Wood, "Brace")
	end
	part(m, Vector3.new(11, 0.6, 11), Vector3.new(c.X, 24.3, c.Y), WOOD, Enum.Material.WoodPlanks, "Deck")
	for _, s in { { Vector3.new(10, 2.4, 0.4), Vector2.new(0, -5) }, { Vector3.new(10, 2.4, 0.4), Vector2.new(0, 5) }, { Vector3.new(0.4, 2.4, 10), Vector2.new(-5, 0) }, { Vector3.new(0.4, 2.4, 10), Vector2.new(5, 0) } } do
		part(m, s[1], Vector3.new(c.X + s[2].X, 25.8, c.Y + s[2].Y), WOOD, Enum.Material.WoodPlanks, "Cabin")
		local window = part(m, s[1] + Vector3.new(0, 0.2, 0), Vector3.new(c.X + s[2].X, 28.3, c.Y + s[2].Y), Color3.fromRGB(255, 196, 120), Enum.Material.Glass, "Window")
		window.Transparency = 0.45
	end
	part(m, Vector3.new(12.5, 0.8, 12.5), Vector3.new(c.X, 30, c.Y), METAL, Enum.Material.CorrodedMetal, "Roof")
	local warm = Instance.new("PointLight")
	warm.Color = Color3.fromRGB(255, 180, 100)
	warm.Range = 14
	warm.Brightness = 1.5
	warm.Parent = part(m, Vector3.new(0.6, 0.6, 0.6), Vector3.new(c.X, 28.5, c.Y), Color3.fromRGB(255, 200, 130), Enum.Material.Neon, "CabinLamp")
	beacon(m, Vector3.new(c.X, 30.9, c.Y))
	local head = part(m, Vector3.new(1.4, 1.4, 1.8), Vector3.new(c.X, 27.5, c.Y), METAL, Enum.Material.Metal, "Searchlight")
	head.CFrame = CFrame.lookAt(head.Position, ORIGIN + Vector3.new(faceTo.X, 0, faceTo.Y))
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Angle = 28
	beam.Range = 60
	beam.Brightness = 3
	beam.Color = Color3.fromRGB(220, 230, 255)
	beam.Parent = head
	local from, to = Instance.new("Attachment"), Instance.new("Attachment")
	to.Position = Vector3.new(0, 0, -55)
	from.Parent, to.Parent = head, head
	local cone = Instance.new("Beam")
	cone.Attachment0, cone.Attachment1 = from, to
	cone.Width0, cone.Width1 = 1.4, 26
	cone.FaceCamera = true
	cone.LightEmission = 1
	cone.Color = ColorSequence.new(Color3.fromRGB(210, 225, 255))
	cone.Transparency = NumberSequence.new(0.8, 1)
	cone.Segments = 1
	cone:AddTag("Detail")
	cone.Parent = head
	part(m, Vector3.new(2, 24, 0.3), Vector3.new(c.X, 12, c.Y + 4.8), RUST, Enum.Material.CorrodedMetal, "Ladder")
end
for _, s in { -1, 1 } do
	watchtower(Vector2.new(s * (HALF.X - 12), HALF.Y - 12), Vector2.new(s * (HALF.X - 50), HALF.Y - 50))
	watchtower(Vector2.new(s * (HALF.X - 12), -HALF.Y + 12), Vector2.new(s * (HALF.X - 50), -HALF.Y + 50))
end

local Outside = folder("Outside", MapModel)
local function pine(parent: Instance, base: Vector3, h: number, solid: boolean)
	local trunk = part(parent, Vector3.new(h * 0.3, h * 0.05, h * 0.05), base + Vector3.new(0, h * 0.15, 0), Color3.fromRGB(46, 34, 26), Enum.Material.Wood, "Trunk")
	trunk.Shape = Enum.PartType.Cylinder
	trunk.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	trunk.CanCollide = solid
	for tier = 0, 1 do
		local w, th = h * (0.5 - tier * 0.17), h * (0.5 - tier * 0.08)
		local center = ORIGIN + base + Vector3.new(0, h * (0.2 + tier * 0.3) + th / 2, 0)
		for q = 0, 3 do
			local leaf = Instance.new("CornerWedgePart")
			leaf.Name = "Needles"
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.CastShadow = solid
			leaf.Size = Vector3.new(w / 2, th, w / 2)
			leaf.CFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(90 * q), 0) * CFrame.new(-w / 4, 0, w / 4)
			leaf.Color = if tier == 0 then Color3.fromRGB(40, 58, 46) else Color3.fromRGB(58, 80, 64)
			leaf.Material = Enum.Material.Grass
			leaf.Parent = parent
		end
	end
end
local forestRand = Random.new(7)
for x = -HALF.X - 80, HALF.X + 80, 22 do
	for z = -HALF.Y - 80, HALF.Y + 80, 22 do
		local p = Vector2.new(x + forestRand:NextNumber(-8, 8), z + forestRand:NextNumber(-8, 8))
		local inside = math.abs(p.X) < HALF.X + 8 and math.abs(p.Y) < HALF.Y + 8
		local onRoad = math.abs(p.X) < 18 and p.Y > HALF.Y
		if not inside and not onRoad then
			local tree = Instance.new("Model")
			tree.Name = "Pine"
			tree.Parent = Outside
			pine(tree, Vector3.new(p.X, 0, p.Y), forestRand:NextNumber(26, 44), false)
			if math.abs(p.X) > HALF.X + 40 or math.abs(p.Y) > HALF.Y + 40 then
				tree:AddTag("Detail")
				for _, d in tree:GetChildren() do
					d:AddTag("Detail")
				end
			end
		end
	end
end
for i = 0, 17 do
	local angle = math.rad(i * 20 + forestRand:NextNumber(-6, 6))
	local peak = forestRand:NextNumber(90, 170)
	local at = Vector3.new(math.cos(angle) * 540, -peak * 0.2, math.sin(angle) * 500)
	local ridge = part(Outside, Vector3.new(peak, peak, 200), at, Color3.fromRGB(22, 25, 34), Enum.Material.Slate, "Mountain")
	ridge.CFrame = CFrame.lookAt(ORIGIN + at, ORIGIN + Vector3.new(0, at.Y, 0)) * CFrame.Angles(0, 0, math.rad(45))
	ridge.CanCollide = false
	ridge.CastShadow = false
end

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
local ring = part(Reactor, Vector3.new(1, 15, 15), Vector3.new(105, 12, -92), Color3.fromRGB(255, 45, 35), Enum.Material.Neon, "CoreRing")
ring.Shape = Enum.PartType.Cylinder
ring.CFrame = CFrame.new(ORIGIN + Vector3.new(105, 12, -92)) * CFrame.Angles(0, 0, math.rad(90))
ring.CanCollide = false
local coreLight = Instance.new("PointLight")
coreLight.Color = ring.Color
coreLight.Range = 45
coreLight.Brightness = 3.2
for _, p in { Vector3.new(75, 10, -95), Vector3.new(135, 10, -95), Vector3.new(105, 10, -60) } do
	fillLight(Reactor, p)
end
coreLight.Parent = ring
local chimney = part(Reactor, Vector3.new(60, 9, 9), Vector3.new(100, 30, -131), DARK_CONCRETE, Enum.Material.Concrete, "Chimney")
chimney.Shape = Enum.PartType.Cylinder
chimney.CFrame = CFrame.new(ORIGIN + Vector3.new(100, 30, -131)) * CFrame.Angles(0, 0, math.rad(90))
local chimneyBeacon = part(Reactor, Vector3.new(1.5, 1.5, 1.5), Vector3.new(100, 61, -131), Color3.fromRGB(255, 40, 30), Enum.Material.Neon, "Beacon")
chimneyBeacon.CastShadow = false
chimneyBeacon:SetAttribute("Flicker", true)
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

local Details = folder("Details", MapModel)
local function detail(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p:AddTag("Detail")
	return p
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
local WHITE, RED, AMBER = Color3.fromRGB(220, 224, 230), Color3.fromRGB(210, 40, 36), Color3.fromRGB(230, 170, 40)
sign("ANOMALIS  LAB-07", Vector3.new(0, 18, HALF.Y - 0.6), Enum.NormalId.Front, WHITE)
sign("ANOMALIS  SECTOR A  PUERTA", Vector3.new(0, 18, HALF.Y + 0.6), Enum.NormalId.Back, RED)
sign("SECTOR C  LABORATORIOS", Vector3.new(-35, 12, -39.1), Enum.NormalId.Back, WHITE)
sign("CONTENCIÓN  SOLO AUTORIZADOS", Vector3.new(-35, 10, -84.1), Enum.NormalId.Back, RED)
sign("REACTOR 02  RADIACIÓN", Vector3.new(105, 16, -49.1), Enum.NormalId.Back, AMBER)
sign("ALMACÉN B", Vector3.new(-110, 10, 69.1), Enum.NormalId.Front, WHITE)
sign("BARRACONES", Vector3.new(92, 9, 81.9), Enum.NormalId.Front, WHITE)

for _, z in { -83.4, -76.6 } do
	detail(part(Details, Vector3.new(148, 1.1, 1.1), Vector3.new(-35, 14.6, z), METAL, Enum.Material.Metal, "Pipe")).Shape = Enum.PartType.Cylinder
end
detail(part(Details, Vector3.new(88, 1.6, 1.6), Vector3.new(105, 19, -118), RUST, Enum.Material.CorrodedMetal, "Pipe")).Shape = Enum.PartType.Cylinder

for _, p in { Vector3.new(-70, 0, 20), Vector3.new(15, 0, 50), Vector3.new(-15, 0, 95), Vector3.new(70, 0, 10), Vector3.new(-125, 0, -45), Vector3.new(125, 0, 80), Vector3.new(40, 0, 105) } do
	for i, o in { Vector3.zero, Vector3.new(3, 0, 1.5), Vector3.new(-2, 0, 2) } do
		local d = 6 - i
		local puddle = detail(part(Details, Vector3.new(0.05, d, d * 1.3), p + o + Vector3.new(0, 0.03, 0), Color3.fromRGB(58, 64, 72), Enum.Material.Glass, "Puddle"))
		puddle.Shape = Enum.PartType.Cylinder
		puddle.CFrame *= CFrame.Angles(0, 0, math.rad(90))
		puddle.Transparency = 0.45
	end
end

local Landmarks = folder("Landmarks", MapModel)
local PURPLE = Color3.fromRGB(170, 70, 230)
local function glowLight(parent: BasePart, kind: string, color: Color3, range: number, brightness: number)
	local light = Instance.new(kind) :: any
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = parent
	return light
end
local function bigText(parent: BasePart, text: string, face: Enum.NormalId, color: Color3, font: Enum.Font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.4
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = font
	label.TextColor3 = color
	label.Parent = gui
end

local upper = part(Landmarks, Vector3.new(80, 14, 40), Vector3.new(-35, 24, -62), DARK_CONCRETE, Enum.Material.Concrete, "UpperFloor")
local WINDOW_TINTS = { Color3.fromRGB(120, 170, 255), Color3.fromRGB(255, 190, 120), nil, Color3.fromRGB(120, 170, 255) }
for i = 0, 6 do
	local x = -70 + i * 6.5
	local tint = WINDOW_TINTS[i % 4 + 1]
	local pane = part(Landmarks, Vector3.new(4.4, 3.4, 0.3), Vector3.new(x, 24, -41.7), tint or Color3.fromRGB(16, 18, 24), if tint then Enum.Material.Neon else Enum.Material.Glass, "Window")
	pane.Transparency = if tint then 0.3 else 0.1
	pane.CastShadow = false
	part(Landmarks, Vector3.new(5.2, 4.2, 0.2), Vector3.new(x, 24, -41.85), Color3.fromRGB(30, 32, 38), Enum.Material.Metal, "WindowFrame")
	part(Landmarks, Vector3.new(0.25, 3.4, 0.4), Vector3.new(x, 24, -41.6), Color3.fromRGB(30, 32, 38), Enum.Material.Metal, "Mullion")
end
local plate = part(Landmarks, Vector3.new(26, 9, 0.4), Vector3.new(-8, 24, -41.6), Color3.fromRGB(26, 28, 34), Enum.Material.Metal, "LabSign")
bigText(plate, "LAB-07", Enum.NormalId.Back, Color3.fromRGB(235, 240, 250), Enum.Font.GothamBlack)
glowLight(plate, "SurfaceLight", Color3.fromRGB(200, 215, 255), 10, 1.5).Face = Enum.NormalId.Back
for _, edge in { { Vector3.new(26.6, 0.35, 0.3), Vector3.new(-8, 28.65, -41.9) }, { Vector3.new(26.6, 0.35, 0.3), Vector3.new(-8, 19.35, -41.9) }, { Vector3.new(0.35, 9.6, 0.3), Vector3.new(-21.15, 24, -41.9) }, { Vector3.new(0.35, 9.6, 0.3), Vector3.new(5.15, 24, -41.9) } } do
	part(Landmarks, edge[1], edge[2], Color3.fromRGB(150, 190, 255), Enum.Material.Neon, "SignBorder").CastShadow = false
end
local hazard = part(Landmarks, Vector3.new(8, 13, 0.4), Vector3.new(-26, 24, -41.6), Color3.fromRGB(170, 22, 24), Enum.Material.SmoothPlastic, "HazardBanner")
bigText(hazard, "☣", Enum.NormalId.Back, Color3.fromRGB(16, 4, 4), Enum.Font.GothamBlack)
glowLight(hazard, "SurfaceLight", Color3.fromRGB(255, 40, 40), 16, 1.6).Face = Enum.NormalId.Back
local washer = part(Landmarks, Vector3.new(1.5, 0.6, 1.5), Vector3.new(-26, 0.4, -36), Color3.fromRGB(255, 50, 40), Enum.Material.Neon, "FacadeWash")
washer.CFrame = CFrame.lookAt(washer.Position, ORIGIN + Vector3.new(-26, 26, -42))
glowLight(washer, "SpotLight", Color3.fromRGB(255, 40, 30), 34, 4).Angle = 40
for _, x in { -45, -25 } do
	local sconce = part(Landmarks, Vector3.new(1.6, 0.8, 1), Vector3.new(x, 13, -39.2), Color3.fromRGB(255, 200, 130), Enum.Material.Neon, "Sconce")
	sconce.CastShadow = false
	local down = glowLight(sconce, "SpotLight", Color3.fromRGB(255, 185, 110), 22, 3)
	down.Face = Enum.NormalId.Bottom
	down.Angle = 90
end
for _, edge in { { Vector3.new(81, 1.6, 0.8), Vector3.new(-35, 31.8, -42.4) }, { Vector3.new(81, 1.6, 0.8), Vector3.new(-35, 31.8, -81.6) }, { Vector3.new(0.8, 1.6, 40), Vector3.new(-75.1, 31.8, -62) }, { Vector3.new(0.8, 1.6, 40), Vector3.new(5.1, 31.8, -62) } } do
	part(Landmarks, edge[1], edge[2], DARK_CONCRETE, Enum.Material.Concrete, "Parapet")
end

local DOME_GLOW = Color3.fromRGB(205, 90, 255)
local dome = part(Landmarks, Vector3.new(34, 34, 34), Vector3.new(-35, 31, -62), DOME_GLOW, Enum.Material.Glass, "ResearchDome")
dome.Shape = Enum.PartType.Ball
dome.Transparency = 0.58
dome.CastShadow = false
local core = part(Landmarks, Vector3.new(6, 6, 6), Vector3.new(-35, 34, -62), DOME_GLOW, Enum.Material.Neon, "DomeCore")
core.Shape = Enum.PartType.Ball
glowLight(core, "PointLight", DOME_GLOW, 60, 5).Shadows = true
glowLight(part(Landmarks, Vector3.new(0.4, 0.4, 0.4), Vector3.new(-35, 50, -62), DOME_GLOW, Enum.Material.Neon, "DomeTop"), "PointLight", DOME_GLOW, 40, 3).Shadows = true
for _, angle in { 0, 45, 90, 135 } do
	local rib = part(Landmarks, Vector3.new(0.7, 34.6, 34.6), Vector3.new(-35, 31, -62), Color3.fromRGB(255, 190, 255), Enum.Material.Neon, "DomeRib")
	rib.Shape = Enum.PartType.Cylinder
	rib.CFrame = CFrame.new(ORIGIN + Vector3.new(-35, 31, -62)) * CFrame.Angles(0, math.rad(angle), 0)
	rib.Transparency = 0.7
	rib.CastShadow = false
end
local baseRing = part(Landmarks, Vector3.new(0.8, 35, 35), Vector3.new(-35, 31.4, -62), DOME_GLOW, Enum.Material.Neon, "DomeRing")
baseRing.Shape = Enum.PartType.Cylinder
baseRing.CFrame = CFrame.new(ORIGIN + Vector3.new(-35, 31.4, -62)) * CFrame.Angles(0, 0, math.rad(90))
baseRing.CastShadow = false

local mast = part(Landmarks, Vector3.new(1.2, 6, 1.2), Vector3.new(10, 20, -105), METAL, Enum.Material.Metal, "DishMast")
local dish = part(Landmarks, Vector3.new(1, 16, 16), Vector3.new(10, 26, -105), Color3.fromRGB(150, 152, 158), Enum.Material.Metal, "SatelliteDish")
dish.Shape = Enum.PartType.Cylinder
dish.CFrame = CFrame.new(ORIGIN + Vector3.new(10, 26, -105)) * CFrame.Angles(0, math.rad(-30), math.rad(-35))
mast.CastShadow = true

local tower = Instance.new("Model")
tower.Name = "CommsTower"
tower.Parent = Landmarks
local TOWER_AT, TOWER_H = Vector2.new(-185, -150), 60
for _, o in { Vector2.new(-5, -5), Vector2.new(5, -5), Vector2.new(-5, 5), Vector2.new(5, 5) } do
	local leg = part(tower, Vector3.new(0.8, TOWER_H, 0.8), Vector3.new(TOWER_AT.X + o.X * 0.6, TOWER_H / 2, TOWER_AT.Y + o.Y * 0.6), RUST, Enum.Material.CorrodedMetal, "Leg")
	leg.CFrame = CFrame.lookAt(ORIGIN + Vector3.new(TOWER_AT.X + o.X, 0, TOWER_AT.Y + o.Y), ORIGIN + Vector3.new(TOWER_AT.X + o.X * 0.2, TOWER_H, TOWER_AT.Y + o.Y * 0.2)) * CFrame.new(0, 0, -TOWER_H / 2) * CFrame.Angles(math.rad(90), 0, 0)
end
for y = 8, TOWER_H - 6, 10 do
	local w = 10 - y / TOWER_H * 8
	for _, s in { { Vector3.new(w, 0.4, 0.4), Vector2.new(0, -w / 2) }, { Vector3.new(w, 0.4, 0.4), Vector2.new(0, w / 2) }, { Vector3.new(0.4, 0.4, w), Vector2.new(-w / 2, 0) }, { Vector3.new(0.4, 0.4, w), Vector2.new(w / 2, 0) } } do
		part(tower, s[1], Vector3.new(TOWER_AT.X + s[2].X, y, TOWER_AT.Y + s[2].Y), RUST, Enum.Material.CorrodedMetal, "Brace")
	end
	if y % 20 == 8 then
		beacon(tower, Vector3.new(TOWER_AT.X + w / 2, y + 0.8, TOWER_AT.Y))
	end
end
part(tower, Vector3.new(0.4, 10, 0.4), Vector3.new(TOWER_AT.X, TOWER_H + 5, TOWER_AT.Y), METAL, Enum.Material.Metal, "Antenna")
beacon(tower, Vector3.new(TOWER_AT.X, TOWER_H + 10.5, TOWER_AT.Y))

local HELIPAD_AT = Vector3.new(195, 0, -40)
local pad = part(Landmarks, Vector3.new(0.4, 36, 36), HELIPAD_AT + Vector3.new(0, 0.1, 0), Color3.fromRGB(52, 56, 62), Enum.Material.Concrete, "Helipad")
pad.Shape = Enum.PartType.Cylinder
pad.CFrame *= CFrame.Angles(0, 0, math.rad(90))
local ring = part(Landmarks, Vector3.new(0.42, 30, 30), HELIPAD_AT + Vector3.new(0, 0.11, 0), Color3.fromRGB(200, 200, 190), Enum.Material.SmoothPlastic, "HelipadRing")
ring.Shape = Enum.PartType.Cylinder
ring.CFrame *= CFrame.Angles(0, 0, math.rad(90))
local inner = part(Landmarks, Vector3.new(0.44, 27, 27), HELIPAD_AT + Vector3.new(0, 0.12, 0), Color3.fromRGB(52, 56, 62), Enum.Material.Concrete, "HelipadInner")
inner.Shape = Enum.PartType.Cylinder
inner.CFrame *= CFrame.Angles(0, 0, math.rad(90))
for _, s in { { Vector3.new(1.6, 0.1, 11), Vector3.new(-4, 0, 0) }, { Vector3.new(1.6, 0.1, 11), Vector3.new(4, 0, 0) }, { Vector3.new(8, 0.1, 1.6), Vector3.zero } } do
	part(Landmarks, s[1], HELIPAD_AT + s[2] + Vector3.new(0, 0.36, 0), Color3.fromRGB(210, 210, 200), Enum.Material.SmoothPlastic, "HelipadMark").CanCollide = false
end
for i = 0, 11 do
	local a = math.rad(i * 30)
	local stud = part(Landmarks, Vector3.new(0.6, 0.4, 0.6), HELIPAD_AT + Vector3.new(math.cos(a) * 17, 0.4, math.sin(a) * 17), Color3.fromRGB(120, 200, 255), Enum.Material.Neon, "PadLight")
	stud.CastShadow = false
	if i % 3 == 0 then
		glowLight(stud, "PointLight", Color3.fromRGB(120, 200, 255), 8, 1)
	end
end

local Interiors = folder("Interiors", MapModel)
local LIQUID = Color3.fromRGB(150, 60, 220)
local function capsule(x: number, z: number, broken: boolean)
	local m = Instance.new("Model")
	m.Name = "ContainmentCapsule"
	m.Parent = Interiors
	local function disc(size: Vector3, y: number, color: Color3, material: Enum.Material, name: string): Part
		local d = part(m, size, Vector3.new(x, y, z), color, material, name)
		d.Shape = Enum.PartType.Cylinder
		d.CFrame *= CFrame.Angles(0, 0, math.rad(90))
		return d
	end
	disc(Vector3.new(1.4, 8, 8), 0.7, METAL, Enum.Material.DiamondPlate, "Base")
	disc(Vector3.new(1.2, 8, 8), 13.4, METAL, Enum.Material.Metal, "Cap")
	disc(Vector3.new(0.3, 7.6, 7.6), 1.5, LIQUID, Enum.Material.Neon, "BaseGlow").CastShadow = false
	if broken then
		for i = 0, 4 do
			local a = math.rad(i * 72 + 20)
			local shard = part(m, Vector3.new(1.6, 0.15, 1), Vector3.new(x + math.cos(a) * (5 + i % 2 * 2), 0.1, z + math.sin(a) * (5 + i % 2 * 2)), Color3.fromRGB(200, 170, 230), Enum.Material.Glass, "Shard")
			shard.Transparency = 0.4
			shard.CanCollide = false
			shard.CFrame *= CFrame.Angles(0, a, 0)
		end
		local spill = disc(Vector3.new(0.05, 12, 14), 0.06, LIQUID, Enum.Material.Glass, "Spill")
		spill.Transparency = 0.35
		spill.CanCollide = false
		glowLight(disc(Vector3.new(0.3, 2, 2), 12.5, LIQUID, Enum.Material.Neon, "Spark"), "PointLight", LIQUID, 18, 1.5)
	else
		local liquid = disc(Vector3.new(11, 6.4, 6.4), 7, LIQUID, Enum.Material.Neon, "Liquid")
		liquid.Transparency = 0.55
		liquid.CanCollide = false
		liquid.CastShadow = false
		local glass = disc(Vector3.new(11.6, 7.2, 7.2), 7.2, Color3.fromRGB(210, 190, 240), Enum.Material.Glass, "Glass")
		glass.Transparency = 0.6
		part(m, Vector3.new(1.4, 3, 0.8), Vector3.new(x, 7.5, z), Color3.fromRGB(14, 10, 18), Enum.Material.SmoothPlastic, "Specimen").CanCollide = false
		local head = part(m, Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, 9.7, z), Color3.fromRGB(14, 10, 18), Enum.Material.SmoothPlastic, "SpecimenHead")
		head.Shape = Enum.PartType.Ball
		head.CanCollide = false
		glowLight(liquid, "PointLight", LIQUID, 16, 1.4)
	end
end
capsule(0, -113, false)
capsule(13, -113, false)
capsule(26, -113, true)
capsule(36, -96, false)
local table_ = part(Interiors, Vector3.new(11, 0.6, 5), Vector3.new(10, 3.2, -98), Color3.fromRGB(150, 155, 160), Enum.Material.Metal, "ExperimentTable")
for _, o in { Vector3.new(-5, 0, -2), Vector3.new(5, 0, -2), Vector3.new(-5, 0, 2), Vector3.new(5, 0, 2) } do
	part(Interiors, Vector3.new(0.4, 3, 0.4), Vector3.new(10, 1.5, -98) + o, METAL, Enum.Material.Metal, "TableLeg")
end
local stain = part(Interiors, Vector3.new(4, 0.05, 2.2), Vector3.new(11, 3.53, -98), Color3.fromRGB(90, 10, 14), Enum.Material.SmoothPlastic, "Stain")
stain.CanCollide = false
table_.CastShadow = true

local DESK = Color3.fromRGB(46, 48, 54)
part(Interiors, Vector3.new(18, 3.6, 3), Vector3.new(-45, 1.8, -62), DESK, Enum.Material.Metal, "ReceptionDesk")
part(Interiors, Vector3.new(18.6, 0.3, 3.6), Vector3.new(-45, 3.75, -62), Color3.fromRGB(120, 124, 130), Enum.Material.Marble, "DeskTop")
for _, x in { -51, -45, -39 } do
	local screen = part(Interiors, Vector3.new(2.4, 1.6, 0.2), Vector3.new(x, 4.9, -62.6), Color3.fromRGB(60, 150, 255), Enum.Material.Neon, "Monitor")
	screen.CastShadow = false
	glowLight(screen, "SurfaceLight", Color3.fromRGB(80, 160, 255), 8, 1).Face = Enum.NormalId.Back
end
for _, x in { -68, -22 } do
	part(Interiors, Vector3.new(8, 1.6, 2.4), Vector3.new(x, 0.8, -46), Color3.fromRGB(70, 40, 40), Enum.Material.Fabric, "WaitingBench")
end

local Catwalk = folder("Catwalk", Interiors)
local WALK_Y, WALK_Z = 10, -114
part(Catwalk, Vector3.new(82, 0.6, 6), Vector3.new(105, WALK_Y, WALK_Z), METAL, Enum.Material.DiamondPlate, "Walkway")
part(Catwalk, Vector3.new(70, 3, 0.3), Vector3.new(105, WALK_Y + 1.8, WALK_Z + 3), RUST, Enum.Material.CorrodedMetal, "Railing").Transparency = 0.3
for x = 66, 144, 13 do
	part(Catwalk, Vector3.new(0.6, WALK_Y, 0.6), Vector3.new(x, WALK_Y / 2, WALK_Z + 2.7), RUST, Enum.Material.CorrodedMetal, "Strut")
end
local RAMP_RUN = 20
for _, x in { 67, 143 } do
	local ramp = part(Catwalk, Vector3.new(6, 0.6, math.sqrt(RAMP_RUN ^ 2 + WALK_Y ^ 2)), Vector3.new(x, WALK_Y / 2, WALK_Z + 3 + RAMP_RUN / 2), METAL, Enum.Material.DiamondPlate, "Ramp")
	ramp.CFrame *= CFrame.Angles(math.atan2(WALK_Y, RAMP_RUN), 0, 0)
end
local hazardRing = part(Interiors, Vector3.new(0.05, 26, 26), Vector3.new(105, 0.04, -92), Color3.fromRGB(255, 40, 30), Enum.Material.Neon, "HazardRing")
hazardRing.Shape = Enum.PartType.Cylinder
hazardRing.CFrame *= CFrame.Angles(0, 0, math.rad(90))
hazardRing.Transparency = 0.75
hazardRing.CanCollide = false
hazardRing.CastShadow = false

local Fog = folder("GroundFog", Details)
for _, c in { Vector2.new(-90, 30), Vector2.new(0, 50), Vector2.new(90, 40), Vector2.new(-30, 110), Vector2.new(110, -15), Vector2.new(-120, -30) } do
	local area = detail(part(Fog, Vector3.new(60, 1, 50), Vector3.new(c.X, 0.6, c.Y), CONCRETE, Enum.Material.SmoothPlastic, "FogArea"))
	area.Transparency = 1
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Shape = Enum.ParticleEmitterShape.Box
	mist.EmissionDirection = Enum.NormalId.Top
	mist.Rate = 3
	mist.Lifetime = NumberRange.new(10, 14)
	mist.Speed = NumberRange.new(0.3, 1)
	mist.SpreadAngle = Vector2.new(70, 70)
	mist.Size = NumberSequence.new(14, 24)
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.76), NumberSequenceKeypoint.new(1, 1) })
	mist.Color = ColorSequence.new(Color3.fromRGB(150, 160, 185))
	mist.LightInfluence = 1
	mist.Rotation = NumberRange.new(0, 360)
	mist.RotSpeed = NumberRange.new(-6, 6)
	mist.Acceleration = Vector3.new(0, -0.05, 0)
	mist:AddTag("Detail")
	mist.Parent = area
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
	ClockTime = 20,
	GeographicLatitude = 55,
	Brightness = 2,
	Ambient = Color3.fromRGB(22, 22, 34),
	OutdoorAmbient = Color3.fromRGB(105, 115, 155),
	EnvironmentDiffuseScale = 0.4,
	EnvironmentSpecularScale = 1,
	GlobalShadows = true,
	ShadowSoftness = 0.2,
	ExposureCompensation = 0.1,
	ColorShift_Top = Color3.fromRGB(0, 0, 0),
	ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
}]]
LightingModule.Parent = Root

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.32
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(84, 92, 124)
atmosphere.Decay = Color3.fromRGB(8, 8, 18)
atmosphere.Glare = 0
atmosphere.Haze = 2
atmosphere.Parent = LightingModule

local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "Grade"
grade.Brightness = 0
grade.Contrast = 0.08
grade.Saturation = 0.12
grade.TintColor = Color3.fromRGB(206, 212, 255)
grade.Parent = LightingModule

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1.2
bloom.Size = 24
bloom.Threshold = 0.9
bloom.Parent = LightingModule

local sky = Instance.new("Sky")
sky.StarCount = 1200
sky.CelestialBodiesShown = true
sky.MoonAngularSize = 16
sky.Parent = LightingModule

local depth = Instance.new("DepthOfFieldEffect")
depth.FarIntensity = 0.18
depth.FocusDistance = 40
depth.InFocusRadius = 60
depth.NearIntensity = 0
depth:AddTag("Detail")
depth.Parent = LightingModule

local Behaviour = Instance.new("ModuleScript")
Behaviour.Name = "Behaviour"
Behaviour.Source = [[--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DRAIN_RADIUS = 18
local STUTTER_RADIUS = 40

local function setLit(bulb: BasePart, on: boolean)
	bulb.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	for _, light in bulb:GetChildren() do
		if light:IsA("Light") then
			light.Enabled = on
		elseif light:IsA("Beam") then
			light.Enabled = on and not Players.LocalPlayer:GetAttribute("Potato")
		end
	end
end

local function blink(bulb: BasePart, rand: Random)
	setLit(bulb, false)
	task.wait(rand:NextNumber(0.03, 0.12))
	if not bulb:GetAttribute("Drained") then
		setLit(bulb, true)
	end
end

local function flicker(bulb: BasePart)
	local rand = Random.new()
	while bulb:IsDescendantOf(workspace) do
		task.wait(rand:NextNumber(0.4, 4))
		for _ = 1, rand:NextInteger(1, 4) do
			if not bulb:GetAttribute("Drained") then
				blink(bulb, rand)
			end
			task.wait(rand:NextNumber(0.03, 0.2))
		end
	end
end

local function killerPositions(): { Vector3 }
	local list = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local role = char and char:FindFirstChild("Role") :: StringValue?
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local effects = char and char:FindFirstChild("Effects")
		if role and root and role.Value == "Killer" and not (effects and effects:FindFirstChild("Undetectable")) then
			table.insert(list, root.Position)
		end
	end
	return list
end

local function drainNearKiller(bulbs: { BasePart })
	local rand = Random.new()
	while #bulbs > 0 and bulbs[1]:IsDescendantOf(workspace) do
		local killers = killerPositions()
		for _, bulb in bulbs do
			local near = math.huge
			for _, pos in killers do
				near = math.min(near, (pos - bulb.Position).Magnitude)
			end
			local drained = near < DRAIN_RADIUS
			if drained ~= (bulb:GetAttribute("Drained") == true) then
				bulb:SetAttribute("Drained", drained)
				setLit(bulb, not drained)
			elseif not drained and near < STUTTER_RADIUS and rand:NextNumber() < 0.3 then
				task.spawn(blink, bulb, rand)
			end
		end
		task.wait(0.25)
	end
end

return {
	Init = function()
		if not RunService:IsClient() then
			return
		end
		local bulbs = {}
		for _, bulb in workspace:WaitForChild("Map"):GetDescendants() do
			if bulb:IsA("BasePart") and bulb.Name == "Bulb" then
				table.insert(bulbs, bulb)
				if bulb:GetAttribute("Flicker") then
					task.spawn(flicker, bulb)
				end
			end
		end
		task.spawn(drainNearKiller, bulbs)
	end,
}]]
Behaviour.Parent = Root

Root.Parent = Maps
local _, size = MapModel:GetBoundingBox()
return "Instalacion built: " .. #MapModel:GetDescendants() .. " parts, size " .. tostring(size) .. ", moved out of rotation: " .. (if #moved > 0 then table.concat(moved, ", ") else "none")
