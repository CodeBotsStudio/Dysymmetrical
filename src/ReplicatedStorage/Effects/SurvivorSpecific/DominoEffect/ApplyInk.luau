--!nocheck
return function()
    local Effect = require(script.Parent)

    local TemporaryUI = game:GetService("Players").LocalPlayer.PlayerGui.TemporaryUI
	local UI = Effect.Splatter:Clone()
	UI.Parent = TemporaryUI
	require(UI:FindFirstChildOfClass("ModuleScript"))()
end