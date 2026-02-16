--[[
	AbilityTestFramework - Testing suite for killer abilities
	Validates ability behavior, cooldowns, and effects
]]

local AbilityTestFramework = {
	Tests = {},
	Results = {},
}

--- Define an ability test
---@param abilityName string Name of the ability to test
---@param testName string Name of this test
---@param testFunc fun(): boolean Test function that returns true if passed
function AbilityTestFramework.RegisterTest(abilityName: string, testName: string, testFunc: () -> boolean): ()
	if not AbilityTestFramework.Tests[abilityName] then
		AbilityTestFramework.Tests[abilityName] = {}
	end
	
	table.insert(AbilityTestFramework.Tests[abilityName], {
		Name = testName,
		Func = testFunc,
	})
end

--- Run tests for an ability
---@param abilityName string The ability to test
---@return number Passed tests
---@return number Total tests
function AbilityTestFramework.RunAbilityTests(abilityName: string): (number, number)
	local tests = AbilityTestFramework.Tests[abilityName] or {}
	local passed = 0
	
	print(`[Test] Running tests for {abilityName}...`)
	
	for _, test in ipairs(tests) do
		local success, result = pcall(test.Func)
		
		if success and result then
			passed += 1
			print(`  ✓ {test.Name}`)
		else
			print(`  ✗ {test.Name}`)
		end
	end
	
	print(`Passed: {passed}/{#tests}\\n`)
	
	table.insert(AbilityTestFramework.Results, {
		Ability = abilityName,
		Passed = passed,
		Total = #tests,
		Timestamp = os.clock(),
	})
	
	return passed, #tests
end

--- Run all tests
---@return number Total passed
---@return number Total tests
function AbilityTestFramework.RunAllTests(): (number, number)
	local totalPassed = 0
	local totalTests = 0
	
	print(\"\\n=== ABILITY TEST SUITE ===\")
	
	for abilityName, _ in pairs(AbilityTestFramework.Tests) do
		local passed, total = AbilityTestFramework.RunAbilityTests(abilityName)
		totalPassed += passed
		totalTests += total
	end
	
	print(f\"\\n=== FINAL RESULTS ===\")
	print(f\"Total Passed: {totalPassed}/{totalTests}\")
	print(f\"Success Rate: {math.round(totalPassed / math.max(1, totalTests) * 100)}%\\n\")
	
	return totalPassed, totalTests
end

--- Example tests for NullexVoyd
function AbilityTestFramework.RegisterNullexVoydTests(): ()
	AbilityTestFramework.RegisterTest(\"NullexVoyd\", \"DataAnchor placement\", function()
		-- Test: Ability places successfully
		return true  -- Placeholder
	end)
	
	AbilityTestFramework.RegisterTest(\"NullexVoyd\", \"DataAnchor recall\", function()
		-- Test: Ability recalls successfully
		return true  -- Placeholder
	end)
	
	AbilityTestFramework.RegisterTest(\"NullexVoyd\", \"Slowness application\", function()
		-- Test: Slowness is applied on place
		return true  -- Placeholder
	end)
	
	AbilityTestFramework.RegisterTest(\"NullexVoyd\", \"Slowness removal\", function()
		-- Test: Slowness is removed on recall
		return true  -- Placeholder
	end)
end

return AbilityTestFramework
