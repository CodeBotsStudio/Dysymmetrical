local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LERP_ALPHA = 0.25
local FOWARD_LEAN_ANGLE = math.rad(10)
local SIDE_LEAN_ANGLE = math.rad(35)

local TARGET_FPS = 60
local TARGET_DELTA = 1 / TARGET_FPS

local camera = workspace.CurrentCamera

local TurnToMoveDirection = {
    HeadPreventionFactors = {},
}

function TurnToMoveDirection:Init()
    Utils.Player.ObservePlayers(function(Player: Player, PlayerJanitor: Types.Janitor)
        PlayerJanitor:Add(Utils.Character.ObserveHumanoid(Player, function(Humanoid: Humanoid, HumanoidJanitor: Types.Janitor)
            TurnToMoveDirection._SetupHumanoid(Player, Humanoid, HumanoidJanitor)
        end))
    end)
end

--- Adds a head prevention factor.
--- 
--- If at least one is present in the table, the local player's head won't rotate relatively to the camera's position and rotation.
function TurnToMoveDirection.AddHeadPreventionFactor(name: string)
    TurnToMoveDirection.HeadPreventionFactors[name] = true
end

--- Removes a head prevention factor.
--- 
--- If at least one is present in the table, the local player's head won't rotate relatively to the camera's position and rotation.
function TurnToMoveDirection.RemoveHeadPreventionFactor(name: string)
    TurnToMoveDirection.HeadPreventionFactors[name] = nil
end

--- INTERNAL FUNCTION: Sets up a `Humanoid`'s connections to make this work.
function TurnToMoveDirection._SetupHumanoid(Player: Player, Humanoid: Humanoid, humanoidJanitor: Types.Janitor)
    local character = Humanoid.Parent
    --TODO: support for r15 and customs
    --if it's a non-r6 rig, halt, will probably make support for every rig in the future
    if character:GetAttribute("CustomRig") or Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        return
    end

    --get the root
    local rootPart = Utils.Character.GetRootPart(character)
    --get base parts
    local torso: BasePart = character:FindFirstChild("Torso") or character:FindFirstChild("LowerTorso")
    local head: BasePart = character:FindFirstChild("Head")

    --get joints involved
    local joints: {[string]: Motor6D} = {
        RootJoint = rootPart:FindFirstChild("RootJoint") or torso:FindFirstChild("Root"),
        Neck = torso:FindFirstChild("Neck") or head:FindFirstChild("Neck"),
        RightShoulder = torso:FindFirstChild("Right Shoulder") or Utils.Instance.FindFirstChild(character, "RightUpperArm.RightShoulder", 0),
        LeftShoulder = torso:FindFirstChild("Left Shoulder") or Utils.Instance.FindFirstChild(character, "LeftUpperArm.LeftShoulder", 0),
        RightHip = torso:FindFirstChild("Right Hip") or Utils.Instance.FindFirstChild(character, "RightUpperLeg.RightHip", 0),
        LeftHip = torso:FindFirstChild("Left Hip") or Utils.Instance.FindFirstChild(character, "LeftUpperLeg.LeftHip", 0),
    }

    --tables for later
    local defaultC0s = {}
    local offsets = {}

    --set defaults
    for name, joint in joints do
        defaultC0s[name] = joint.C0
        offsets[name] = CFrame.identity
    end

    --lerp util for joint offsets
    local function lerpTilt(name: string, angles: {number}, deltaTimeSim: number)
        offsets[name] = offsets[name]:Lerp(CFrame.Angles(table.unpack(angles)), LERP_ALPHA * deltaTimeSim)
    end

    --making accumulator to allow this to run at a specific framerate
    local Accumulator = 0
    --renderstepped but cooler
    humanoidJanitor:Add(RunService.PreSimulation:Connect(function(deltaTimeSim: number)
        --increase accuulator
        Accumulator += deltaTimeSim
        --if the accumulator hasn't reached the set fps minimum, halt
        if Accumulator < TARGET_DELTA then
            return
        end

        --adapt the delta according to the accumulator
        deltaTimeSim = Accumulator * 60
        --reset accumulator
        Accumulator = 0

        --get the real move direction of the character through the humanoid's input based on the root's rotation
        local moveDirection = rootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)

        --clamping values
        local x = math.clamp(moveDirection.X, -1, 1)
        local z = math.clamp(moveDirection.Z, -1, 1)

        --angles
        local forwardLean = -z * FOWARD_LEAN_ANGLE
        local sideLean = -x * SIDE_LEAN_ANGLE
        -- isBackward = z > 0.5
        local hipTiltFactor = z > 0.5 and 1 or -1

        --iterate over every joint and lerp its C0 to its target
        for name, angles in {
            --not explaining any of these values.
            RootJoint = {forwardLean, 0, sideLean * -hipTiltFactor},
            Neck = {-forwardLean * 0.5, 0, -sideLean * 0.5},
            Shoulder = {0, x * math.rad(10), 0},
            Hip = {0, hipTiltFactor * x * math.rad(20), 0},
        } do
            --if it's a leg or an arm, do it for both left and right
            if name:lower() == "hip" or name:lower() == "shoulder" then
                for _, side in {"Left", "Right"} do
                    lerpTilt(side..name, angles, deltaTimeSim)
                end

                continue
            end

            --lerp
            lerpTilt(name, angles, deltaTimeSim)
        end

        --set the C0s
        for name, joint in joints do
            if name == "Neck" then
                continue
            end
            joint.C0 = defaultC0s[name] * offsets[name]
        end

        --neck will only work for the local player so, if the target player isn't the local player, halt here
        if Player ~= Players.LocalPlayer then
            return
        end

        --calculate lots of stuff (again, too lazy to explain all of this)
        local cameraLook = camera.CFrame.LookVector
        local torsoLook = torso.CFrame.LookVector
        local headPos = head.Position
        local targetPos = headPos + cameraLook * 10

        local dist = (headPos - targetPos).Magnitude
        local diff = head.Position.Y - targetPos.Y

        local finalx = (((headPos - targetPos).Unit):Cross(torsoLook)).Y * -1
        local y = (math.atan(diff / dist) / 2)

        --lerp if there are no head prevention factors
        --otherwise, just set it to the default value
        joints.Neck.C0 = Utils.Type.GetCountOfDict(TurnToMoveDirection.HeadPreventionFactors) <= 0 and joints.Neck.C0:Lerp(defaultC0s["Neck"] * CFrame.Angles(y, 0, -finalx), LERP_ALPHA * deltaTimeSim) or defaultC0s["Neck"]
    end))
end

return TurnToMoveDirection