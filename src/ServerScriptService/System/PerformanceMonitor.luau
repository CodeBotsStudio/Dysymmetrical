--[[
	PerformanceMonitor - Tracks game performance metrics
	Identifies bottlenecks and logs statistics
]]

local PerformanceMonitor = {
	Metrics = {},
}

local RunService = game:GetService("RunService")
local interval = 0

--- Start collecting performance metrics
function PerformanceMonitor.Start(): ()
	if not RunService:IsServer() then return end
	
	RunService.Heartbeat:Connect(function(deltaTime)
		interval += deltaTime
		
		if interval >= 5 then  -- Every 5 seconds
			local metrics = {
				Timestamp = os.time(),
				Memory = collectgarbage("count"),
				DeltaTime = deltaTime,
				ThreadCount = debug.getinfo(1).namewhat,
			}
			
			table.insert(PerformanceMonitor.Metrics, metrics)
			
			-- Keep only last 100 samples
			if #PerformanceMonitor.Metrics > 100 then
				table.remove(PerformanceMonitor.Metrics, 1)
			end
			
			if deltaTime > 0.1 then  -- Frame spikes
				warn(`[Performance] Spike detected: {math.round(deltaTime * 1000)}ms frame time`)
			end
			
			interval = 0
		end
	end)
end

--- Get average memory usage
---@return number Average memory in KB
function PerformanceMonitor.GetAverageMemory(): number
	if #PerformanceMonitor.Metrics == 0 then return 0 end
	
	local sum = 0
	for _, metric in ipairs(PerformanceMonitor.Metrics) do
		sum += metric.Memory
	end
	
	return sum / #PerformanceMonitor.Metrics
end

--- Get peak memory usage
---@return number Peak memory in KB
function PerformanceMonitor.GetPeakMemory(): number
	local peak = 0
	for _, metric in ipairs(PerformanceMonitor.Metrics) do
		peak = math.max(peak, metric.Memory)
	end
	return peak
end

--- Print performance report
function PerformanceMonitor.PrintReport(): ()
	print("[Performance Report]")
	print(`Average Memory: {math.round(PerformanceMonitor.GetAverageMemory())} KB`)
	print(`Peak Memory: {math.round(PerformanceMonitor.GetPeakMemory())} KB`)
	print(`Samples: {#PerformanceMonitor.Metrics}`)
end

return PerformanceMonitor