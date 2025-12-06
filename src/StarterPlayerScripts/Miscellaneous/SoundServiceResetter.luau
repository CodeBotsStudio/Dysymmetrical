local SoundServiceResetter = {}

local SoundService = game:GetService("SoundService")

function SoundServiceResetter:Init()
    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
        for _, Descendant in SoundService.SoundGroups:GetDescendants() do
            if not Descendant:IsA("SoundGroup") then
                Descendant:Destroy()
            end
        end
    end)
end

return SoundServiceResetter
