local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Lighting = require(ReplicatedStorage.Modules.Lighting)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Utils = require(ReplicatedStorage.Modules.Utils)

local MapManager = {
    --- Allows the map to not be the same to the last one.
    CanRepeatMap = true, --might want to disable on release
    CurrentMap = nil,
    LastMap = nil,
}

local Rand = Random.new()

function MapManager:Init()
    MapManager.MapPrefabs = ServerStorage.Maps:GetChildren()

    -- iterating backwards to not have to do `table.find()` every single time i want to remove a map from the table
	for i = #MapManager.MapPrefabs, 1, -1 do
		local Map = MapManager.MapPrefabs[i]
		if not Map:IsA("Folder") and not Map:IsA("Model") then
			table.remove(MapManager.MapPrefabs, i)
		end
	end

    -- this was fucking useless -dys
    -- MapManager.CurrentMap = nil
    -- MapManager.LastMap = nil
end

--- Picks a random map from `ServerStorage.Assets.Maps` and inits everything related to it, setting it as `Map` in `workspace`.
--- If `MapManager.CanRepeatMap` is true, the map will never be the same to the one chosen the round before for variety.
function MapManager.GetRandomMap(): Model | Folder
    --chooses a random map
    local SelectedMap = MapManager.MapPrefabs[Rand:NextInteger(1, #MapManager.MapPrefabs)]
    --if it's the same as the one before it chooses a different one
    if not MapManager.CanRepeatMap and MapManager.LastMap and #MapManager.MapPrefabs > 1 then
        while SelectedMap == MapManager.LastMap do
            SelectedMap = MapManager.MapPrefabs[Rand:NextInteger(1, #MapManager.MapPrefabs)]
        end
    end
    --sets the "last map" as the current map for not repeating it next time
    MapManager.LastMap = SelectedMap

    --clones the map for usage
    local MapInstance = SelectedMap:Clone()

    --creates the InGame folder for ability instances
    if not MapInstance:FindFirstChild("InGame") then
        local InGameFolder = Instance.new("Folder")
        InGameFolder.Name = "InGame"
        InGameFolder.Parent = MapInstance
    end

    --creates the Items folder for spawned `PickableItem`s
    if not MapInstance:FindFirstChild("Items") then
        local ItemsFolder = Instance.new("Folder")
        ItemsFolder.Name = "Items"
        ItemsFolder.Parent = MapInstance
    end

    --TODO: make random PickableItem spawns

    local ActualMap = MapInstance:FindFirstChild("Map")

    task.spawn(function()
        --checks if there are item spawn spots around
        local ItemSpawns = ActualMap:FindFirstChild("ItemSpawns")
        if not ItemSpawns then
            return
        end

        --every item should have its own folder with possible spawn spots
        for _, child in ItemSpawns:GetChildren() do
            if not child:IsA("Folder") then
                continue
            end

            --each folder should be named after its PickableItem
            local ItemEquivalent = ReplicatedStorage.Assets.PickableItems:FindFirstChild(child.Name)
            if not ItemEquivalent then
                return
            end
            ItemEquivalent = require(ItemEquivalent)

            for _, spawnPoint in child:GetChildren() do
                --every spawn point should be an anchored, invisible part
                if not spawnPoint:IsA("BasePart") then
                    continue
                end

                --you can add a Chance attribute to every spawn to have a 1 every X chance for the item to spawn there
                --by default it'll be a 1/10 chance
                local Chance = spawnPoint:GetAttribute("Chance") or 10
                local Result = Rand:NextInteger(1, Chance)
                if Result ~= 1 then
                    continue
                end

                --spawning the object
                local ItemInstance = Utils.Type.CopyTable(ItemEquivalent)
                ItemInstance:Init()

                --applies the exact same cframe as the spawn point
                local TargetCFrame = spawnPoint.CFrame

                --if the axis is supposed to be random then do so
                local RandomizedAxis = ItemEquivalent.RandomRotation
                if RandomizedAxis then
                    local RandomRotation = Vector3.new()
                    local AxisTable = RandomizedAxis == "All" and {"X", "Y", "Z"} or RandomizedAxis

                    for _, Axis in AxisTable do
                        RandomRotation[Axis] = Rand:NextInteger(0, 359)
                    end

                    TargetCFrame *= CFrame.fromEulerAnglesXYZ(math.rad(RandomRotation.X), math.rad(RandomRotation.Y), math.rad(RandomRotation.Z))
                end

                --if any offset is present, apply it
                if ItemEquivalent.CFrameOffset then
                    TargetCFrame *= ItemEquivalent.CFrameOffset
                end

                --place it where it's supposed to be
                ItemInstance.ModelInstance:PivotTo(TargetCFrame)
            end
        end
    end)

    --checks if there's more than 1 layout available
    local Spawnpoints = ActualMap:FindFirstChild("SpawnPoints")
    local AvailableLayouts = Spawnpoints:GetChildren()
    if #AvailableLayouts > 2 then
        --chooses a random layout from the spawnpoint pool
        local ChosenLayout = AvailableLayouts[Rand:NextInteger(1, #AvailableLayouts)]
        --destroys the rest to ensure that the chosen one is the only one available
        for _, Layout in AvailableLayouts do
            if Layout == ChosenLayout then
                continue
            end

            Layout:Destroy()
        end
    end

    --i think this is used idk lol but it's useful
    MapManager.CurrentMap = MapInstance
    
    --tries to find the map's config module
    local ConfigModule = MapInstance:FindFirstChild("Config")
    if ConfigModule then
        local Config = require(ConfigModule)
        --will apply the ambience music if it's there
        if Config.Ambience then
            local Props = Config.AmbienceProperties or {}
            Props.Priority = Props.Priority or 0.5
            Props.Name = "MapAmbience"
            Sounds.PlayTheme(Config.Ambience, Props)
        end
    end

    --renaming to generalize it
    MapInstance.Name = "Map"
    --creates PermAbilities folder if it isn't there
    if not MapInstance:FindFirstChild("PermAbilities") then
        local P = Instance.new("Folder")
        P.Name = "PermAbilities"
        P.Parent = MapInstance
    end
    --parented to workspace
    MapInstance.Parent = workspace
    --if it gets destroyed then the theme stops
    MapInstance.AncestryChanged:Connect(function()
        Sounds.StopTheme("MapAmbience")
    end)

    --will apply the lighting module if it's there
    local LightingModule = MapInstance:FindFirstChild("Lighting")
    if LightingModule then
        Lighting.SetCustomLighting(LightingModule)
    end

    --will execute a behaviour module if it exists for either custom map events or sfx that need to be initialized
    local BehaviourModule = MapInstance:FindFirstChild("Behaviour")
    if BehaviourModule then
        local Behaviour = require(MapInstance.Behaviour)
        if Behaviour.Init and typeof(Behaviour.Init) == "function" then
            Behaviour:Init()
        end
    end

    --returns the map instance for usage
    return MapInstance
end

function MapManager.DestroyCurrentMap()
    if MapManager.CurrentMap then
        MapManager.CurrentMap:Destroy()
        MapManager.CurrentMap = nil
        Lighting.SetDefaultLighting()
    end
end

return MapManager
