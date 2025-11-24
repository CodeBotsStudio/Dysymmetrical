local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Modules.Network)

local Utils = {
    --- UDim utils to not have to repeat creations.
    UDim = {
        Zero = UDim2.new(0, 0, 0, 0),
        FullY = UDim2.fromScale(0, 1),
        Full20Offset = UDim2.new(1, -20, 1, -20),
        Full = UDim2.fromScale(1, 1),
    },

    --- The levels of each mod rank.
    Ranks = {
		Owner = 1,
		LeadDeveloper = 5,
		HeadModerator = 10,
		Moderator = 15,
		Developer = 18,
		ServerOwner = 20,
		DefaultPlayer = 30,
    },

    TransparentParts = {},

    -- requiring all children like this to have proper autocompletion

    Player = require(script.PlayerUtils),
    Character = require(script.CharacterUtils),
    Instance = require(script.InstanceUtils),
    Misc = require(script.MiscellaneousUtils),
    Type = require(script.TypeUtils),
    PlayerData = require(script.PlayerDataUtils),
    Math = require(script.MathUtils),
}

--- If you change this, you're a bum.
Utils.Credits = [[

######  #     #  #####  #     # #     # #     # ####### ####### ######   ###   #####     #    #       
#     #  #   #  #     #  #   #  ##   ## ##   ## #          #    #     #   #   #     #   # #   #       
#     #   # #   #         # #   # # # # # # # # #          #    #     #   #   #        #   #  #       
#     #    #     #####     #    #  #  # #  #  # #####      #    ######    #   #       #     # #       
#     #    #          #    #    #     # #     # #          #    #   #     #   #       ####### #       
#     #    #    #     #    #    #     # #     # #          #    #    #    #   #     # #     # #       
######     #     #####     #    #     # #     # #######    #    #     #  ###   #####  #     # ####### 


This game is using Dysymmetrical, an open-source asymmetrical game engine available on GitHub.
Credits to Dyscarn for making it! (hello!)
]]

function Utils:Init()
    if not RunService:IsServer() then
        local function AddToR(i)
            if i:IsA("BasePart") and i.Transparency >= 0.75 then
                Utils.TransparentParts[i] = true
            end
        end
        task.defer(function()
            for _, i in workspace:GetDescendants() do
                AddToR(i)
            end
            workspace.DescendantAdded:Connect(AddToR)
            workspace.DescendantRemoving:Connect(function(i)
                if Utils.TransparentParts[i] then
                    Utils.TransparentParts[i] = nil
                end
            end)
        end)

        Network:SetConnection("RevealPlayerAura", "REMOTE_EVENT", function(RevealedPlayer: Player | Model, Duration: number?, Color: Color3?)
            Utils.Player.RevealPlayerAura(RevealedPlayer, Duration, Color)
        end)

        Network:SetConnection("Fade", "REMOTE_EVENT", function(FadeType: "In" | "Out", Duration: number, Yield: boolean?, StartTransparency: number?, FadeColor: {R: number, G: number, B: number}?)
            Utils.Player._Fade(FadeType, Duration, Yield, StartTransparency, FadeColor)
        end)

        Network:SetConnection("GetMousePosition", "REMOTE_FUNCTION", function(v)
            return Utils.Player._GetMousePosition(v)
        end)
        Network:SetConnection("ShakeCamera", "REMOTE_EVENT", function(Magnitude: number, Duration: number)
            return Utils.Player.ShakeCamera(Magnitude, Duration)
        end)

        return
    end

    Network:SetConnection("CreateMissingSkinValue", "REMOTE_FUNCTION", function(SourcePlayer: Player, name: string)
        return Utils.PlayerData.CreateMissingSkinValue(SourcePlayer, name)
    end)
    Network:SetConnection("CreateMissingPurchasedSkinValue", "REMOTE_FUNCTION", function(SourcePlayer: Player, name: string)
        return Utils.PlayerData.CreateMissingPurchasedSkinValue(SourcePlayer, name)
    end)
    Network:SetConnection("GetMousePosition", "REMOTE_FUNCTION", function(v)
        return Utils.Player._GetMousePosition(v)
    end)
end

-- making this a metatable so that function calls from already existing scripts don't break
return setmetatable(Utils, {
    -- __index = function(self, name: string)
    --     if not self[name] then
    --         -- tries to index in the table's contents unrecursively
    --         for _, section in self do
    --             if typeof(section) ~= "table" then
    --                 continue
    --             end

    --             if section[name] then
    --                 return section[name]
    --             end
    --         end

    --         return
    --     end

    --     return self[name]
    -- end,
    __index = Utils,
})
