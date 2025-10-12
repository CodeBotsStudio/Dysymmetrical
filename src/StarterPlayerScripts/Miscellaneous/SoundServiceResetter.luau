local SoundServiceResetter = {}

local SoundService = game:GetService("SoundService")

function SoundServiceResetter:Init()
    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
        for _, i in SoundService.SoundGroups:GetDescendants() do
            if not i:IsA("SoundGroup") then
                i:Destroy()
            end
        end
    end)
end

return SoundServiceResetter
