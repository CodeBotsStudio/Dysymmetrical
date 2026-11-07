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

	local ramps = 0
	for _, ramp in probe:GetDescendants() do
		if ramp:IsA("BasePart") and ramp:GetAttribute("Ramp") then
			ramps += 1
			local hit = workspace:Raycast(ramp.Position + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), params)
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

	check(workspace.Terrain:GetMaterialColor(Enum.Material.Sand) == Color3.fromRGB(150, 118, 78), "falta el color del serrín")
end)
probe:Destroy()
if not ok then
	error(err, 0)
end

return "OK " .. checks .. " checks"
