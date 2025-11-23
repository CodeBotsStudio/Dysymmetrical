local LocalPlayer = game:GetService("Players").LocalPlayer

return function(NewValue: number)
    LocalPlayer:SetAttribute("BaseFOV", NewValue)
end