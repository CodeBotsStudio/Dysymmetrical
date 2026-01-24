local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local PlayerHitboxCreator = {}

function PlayerHitboxCreator:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model, CharacterJanitor: Types.Janitor)
            --if it's a spectator, halt
            if not Character:GetAttribute("Role") or Character:GetAttribute("Role") == "Spectator" then
                return
            end

            PlayerHitboxCreator.CreateHitboxesForPlayer(Player, Character)
        end)
    end)
end

function PlayerHitboxCreator.CreateHitboxesForPlayer(Player: Player, Character: Model)
    local ManagedHitboxes = {}

    local HRP = Utils.Character.GetRootPart(Character)
    local TargetCFrame = CFrame.new(HRP.CFrame.Position)

    -- Get character config for priority
    local hurtboxPriority = 1 -- fallback
    local charName = Character:GetAttribute("CharacterName")
    local charSkin = Character:GetAttribute("CharacterSkinName")
    local roleValue = Character:FindFirstChild("Role") and Character.Role.Value
    
    if roleValue and charName and #charName > 0 then
        local moduleInstance = Utils.Instance.GetCharacterModule(roleValue, charName, charSkin)
        if moduleInstance then
            local success, mod = pcall(require, moduleInstance)
            if success and mod.GameplayConfig and type(mod.GameplayConfig.HitboxPriority) == "number" then
                hurtboxPriority = mod.GameplayConfig.HitboxPriority
            end
        end
    end
    
    --make IDs for later hitbox display
    local ID = 0
    for _, Hitbox: BasePart in script:GetChildren() do
        if not Hitbox:IsA("BasePart") then
            continue
        end

        --make its ID unique but very very low to prevent using UniqueID because it's unnecessary info
        ID += 1

        --clone it
        local HitboxClone = Hitbox:Clone()
        HitboxClone.Transparency = 1
        HitboxClone.CFrame = TargetCFrame
		HitboxClone:SetAttribute("HitboxPriority", hurtboxPriority)
        --set its ID for later hitbox display
        HitboxClone:SetAttribute("ID", ID)
        
        --weld to HRP
        local Weld = Instance.new("Weld")
        Weld.Part0 = HRP
        Weld.Part1 = HitboxClone
        Weld.Name = HitboxClone.Name
        Weld.Parent = HRP
        
        --parent it NOW instead of BEFORE so that the client can properly get the ID attribute
        HitboxClone.Parent = Character.Hitboxes

        --add it to the table for later hitbox display
        ManagedHitboxes[ID] = HitboxClone
    end

    --setup hitbox display on client
    PlayerHitboxCreator._SetupHitboxViewConnections(Player, Character, ManagedHitboxes)
end

local Framerate = 1/20
--- Sets up all available hitboxes for the passed character.
function PlayerHitboxCreator._SetupHitboxViewConnections(Player: Player, Character: Model, ManagedHitboxes: {[number]: BasePart})
    local JanitorInstance = Janitor.new()
    JanitorInstance:LinkToInstance(Character)

    local Elapsed = 0
    JanitorInstance:Add(RunService.PostSimulation:Connect(function(delta: number)
        --will wait until the 3 frames are processed
        --but only if there wasn't a frame skip because of lag
        --in which case it'll skip the check entirely and move on
        if Elapsed < Framerate then
            Elapsed += delta
            return
        end

        --subtracting to elapsed in this way just in case there is
        --for example half a frame after a small lag spike so that it can be used next check
        Elapsed -= Framerate
        if Elapsed > Framerate then
            Elapsed = 0
        end

        --get every single hitbox that still exists from the managed hitboxes JUST IN FUCKING CASE.
        local AliveHitboxes = {}
        local Count = 0
        for ID: number, Hitbox: BasePart in ManagedHitboxes do
            if not (Hitbox and Hitbox.Parent) then
                continue
            end

            Count += 1
            AliveHitboxes[ID] = Hitbox
        end

        --if there are no available hitboxes to update, halt
        if Count <= 0 then
            return
        end

        --let me break this down
        -- * header for the hitbox count (1 byte, so you can add up to 255 hitboxes)
        -- * multiplying the amount of hitboxes by 13
        --   * 1 byte for the ID
        --   * 12 bytes for XYZ
        --cool size done!!1!
        local BufferSize = 1 + (Count * 13)

        --we make the buffer
        local Buffer = buffer.create(BufferSize)
        --skipping the count byte because that's set by itself in an obvious manner below
        local Offset = 1

        --write count as the header
        buffer.writeu8(Buffer, 0, Count)

        --iterate over every alive hitbox to add it to the buffer
        for ID: number, Hitbox: BasePart in AliveHitboxes do
            --write its id as its header
            buffer.writeu8(Buffer, Offset, ID :: any)
            --move forward 1 byte
            Offset += 1

            --iterate over every axis from its position
            local Position = Hitbox.CFrame.Position
            for _, Axis in {"X", "Y", "Z"} do
                --write it as a 32 bit float, which should be more than enough (4 bytes, up to 7 decimals)
                buffer.writef32(Buffer, Offset, Position[Axis])

                --move forward 4 bytes
                Offset += 4
            end
        end

        --send it to the client to update
        Network:FireClientConnection(Player, "UpdateHitboxPosition", "UREMOTE_EVENT", Buffer)
    end))
end

return PlayerHitboxCreator
