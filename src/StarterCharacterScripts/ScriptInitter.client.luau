local Server = script.Parent:FindFirstChild("Server") or script.Parent:WaitForChild("Server", 30)

for _, i in script.Parent:GetDescendants() do
	if i:IsA("ModuleScript") and not i:IsDescendantOf(Server) then
		local Scr = require(i)
		if type(Scr) == "table" and Scr["Init"] and type(Scr["Init"]) == "function" then
			Scr:Init()
		end
	end
end