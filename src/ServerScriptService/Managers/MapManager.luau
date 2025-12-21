local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Lighting = require(ReplicatedStorage.Modules.Lighting)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local MapManager = {
    --- Allows the map to not be the same to the last one.
    CanRepeatMap = true, --might want to disable on release
}

local Rand = Random.new()

function MapManager:Init()
    self.MapPrefabs = ServerStorage.Maps:GetChildren()

    for _, Map in self.MapPrefabs do
        if not Map:IsA("Folder") and not Map:IsA("Model") then
            table.remove(self.MapPrefabs, table.find(self.MapPrefabs, Map))
        end
    end

    self.CurrentMap = nil
    self.LastMap = nil
end

--- Picks a random map from `ServerStorage.Assets.Maps` and inits everything related to it, setting it as `Map` in `workspace`.
--- If `MapManager.CanRepeatMap` is true, the map will never be the same to the one chosen the round before for variety.
function MapManager:GetRandomMap(): Model | Folder
    --chooses a random map
    local SelectedMap = self.MapPrefabs[Rand:NextInteger(1, #self.MapPrefabs)]
    --if it's the same as the one before it chooses a different one
    if not self.CanRepeatMap and self.LastMap and self.LastMap == SelectedMap then
        repeat SelectedMap = self.MapPrefabs[Rand:NextInteger(1, #self.MapPrefabs)]
        until self.LastMap ~= SelectedMap
    end
    --sets the "last map" as the current map for not repeating it next time
    self.LastMap = SelectedMap

    --clones the map for usage
    local MapInstance = SelectedMap:Clone()

    --creates the InGame folder for ability instances
    if not MapInstance:FindFirstChild("InGame") then
        local InGameFolder = Instance.new("Folder")
        InGameFolder.Name = "InGame"
        InGameFolder.Parent = MapInstance
    end

    --references all of the spawn points
    local Spawns = MapInstance.Map.SpawnPoints
    local KillerSpawns = Spawns.Killers:GetChildren()
    local SurvSpawns = Spawns.Survivors:GetChildren()

    --selects a random preset
    local Index = Rand:NextInteger(1, #KillerSpawns)

    --removes any spawn points that aren't from the set preset
    for _, Spawn: BasePart in KillerSpawns do
        if Spawn:GetAttribute("Index") == nil or Spawn:GetAttribute("Index") ~= Index then
            Spawn:Destroy()
        end
    end
    for _, Spawn: BasePart in SurvSpawns do
        if Spawn:GetAttribute("Index") == nil or Spawn:GetAttribute("Index") ~= Index then
            Spawn:Destroy()
        end
    end

    --i think this is used idk lol but it's useful
    self.CurrentMap = MapInstance
    
    local Config = require(MapInstance.Config)
    if Config.Ambience then
        local Props = Config.AmbienceProperties or {}
        Props.Priority = Props.Priority or 0.5
        Props.Name = "MapAmbience"
        Sounds.PlayTheme(Config.Ambience, Props)
    end

    MapInstance.Name = "Map"
    if not MapInstance:FindFirstChild("PermAbilities") then
        local P = Instance.new("Folder")
        P.Name = "PermAbilities"
        P.Parent = MapInstance
    end
    MapInstance.Parent = workspace
    MapInstance.AncestryChanged:Connect(function()
        Sounds.StopTheme("MapAmbience")
    end)

    if MapInstance:FindFirstChild("Lighting") then
        Lighting.SetCustomLighting(MapInstance.Lighting)
    end

    if not MapInstance:FindFirstChild("Ingame") then
        local Ingame = Instance.new("Folder")
        Ingame.Name = "Ingame"
        Ingame.Parent = MapInstance
    end

    if MapInstance:FindFirstChild("Behaviour") then
        require(MapInstance.Behaviour):Init()
    end

    --returns the map instance for usage
    return MapInstance
end

function MapManager:DestroyCurrentMap()
    if self.CurrentMap then
        self.CurrentMap:Destroy()
        self.CurrentMap = nil
        Lighting.SetDefaultLighting()
    end
end

return MapManager
