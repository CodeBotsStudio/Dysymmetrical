--!nocheck

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Hitbox = require(script.Parent.Hitbox)

local Projectile = {}

export type Projectile = {
    --- The player that created the projectile.
    SourcePlayer: Player,
    --- The model of the projectile.
    --- It has to have a `CollisionBox` part inside of it that acts as a hitbox for `DestroyOnCollision` if it's `true`.
    --- If it's a model, make a `Pivot` part inside it that represents the center and make it the `PrimaryPart` property.
    --- Then, weld every other part in the model to it.
    Model: Model,
    --- The initial position of the projectile.
    StartingCFrame: CFrame,
    --- The speed of the projectile.
    Speed: number,
    --- How much the projectile will rotate in its lifetime.
    --- Use `CFrame.fromEulerAnglesXYZ()` and `math.rad()` for this.
    FinalRotation: CFrame,
    --- How much time in seconds it'll take for the projectile to be removed naturally.
    Lifetime: number,
    --- The behaviour of the throw.
    --- * If it's `Forward`, it'll be thrown relative to the `Forward` vector of `StartingCFrame`.
    --- * If it's `Mouse`, it'll be thrown towards where the mouse is pointing at.
    ThrowType: "Forward" | "Mouse",
    --- The settings of the projectile's hitbox.
    HitboxSettings: Hitbox.HitboxSettings,
    --- If `true`, the projectile will be destroyed whenever it collides with a part, including players.
    DestroyOnCollision: boolean,

    --- Callback fired when the projectile is about to be destroyed by `Projectile:Destroy()` when it gets called from colliding with something when `DestroyOnCollision` is `true`.
    OnHitDestroy: (self: any) -> ()?,
    --- Callback fired when the projectile is about to be destroyed by `Projectile:Destroy()`.
    OnDestroy: (self: any) -> ()?,
}

--- Creates a new projectile instance.
--- Remember to call this function with a `.` instead of a `:`.
function Projectile.New(ProjectileSettings: Projectile): {
    --- The model of the projectile.
    Model: Model?,
    --- The hitbox associated to this projectile.
    Hitbox: {
        --- The humanoids the hitbox has already hit.
        HumanoidsHit: {Humanoid}?,
        --- The player that created this hitbox.
        Creator: Player?,
        --- The damage this hitbox deals.
        Damage: number?,
        --- The time that's passed since the creation of the hitbox.
        TimePast: number?,
        --- If the hitbox has been cancelled.
        Cancelled: boolean?,
        --- Cancels the hitbox and destroys it.
        --- Call this with a `:`.
        Cancel: (self: any) -> ()?,
    }?,
    --- Destroys this projectile by destroying the model and cancelling the hitbox.
    Destroy: (self: any) -> ()?,
}

    if not RunService:IsServer() then
        return {}
    end

    if not ProjectileSettings then
        warn("No projectile settings specified!")
        warn(debug.traceback())
        return {}
    end
    if not ProjectileSettings.SourcePlayer or not ProjectileSettings.Model or not ProjectileSettings.StartingCFrame or not ProjectileSettings.HitboxSettings then
        warn("Projectile settings missing crucial fields!")
        warn(debug.traceback())
        return {}
    end

    ProjectileSettings = {
        SourcePlayer = ProjectileSettings.SourcePlayer,
        Model = ProjectileSettings.Model,
        StartingCFrame = ProjectileSettings.StartingCFrame,
        Speed = ProjectileSettings.Speed or 50,
        FinalRotation = ProjectileSettings.FinalRotation or CFrame.new(),
        Lifetime = ProjectileSettings.Lifetime or 5,
        ThrowType = ProjectileSettings.ThrowType or "Forward",
        HitboxSettings = ProjectileSettings.HitboxSettings or {},
        DestroyOnCollision = ProjectileSettings.DestroyOnCollision or false,
    }
    ProjectileSettings.HitboxSettings.IsProjectile = true

    local ProjectileInstance = {}

    ProjectileInstance.Model = ProjectileSettings.Model:Clone()
    ProjectileInstance.Model.Parent = workspace.Map and workspace.Map.Ingame or workspace.TempObjectFolders

    ProjectileInstance.Hitbox = Hitbox:New(ProjectileSettings.SourcePlayer, ProjectileSettings.HitboxSettings)

    ProjectileSettings.HitboxSettings.CFrame = ProjectileSettings.HitboxSettings.CFrame or function(): CFrame
        return ProjectileInstance.Model.CFrame or ProjectileInstance.Model.WorldPivot
    end

    local Cancel = false
    function ProjectileInstance:Destroy()
        if ProjectileSettings.OnDestroy then
            ProjectileSettings:OnDestroy()
        end
        Cancel = true
        ProjectileInstance.Model:Destroy()
        ProjectileInstance.Hitbox:Cancel()
    end

    if ProjectileSettings.ThrowType == "Mouse" then
        local Direction = (Utils:GetPlayerMousePosition(ProjectileSettings.SourcePlayer, false) - ProjectileSettings.StartingCFrame.Position).Unit
        ProjectileSettings.StartingCFrame = CFrame.new(ProjectileSettings.StartingCFrame.Position) * CFrame.fromEulerAnglesXYZ(Direction.X, Direction.Y, Direction.Z)
    end

    if ProjectileInstance.Model:IsA("Model") then
        ProjectileInstance.Model:PivotTo(ProjectileSettings.StartingCFrame)
    else
        ProjectileInstance.Model.CFrame = ProjectileSettings.StartingCFrame
    end

    Debris:AddItem(ProjectileInstance.Model, ProjectileSettings.Lifetime)

    local Goal = ProjectileSettings.StartingCFrame * CFrame.new(0, 0, -ProjectileSettings.Speed * ProjectileSettings.Lifetime) * ProjectileSettings.FinalRotation
    TweenService:Create(ProjectileInstance.Model:IsA("Model") and ProjectileInstance.Model.Pivot or ProjectileInstance.Model, TweenInfo.new(ProjectileSettings.Lifetime), {
        CFrame = Goal,
    }):Play()

    if ProjectileSettings.DestroyOnCollision then
        task.spawn(function()
            for _ = 0, ProjectileSettings.Lifetime, 0.1 do
                if Cancel or not ProjectileInstance.Model then
                    break
                end

                local TouchingParts = workspace:GetPartsInPart(ProjectileInstance.Model.CollisionBox)
                if #TouchingParts > 0 then
                    local found = false

                    for _, i in TouchingParts do
                        if (not ProjectileSettings.SourcePlayer.Character or not i:IsDescendantOf(ProjectileSettings.SourcePlayer.Character)) and i.CanCollide and i.CollisionGroup ~= "KillerPassthrough" then
                            found = true
                            task.delay(0.04, function()
                                if ProjectileSettings.OnHitDestroy then
                                    ProjectileSettings:OnHitDestroy()
                                end
                                ProjectileInstance:Destroy()
                            end)
                            break
                        end
                    end
                    if found then
                        break
                    end
                end

                task.wait(0.1)
            end
        end)
    end

    return ProjectileInstance
end

return Projectile
