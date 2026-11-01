--!strict
local Players = game:GetService("Players")

local STRENGTH = 0.35

return {
	Init = function(_)
		local gui = Instance.new("ScreenGui")
		gui.Name = "Vignette"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = -1
		for _, side in {
			{ UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.7), -90 },
			{ UDim2.fromScale(0.25, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.25, 1), UDim2.fromScale(0.75, 0), 180 },
		} do
			local band = Instance.new("Frame")
			band.Size = side[1]
			band.Position = side[2]
			band.BackgroundColor3 = Color3.new(0, 0, 0)
			band.BackgroundTransparency = 1 - STRENGTH
			band.BorderSizePixel = 0
			band.Parent = gui
			local fade = Instance.new("UIGradient")
			fade.Transparency = NumberSequence.new(0, 1)
			fade.Rotation = side[3]
			fade.Parent = band
		end
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end,
}
