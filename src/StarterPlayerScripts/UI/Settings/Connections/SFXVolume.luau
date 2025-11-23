local SoundService = game:GetService("SoundService")
return function(NewValue: number)
    SoundService.SoundGroups.Master.SFX.Volume = NewValue / 100
end