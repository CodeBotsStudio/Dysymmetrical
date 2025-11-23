--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)

return function()
    local function Execute(path: string, ...)
		local module: ModuleScript
		if path and #path > 0 then
			local steps = path:split(".")
			for index, step in steps do
				if index == 1 then
					module = game:GetService(step)
				else
					module = module:FindFirstChild(step)
				end
			end
		end
		if module:IsA("ModuleScript") then
			require(module)(...)
		end
	end

	Network:SetConnection("ExecuteReplicatedModule", "UREMOTE_EVENT", function(path: string, ...)
		Execute(path, ...)
	end)

	Network:SetConnection("ExecuteReplicatedModule", "REMOTE_EVENT", function(path: string, ...)
		Execute(path, ...)
	end)
end