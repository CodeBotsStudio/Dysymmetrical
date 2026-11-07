local O = Vector3.new(2500, 0, -2500)
local character = game.Players:GetPlayers()[1].Character
local hrp = character.HumanoidRootPart
local humanoid = character.Humanoid
local map = workspace:WaitForChild("Map")

local function walk(from: Vector3, targets: { Vector3 }): Vector3
	hrp.CFrame = CFrame.new(O + from + Vector3.new(0, 3.5, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.8)
	for _, target in targets do
		humanoid:MoveTo(O + target)
		local done = false
		local conn = humanoid.MoveToFinished:Connect(function() done = true end)
		local t = 0
		while not done and t < 7 do
			t += task.wait(0.1)
		end
		conn:Disconnect()
	end
	return hrp.Position - O
end

local exit
for _, r in map:GetDescendants() do
	if r:GetAttribute("CanalExit") == "North" and (not exit or r:GetAttribute("Arc") < exit:GetAttribute("Arc")) then
		exit = r
	end
end
local low = exit:GetAttribute("Low")
local up = (Vector3.new(exit.Position.X, 0, exit.Position.Z) - O - Vector3.new(low.X, 0, low.Z)).Unit
local top = exit.Position - O + up * (exit.Size.Z / 2)

local out = {}
local p = walk(low - up * 4, { top - up * 1, top + Vector3.new(0, 0, -12) })
table.insert(out, string.format("canal->exit->bank y=%.1f (want ~7)", p.Y))
p = walk(Vector3.new(-60, 4, -77), { Vector3.new(-60, 8, -100) })
table.insert(out, string.format("wall no ramp y=%.1f z=%.1f (want ~7, stops at the wall face, z>-82)", p.Y, p.Z))
p = walk(Vector3.new(-150, 4, -62), { Vector3.new(-150, 8, -115) })
table.insert(out, string.format("terrace ramp y=%.1f (want ~11)", p.Y))
p = walk(Vector3.new(118, 1.5, -46), { Vector3.new(168, 4, -46) })
table.insert(out, string.format("bowl out y=%.1f x=%.1f (want ~7, x~168)", p.Y, p.X))
p = walk(Vector3.new(0, -4, 17), { Vector3.new(0, 0, 45) })
table.insert(out, string.format("canal south wall y=%.1f (want ~-1)", p.Y))
local function rot(cx: number, cz: number, angle: number, u: number, v: number, y: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(cx + u * math.cos(a) - v * math.sin(a), y, cz + u * math.sin(a) + v * math.cos(a))
end
p = walk(Vector3.new(195, 8, -158), { Vector3.new(195, 8, -170), Vector3.new(177, 8, -168), Vector3.new(177, 17, -188), Vector3.new(195, 17, -190) })
table.insert(out, string.format("oficinas mezzanine y=%.1f (want ~20)", p.Y))
p = walk(rot(40, -55, 13, -48, 10.5, 4), { rot(40, -55, 13, -18, 10.5, 14), rot(40, -55, 13, 40, 10.5, 14), rot(40, -55, 13, 64, 10.5, 14), rot(40, -55, 13, 76, 10.5, 4) })
table.insert(out, string.format("catwalk drop y=%.1f x=%.1f (want <8, x>95)", p.Y, p.X))
p = walk(rot(40, -55, 13, 8.5, -9, 4), { rot(40, -55, 13, 8.5, 9, 4) })
local gap = p - rot(40, -55, 13, 8.5, 9, p.Y)
table.insert(out, string.format("rodillos gap past generator off=%.1f (want <2)", Vector2.new(gap.X, gap.Z).Magnitude))
p = walk(Vector3.new(190, 8, -182), { Vector3.new(190, 8, -192), Vector3.new(200, 8, -191), Vector3.new(210, 8, -191) })
table.insert(out, string.format("oficinas despachos x=%.1f z=%.1f (want x>208)", p.X, p.Z))
for _, deck in map:GetDescendants() do
	if deck.Name == "Deck" then
		local look = deck.CFrame.LookVector
		p = walk(deck.Position - O - look * 26 + Vector3.new(0, 0.5, 0), { deck.Position - O + look * 34 })
		table.insert(out, string.format("crossing x=%.0f y=%.1f along=%.1f (want ~3, ~34)", deck.Position.X - O.X, p.Y, (p - (deck.Position - O)):Dot(look)))
	end
end
p = walk(rot(185, 125, -12, 60, -40.75, 0), { rot(185, 125, -12, 25, -40.75, 4) })
table.insert(out, string.format("dock y=%.1f (want ~7)", p.Y))
p = walk(Vector3.new(162, 8, -190), { Vector3.new(180, 8, -190) })
table.insert(out, string.format("killer door as survivor x=%.1f (want <169)", p.X))
local groups = {}
for _, part in character:GetDescendants() do
	if part:IsA("BasePart") then
		groups[part] = part.CollisionGroup
		part.CollisionGroup = "Killer"
	end
end
p = walk(Vector3.new(162, 8, -190), { Vector3.new(180, 8, -190) })
table.insert(out, string.format("killer door as killer x=%.1f (want >172)", p.X))
for part, group in groups do
	part.CollisionGroup = group
end
local hazard
for _, h in map:GetDescendants() do
	if h.Name == "CanalHazard" and (not hazard or (h.Position - O).Magnitude < (hazard.Position - O).Magnitude) then
		hazard = h
	end
end
humanoid.Health = 12
hrp.CFrame = CFrame.new(Vector3.new(hazard.Position.X, O.Y - 0.5, hazard.Position.Z))
task.wait(6)
local first = humanoid.Health
task.wait(3)
table.insert(out, string.format("canal health %.0f then %.0f (want 1, 1)", first, humanoid.Health))
humanoid.Health = humanoid.MaxHealth
return table.concat(out, " | ")
