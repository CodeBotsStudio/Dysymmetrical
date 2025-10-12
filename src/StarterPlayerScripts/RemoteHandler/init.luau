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