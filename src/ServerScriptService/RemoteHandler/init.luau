--- Make a script in here (use another one as an example) to handle an independant Remote instance.

return {
	Init = function(_self)
		for _, func in script:GetChildren() do
			if not func:IsA("ModuleScript") then
				continue
			end
			require(func)()
		end
	end
}
