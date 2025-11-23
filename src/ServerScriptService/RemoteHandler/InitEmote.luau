--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)

local EmoteFolder = ReplicatedStorage.Assets.Emotes

return function()
    Network:SetConnection("InitEmote", "REMOTE_EVENT", function(plr: Player, emoteName: string)
        if not plr.Character or not plr.Character:FindFirstChild("Humanoid") or not plr.Character.Humanoid:FindFirstChild("Animator") then
            return
        end

        if EmoteFolder:FindFirstChild(emoteName) then
            require(EmoteFolder[emoteName]):Init(plr, plr.Character.Humanoid.Animator)
        end
    end)
end