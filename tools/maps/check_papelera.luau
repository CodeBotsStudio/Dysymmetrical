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

return "OK " .. checks .. " checks"
