--!strict
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

return {
    Init = function()
        ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
            if not prompt:GetAttribute("SurvivorOnly") then
                return
            end
            local character = Players.LocalPlayer.Character
            local role = character and character:FindFirstChild("Role") :: StringValue?
            if not role or role.Value ~= "Survivor" then
                prompt.Enabled = false
            end
        end)
    end,
}
