local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
return {
    Init = function(_)
        Players.LocalPlayer.CharacterAdded:Connect(function()
            if Lighting:FindFirstChild("HealthDesat") then
                Lighting.HealthDesat:Destroy()
            end
        end)
    end,
}