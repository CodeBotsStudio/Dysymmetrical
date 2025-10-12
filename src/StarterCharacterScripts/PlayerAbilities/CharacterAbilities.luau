local CharacterAbilities = {
    CharacterModule = {}, --this is here as a utility local for possible usage
    Abilities = {},
}

function CharacterAbilities:Init()
    local conn
    conn = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
        table.clear(CharacterAbilities.Abilities)
        conn:Disconnect()
    end)
end

return CharacterAbilities
