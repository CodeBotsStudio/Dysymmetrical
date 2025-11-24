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
        local checkedAssets = {}

        local function Fetch(assetsToFetch: string | {string})
            if typeof(assetsToFetch) == "string" then
                table.insert(loadedAssets, assetsToFetch)
                table.insert(checkedAssets, assetsToFetch)
                return
            end
            
            for t, asset in assetsToFetch do
                if table.find(checkedAssets, asset) then
                    continue
                end
                
                if typeof(asset) == "table" then
                    pcall(Fetch, asset)

                elseif typeof(asset) == "string" and asset:find("rbxassetid://") then
                    if t == "SoundIDs" and RunService:IsClient() then
                        local Sound = Instance.new("Sound")
                        Sound.Name = asset
                        Sound.SoundId = asset
                        Sound.Volume = 0
                        Sound.Parent = workspace.Sounds
                        Sound:Play()

                        Debris:AddItem(Sound, 1)
                    end

                    table.insert(loadedAssets, asset)
                end
                table.insert(checkedAssets, asset)
            end
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
