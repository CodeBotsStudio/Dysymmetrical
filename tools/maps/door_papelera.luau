local O = Vector3.new(2500, 0, -2500)
local character = game.Players.LocalPlayer.Character
local hrp = character.HumanoidRootPart
local humanoid = character.Humanoid

local function walk(from: Vector3, to: Vector3): Vector3
	hrp.CFrame = CFrame.new(O + from + Vector3.new(0, 3.5, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.8)
	humanoid:MoveTo(O + to)
	local t = 0
	while (hrp.Position - O - to) * Vector3.new(1, 0, 1) ~= Vector3.zero and t < 5 do
		t += task.wait(0.1)
		if ((hrp.Position - O - to) * Vector3.new(1, 0, 1)).Magnitude < 1.5 then
			break
		end
	end
	return hrp.Position - O
end

local function A(u: number, v: number): Vector3
	local a = math.rad(-12)
	return Vector3.new(185 + u * math.cos(a) - v * math.sin(a), 0, 125 + u * math.sin(a) + v * math.cos(a))
end

local out = {}
local p = walk(Vector3.new(-238, 8, -165), Vector3.new(-254, 8, -165))
table.insert(out, string.format("nave exit out x=%.1f (want <-247)", p.X))
p = walk(Vector3.new(-254, 8, -165), Vector3.new(-238, 8, -165))
table.insert(out, string.format("nave exit back x=%.1f (want <-246)", p.X))
local inside, outside = A(48, 10), A(64, 10)
p = walk(inside, outside)
table.insert(out, string.format("almacen exit out dist=%.1f (want <2)", ((p - outside) * Vector3.new(1, 0, 1)).Magnitude))
p = walk(outside, inside)
table.insert(out, string.format("almacen exit back dist=%.1f (want >7.5)", ((p - inside) * Vector3.new(1, 0, 1)).Magnitude))
return table.concat(out, " | ")
