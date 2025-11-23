local SoundService = game:GetService("SoundService")
return function(NewValue: number)
    SoundService.SoundGroups.Master.UI.Volume = NewValue / 100
end