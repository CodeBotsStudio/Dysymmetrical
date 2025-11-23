local SoundService = game:GetService("SoundService")
return function(NewValue: number)
    SoundService.SoundGroups.Master.Music.Volume = NewValue / 100
end