--!strict
local checks = 0
local function check(ok: any, message: string)
	assert(ok, message)
	checks += 1
end

local root = game:GetService("ServerStorage").Maps:FindFirstChild("Papelera")
check(root, "falta ServerStorage.Maps.Papelera")
for _, name in { "Map", "Config", "Lighting", "Behaviour" } do
	check(root:FindFirstChild(name), "falta " .. name)
end
local layouts = root.Map.SpawnPoints:GetChildren()
check(#layouts >= 2, "hacen falta 2 Layouts")
for _, layout in layouts do
	check(#layout.Survivors:GetChildren() >= 4 and #layout.Killers:GetChildren() >= 1, layout.Name .. " incompleto")
end

local ORIGIN = Vector3.new(2500, 0, -2500)
local probe = root.Map:Clone()
probe.Parent = workspace
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain, probe }
local function ground(x: number, z: number): RaycastResult?
	return workspace:Raycast(ORIGIN + Vector3.new(x, 100, z), Vector3.new(0, -200, 0), params)
end
local function heightAt(x: number, z: number): number
	local hit = ground(x, z)
	return if hit then hit.Position.Y - ORIGIN.Y else -999
end

local ok, err = pcall(function()
	for _, sample in { { -200, -150, 8 }, { -50, -40, 4 }, { -100, 150, 0 }, { 100, 25, -4 } } do
		local y = heightAt(sample[1], sample[2])
		check(math.abs(y - sample[3]) <= 1, string.format("altura en (%d, %d) = %.1f, se esperaba %d", sample[1], sample[2], y, sample[3]))
	end
	local bowl = heightAt(160, -45) - heightAt(120, -45)
	check(math.abs(bowl - 3) <= 1, string.format("el cuenco del pozo tiene %.1f de hondo, se esperaba 3", bowl))

	local roofs = {}
	for _, d in probe:GetDescendants() do
		if d:GetAttribute("Roof") then
			table.insert(roofs, d)
		end
	end
	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	groundParams.FilterDescendantsInstances = { probe:FindFirstChild("Generators"), table.unpack(roofs) }
	local ramps = 0
	for _, ramp in probe:GetDescendants() do
		if ramp:IsA("BasePart") and ramp:GetAttribute("Ramp") then
			ramps += 1
			local hit = workspace:Raycast(ramp.Position + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), groundParams)
			check(hit and hit.Instance == ramp and hit.Normal.Y >= math.cos(math.rad(30)), ramp:GetFullName() .. " pasa de 30 grados o no se pisa")
		end
	end
	check(ramps >= 4, "hacen falta 2 rampas por muro de terraza")

	local canalLength = probe:GetAttribute("CanalLength")
	check(type(canalLength) == "number", "falta el atributo CanalLength")
	for _, bank in { "North", "South" } do
		local arcs = {}
		for _, exit in probe:GetDescendants() do
			if exit:GetAttribute("CanalExit") == bank then
				table.insert(arcs, exit:GetAttribute("Arc"))
			end
		end
		table.sort(arcs)
		check(#arcs >= 3, bank .. ": hacen falta 3 salidas del canal")
		local worst = math.max(arcs[1], canalLength - arcs[#arcs])
		for i = 2, #arcs do
			worst = math.max(worst, (arcs[i] - arcs[i - 1]) / 2)
		end
		check(worst <= 60, string.format("%s: hay un tramo del canal a %.0f de la salida más cercana", bank, worst))
	end

	local slabs = {}
	for _, slab in probe:GetDescendants() do
		if slab.Name == "BigSlab" then
			table.insert(slabs, slab)
		end
	end
	check(#slabs >= 3, "hacen falta 3 o 4 losas grandes en el pozo")
	for i = 1, #slabs do
		for j = i + 1, #slabs do
			local a, b = slabs[i].Position, slabs[j].Position
			local gap = Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude - slabs[i].Size.X
			check(gap >= 8, string.format("dos losas del pozo a %.1f, hace falta 8 para rodearlas", gap))
		end
	end

	local generators = probe:FindFirstChild("Generators"):GetChildren()
	check(#generators == 8, "hacen falta 8 sitios de generador, hay " .. #generators)
	check(probe.Generators:GetAttribute("ActiveCount") == 5, "Generators necesita ActiveCount = 5")
	for _, g in generators do
		local base = (g :: Model):GetPivot().Position
		local hit = workspace:Raycast(base + Vector3.new(0, 1, 0), Vector3.new(0, -12, 0), groundParams)
		check(hit and hit.Normal.Y > 0.99, g.Name .. ": el generador no está en suelo plano")
		check(Vector2.new(base.X - ORIGIN.X - 120, base.Z - ORIGIN.Z + 45).Magnitude > 30, g.Name .. ": el generador está dentro del cuenco del pozo")
	end

	local shadows, hazards, killerDoors, oneWay, zones = 0, 0, 0, 0, 0
	for _, d in probe:GetDescendants() do
		if d:IsA("Light") and d.Shadows then
			shadows += 1
		end
		hazards += if d.Name == "CanalHazard" then 1 else 0
		killerDoors += if d:GetAttribute("KillerDoor") then 1 else 0
		oneWay += if d:GetAttribute("OpenDirection") then 1 else 0
		zones += if d:GetAttribute("Zone") then 1 else 0
	end
	check(shadows <= 6, shadows .. " luces con sombra, el máximo es 6")
	check(hazards > 0, "falta el peligro del canal")
	check(killerDoors >= 1, "falta la puerta del asesino")
	check(oneWay >= 2, "faltan 2 salidas de incendios de un sentido")
	check(zones >= 6, "faltan zonas con atributo Zone")
	for _, z in probe:GetDescendants() do
		local want = z:GetAttribute("LightColor")
		if z:GetAttribute("Zone") then
			local lit = false
			for _, l in z:GetDescendants() do
				if l:IsA("Light") and typeof(want) == "Color3" and math.abs(l.Color.R - want.R) + math.abs(l.Color.G - want.G) + math.abs(l.Color.B - want.B) < 0.03 then
					lit = true
					break
				end
			end
			check(lit, z:GetFullName() .. " no tiene una luz de su color")
		end
	end
	local beacon = probe:FindFirstChild("Beacon", true)
	check(beacon and beacon.Position.Y - ORIGIN.Y > 140 and beacon:FindFirstChildOfClass("PointLight"), "falta la luz roja arriba de la chimenea")
	local props = probe:FindFirstChild("ReactiveProps")
	check(props and #props:GetChildren() >= 4, "faltan cajas sueltas en ReactiveProps")

	local hazards = {}
	for _, d in probe:GetDescendants() do
		if d.Name == "CanalHazard" then
			table.insert(hazards, d)
		end
	end
	local function inCanal(x: number, z: number): boolean
		for _, h in hazards do
			local p = h.CFrame:PointToObjectSpace(ORIGIN + Vector3.new(x, h.Position.Y - ORIGIN.Y, z))
			if math.abs(p.X) < h.Size.X / 2 and math.abs(p.Z) < h.Size.Z / 2 then
				return true
			end
		end
		return false
	end
	local function walkable(x: number, z: number): number?
		local hit = workspace:Raycast(ORIGIN + Vector3.new(x, 120, z), Vector3.new(0, -200, 0), groundParams)
		if not hit or hit.Normal.Y < 0.8 or inCanal(x, z) then
			return nil
		end
		local inst = hit.Instance
		if inst ~= workspace.Terrain and not inst:GetAttribute("Walk") and not inst:GetAttribute("Ramp") then
			return nil
		end
		return hit.Position.Y - ORIGIN.Y
	end
	local everything = RaycastParams.new()
	everything.FilterType = Enum.RaycastFilterType.Exclude
	everything.FilterDescendantsInstances = {}
	local function topAt(x: number, z: number): number
		local hit = workspace:Raycast(ORIGIN + Vector3.new(x, 200, z), Vector3.new(0, -300, 0), everything)
		return if hit then hit.Position.Y - ORIGIN.Y else -99
	end
	local open = {}
	for x = -250, 250, 10 do
		for z = -200, 200, 10 do
			local y = walkable(x, z)
			if y then
				local covered = false
				for k = 0, 15 do
					local dir = Vector2.new(math.cos(k * math.pi / 8), math.sin(k * math.pi / 8))
					for dist = 4, 20, 4 do
						if topAt(x + dir.X * dist, z + dir.Y * dist) >= y + 6 then
							covered = true
							break
						end
					end
					if covered then
						break
					end
				end
				if not covered then
					table.insert(open, string.format("(%d,%d)", x, z))
				end
			end
		end
		task.wait()
	end
	check(#open == 0, #open .. " puntos sin nada de 6 de alto a menos de 20: " .. table.concat(open, " ", 1, math.min(#open, 60)))

	check(workspace.Terrain:GetMaterialColor(Enum.Material.Sand) == Color3.fromRGB(150, 118, 78), "falta el color del serrín")
end)
probe:Destroy()
if not ok then
	error(err, 0)
end

return "OK " .. checks .. " checks"
