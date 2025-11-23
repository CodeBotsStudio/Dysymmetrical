for _, i in script.Parent:GetDescendants() do
	if i:IsA("ModuleScript") then
		local Scr = require(i)
		if type(Scr) == "table" and Scr.Init and type(Scr.Init) == "function" then
			Scr:Init()
		end
	end
end