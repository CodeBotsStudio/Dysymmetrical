--!strict
local RunService = game:GetService("RunService")

local map = workspace:FindFirstChild("Map")
assert(map and map:FindFirstChild("Behaviour"), "no hay mapa en juego")

if RunService:IsServer() then
	workspace:SetAttribute("GeneratorsRepaired", 3)
	task.wait(0.5)
	assert(map:GetAttribute("Floracion") == true, "Floracion no se activa con 3 generadores")
	return "server OK: Floracion"
end

local results = {}
local function check(ok: any, message: string)
	assert(ok, message)
	table.insert(results, message)
end

local function find(name: string): BasePart
	return map:FindFirstChild(name, true) :: BasePart
end

local roller, hook = find("Roller"), find("Hook")
local rollerBefore, hookBefore = roller.CFrame, hook.CFrame
task.wait(0.6)
check(roller.CFrame ~= rollerBefore, "los rodillos giran")
check((hook.Position - hookBefore.Position).Magnitude > 0.001, "el gancho se balancea")

local steam, smoke = 0, 0
for _, d in map:GetDescendants() do
	if d:IsA("ParticleEmitter") then
		steam += if d.Name == "Steam" then 1 else 0
		smoke += if d.Name == "Smoke" then 1 else 0
	end
end
check(steam >= 3 and smoke >= 1, "vapor en las cubas y humo en la chimenea")

if map:GetAttribute("Floracion") then
	task.wait(1.5)
	local beacon = find("Beacon")
	check(beacon.Color.B > beacon.Color.R, "la chimenea pasa a violeta")
	local phone = find("Phone")
	local prompt = phone:FindFirstChildOfClass("ProximityPrompt")
	local ring = phone:FindFirstChild("Ring") :: Sound
	check(prompt and ring and ring.Playing, "el teléfono suena y se puede coger")
	local siren = map:FindFirstChild("Siren", true) :: Sound
	check(siren and siren.Playing and siren.TimeLength > 0, "la sirena suena desde el pozo")
	check(prompt.KeyboardKeyCode == Enum.KeyCode.C and prompt.GamepadKeyCode == Enum.KeyCode.ButtonX, "el teléfono se coge con C o con X del mando")
	local hrp = (game:GetService("Players").LocalPlayer.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
	while (hrp.Position - phone.Position).Magnitude > 5 do
		local step = phone.Position + Vector3.new(0, 0, 3.6) - hrp.Position
		hrp.CFrame = CFrame.new(hrp.Position + step.Unit * math.min(step.Magnitude, 300))
		task.wait(0.2)
	end
	task.wait(0.5)
	prompt:InputHoldBegin()
	prompt:InputHoldEnd()
	task.wait(1)
	local call = game:GetService("SoundService"):FindFirstChild("Call") :: Sound
	check(call and call.Playing and call.TimePosition > 0.3 and not ring.Playing, "al coger el teléfono suena la llamada")
end

return "client OK: " .. table.concat(results, ", ")
