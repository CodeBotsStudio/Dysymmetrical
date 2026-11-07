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
p = walk(Vector3.new(118, 1.5, -42), { Vector3.new(175, 4, -45) })
table.insert(out, string.format("bowl out y=%.1f x=%.1f (want ~7, x~175)", p.Y, p.X))
p = walk(Vector3.new(0, -4, 17), { Vector3.new(0, 0, 45) })
table.insert(out, string.format("canal south wall y=%.1f (want ~-1)", p.Y))
return table.concat(out, " | ")
