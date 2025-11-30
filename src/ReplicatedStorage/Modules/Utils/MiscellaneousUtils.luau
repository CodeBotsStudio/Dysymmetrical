local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Modules.Network)

local MiscellaneousUtils = {}

--- Loads any assets in the function's parameter for proper use without loading them right when used.
function MiscellaneousUtils.PreloadAssets(assets: string | {string})
    task.defer(function()
        local loadedAssets = {}

        local function Fetch(assetsToFetch: any)
            if typeof(assetsToFetch) == "table" then
                for _, i in assetsToFetch do
                    pcall(Fetch, i)
                end
                return
            end

            if typeof(assetsToFetch) ~= "string" and typeof(assetsToFetch) ~= "Instance" then
                return
            end

            if typeof(assetsToFetch) == "string" and assetsToFetch:find("rbxassetid://") then
                if assetsToFetch:lower() == "soundids" and RunService:IsClient() then
                    local Sound = Instance.new("Sound")
                    Sound.Name = assetsToFetch
                    Sound.SoundId = assetsToFetch
                    Sound.Volume = 0
                    Sound.Parent = workspace.Sounds
                    Sound:Play()

                    Debris:AddItem(Sound, 1)
                end
            end
            table.insert(loadedAssets, assetsToFetch)
        end

        pcall(Fetch, assets)
        ContentProvider:PreloadAsync(loadedAssets)
    end)
end

--- Function used instead of the built-in print to trace for bugs in public playtesting.
--- If called from Server, it'll also print to all clients to trace server values.
function MiscellaneousUtils.Print(...)
    if RunService:IsServer() then
        print(...)
        if workspace:GetAttribute("DebugAllowed") == true and not RunService:IsStudio() then
            Network:FireAllClientConnection("Print", "UREMOTE_EVENT", Enum.MessageType.MessageInfo, ...)
        end
    elseif workspace:GetAttribute("DebugAllowed") == true then
        print(...)
    end
end

return MiscellaneousUtils
