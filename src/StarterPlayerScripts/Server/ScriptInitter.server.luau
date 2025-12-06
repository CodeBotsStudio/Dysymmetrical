for _, Module in script.Parent:GetDescendants() do
	if not Module:IsA("ModuleScript") then
		continue
	end

	local Scr = require(Module)
	if type(Scr) == "table" and Scr.Init and type(Scr.Init) == "function" then
		Scr:Init()
	end
end