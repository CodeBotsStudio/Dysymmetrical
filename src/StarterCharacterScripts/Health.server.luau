-- Gradually regenerates the Humanoid's Health over time.

--[[local REGEN_RATE = 1/100 -- Regenerate this fraction of MaxHealth per second.
local REGEN_STEP = 1 -- Wait this long between each regeneration step.

--------------------------------------------------------------------------------

local Character = script.Parent
local Humanoid = Character:WaitForChild('Humanoid')

--------------------------------------------------------------------------------

while true do
	while Humanoid.Health < Humanoid.MaxHealth do
		local dt = task.wait(REGEN_STEP)
		local dh = dt*REGEN_RATE*Humanoid.MaxHealth
		Humanoid.Health = math.min(Humanoid.Health + dh, Humanoid.MaxHealth)
	end
	Humanoid.HealthChanged:Wait()
end]]

local Config = {
    RegenRate = 0, --1/100
    RegenStepInSeconds = 1,
}

local char = script.Parent
local Humanoid = char:FindFirstChildOfClass("Humanoid")

if Config.RegenRate > 0 and Config.RegenStepInSeconds > 0 then
    while Humanoid.HealthChanged:Wait() do
        while Humanoid.Health < Humanoid.MaxHealth do
            local Delta = task.wait(Config.RegenStepInSeconds)
            local DH = Delta * Config.RegenRate * Humanoid.MaxHealth
            Humanoid.Health = math.min(Humanoid.Health + DH, Humanoid.MaxHealth)
        end
    end
end
