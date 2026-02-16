--[[
	AbilityStateValidator - Validates and recovers ability state interactions
	Prevents conflicting ability states and cleans up invalid conditions
]]

local AbilityStateValidator = {}

--- Check if ability state is valid
---@param ability table The ability object
---@return boolean Is valid
---@return string? Error message if invalid
function AbilityStateValidator.ValidateAbilityState(ability: any): (boolean, string?)
	if not ability then
		return false, "Ability is nil"
	end
	
	if not ability.OwnerProperties or not ability.OwnerProperties.Character then
		return false, "Character missing"
	end
	
	local char = ability.OwnerProperties.Character
	if not char.Parent then
		return false, "Character is destroyed"
	end
	
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "Humanoid is dead"
	end
	
	return true, nil
end

--- Recover ability from invalid state
---@param ability table The ability to recover
---@return boolean Success
function AbilityStateValidator.RecoverAbilityState(ability: any): boolean
	local valid, err = AbilityStateValidator.ValidateAbilityState(ability)
	if valid then return true end
	
	-- Attempt recovery
	print(`[AbilityStateValidator] Recovering from: {err}`)
	
	-- Clear active effects
	if ability.Setup then
		ability.Setup = false
	end
	
	if ability.Cooldown and ability.Cooldown > 0 then
		ability.Cooldown = 0
	end
	
	-- Clean up connections if ability has them
	if ability._janitor then
		pcall(function() ability._janitor:Cleanup() end)
	end
	
	return false
end

--- Check for conflicting abilities in same character
---@param character Model The character to check
---@return table List of conflicting abilities
function AbilityStateValidator.FindConflictingAbilities(character: Model): {any}
	local conflicts = {}
	
	-- Check if multiple speed modifiers are active
	local speedModCount = 0
	if character:GetAttribute("SpeedModified") then
		speedModCount += 1
		table.insert(conflicts, "Multiple speed modifiers detected")
	end
	
	-- Check for harmful status overkill
	local stunned = character:FindFirstChild("Stunned")
	local slowed = character:FindFirstChild("Slowness")
	if stunned and slowed then
		table.insert(conflicts, "Stun + Slowness stack detected")
	end
	
	return conflicts
end

return AbilityStateValidator
