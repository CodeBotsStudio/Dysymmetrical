local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Hitbox = require(script.Parent.Hitbox)

local Projectile = {
    DefaultConfig = {
        Speed = 50,
        FinalRotation = CFrame.new(),
        Lifetime = 5,
        ThrowType = "Forward",
        HitboxSettings = {},
        DestroyOnCollision = false,
    },
}

--- Holds data for any given projectile
export type Projectile = {
    --- The player that created the projectile.
    SourcePlayer: Player,
    --- The model of the projectile.
    --- It has to have a `CollisionBox` part inside of it that acts as a hitbox for `DestroyOnCollision` if it's `true`.
    --- If it's a model, make a `Pivot` part inside it that represents the center and make it the `PrimaryPart` property.
    --- Then, weld every other part in the model to it.
    -- TODO: fix MODEL projectiles since only BasePart projectiles work properly
    Model: (Model | BasePart),
    --- The initial position of the projectile.
    StartingCFrame: CFrame?,
    --- The speed of the projectile.
    Speed: number,
    --- How much the projectile will rotate in its lifetime.
    --- Use `CFrame.fromEulerAnglesXYZ()` and `math.rad()` for this.
    FinalRotation: CFrame?,
    --- How much time in seconds it'll take for the projectile to be removed naturally.
    Lifetime: number,
    --- The behaviour of the throw.
    --- * If it's `Forward`, it'll be thrown relative to the `Forward` vector of `StartingCFrame`.
    --- * If it's `Mouse`, it'll be thrown towards where the mouse is pointing at.
    ThrowType: ("Forward" | "Mouse")?,
    --- The settings of the projectile's hitbox.
    HitboxSettings: Hitbox.HitboxSettings?,
    --- If `true`, the projectile will be destroyed whenever it collides with a part, including players.
    DestroyOnCollision: boolean?,

    --- Callback fired when the projectile is about to be destroyed by `Projectile:Destroy()` when it gets called from colliding with something when `DestroyOnCollision` is `true`.
    OnHitDestroy: (self: Projectile, Details: ProjectileDetails) -> "PreventDestruction"?,
    --- Callback fired when the projectile is about to be destroyed by `Projectile:Destroy()`.
    OnDestroy: (self: Projectile, Details: ProjectileDetails) -> (),
}

export type ProjectileDetails = {
    --- The model of the projectile.
    Model: Instance & (BasePart | Model),
    --- The tween that acts as the projectile's movement.
    Tween: Tween,
    --- The hitbox associated to this projectile.
    Hitbox: Hitbox.HitboxDetails,
    --- Destroys this projectile by destroying the model and cancelling the hitbox.
    Destroy: (self: ProjectileDetails) -> (),
}

--- Creates a new projectile instance.
---
--- Remember to call this function with a `.` instead of a `:`.
function Projectile.New(ProjectileSettings: Projectile): ProjectileDetails

    ---Stop this from running on the client (technically, a stubborn exploiter could remove this line and run it anyways, but it'll do nothing regardless.)
    -- "i love writing server shit and putting it in ReplicatedStorage :]" – Dyscarn
    if not RunService:IsServer() then
        return {
            Model = nil,
            Tween = nil,
            Hitbox = nil,
            Destroy = nil,
        }
    end

    -- Some feedback for faulty input
    if not ProjectileSettings then
        warn("No projectile settings specified!")
        warn(debug.traceback())
        return {
            Model = nil,
            Tween = nil,
            Hitbox = nil,
            Destroy = nil,
        }
    end
    if not ProjectileSettings.SourcePlayer or not ProjectileSettings.Model or not ProjectileSettings.StartingCFrame or not ProjectileSettings.HitboxSettings then
        warn("Projectile settings missing crucial fields!")
        warn(debug.traceback())
        return {
            Model = nil,
            Tween = nil,
            Hitbox = nil,
            Destroy = nil,
        }
    end

    -- Organize a table used for configuring the projectile.
    Utils.Type.DeepTableWrite(ProjectileSettings, Projectile.DefaultConfig)
    ProjectileSettings.HitboxSettings.IsProjectile = true
    ProjectileSettings.HitboxSettings.PredictVelocity = false
    ProjectileSettings.HitboxSettings.HitMultiple = ProjectileSettings.HitboxSettings.HitMultiple ~= nil and ProjectileSettings.HitboxSettings.HitMultiple or true
    ProjectileSettings.HitboxSettings.Time = ProjectileSettings.Lifetime
    
    -- Define a function and some properties for stopping the projectile in its tracks, when needed.
    local Cancel = false

    -- Make a new table for throwing this all into an instance.
    local ProjectileInstance: ProjectileDetails = {
        Model = ProjectileSettings.Model:Clone(),
        Tween = nil,
        -- Create a new hitbox instance with these settings
        Hitbox = Hitbox.New(ProjectileSettings.SourcePlayer, ProjectileSettings.HitboxSettings),
        Destroy = function(self: ProjectileDetails)
            if ProjectileSettings.OnDestroy then
                ProjectileSettings:OnDestroy(self)
            end
            Cancel = true
            self.Model:Destroy()
            self.Hitbox:Cancel()
        end,
    }

    -- Clone the model into the workspace for use with the projectile.
    ProjectileInstance.Model.Parent = workspace:FindFirstChild("Map") and workspace.Map.Ingame or workspace.TempObjectFolders

    -- Find the provided CFrame; if it doesn't exist, grab it from the instance's own CFrame or the model's worldpivot, whichever is applicable.
    ProjectileSettings.HitboxSettings.CFrame = ProjectileSettings.HitboxSettings.CFrame or function(): CFrame
        return if ProjectileInstance.Model:IsA("Model") then ProjectileInstance.Model.WorldPivot else ProjectileInstance.Model.CFrame -- "Clever! Though, couldn't one have this normally within the conditional statement above? I'd imagine not if you're doing it this way, I suppose." – Itred
    end

    -- If the throwtype is "mouse", fetch another function for grabbing the player's mouse position, to know where to aim the projectile.
    if ProjectileSettings.ThrowType == "Mouse" then
        local Direction = Utils.Player.GetPlayerMousePosition(ProjectileSettings.SourcePlayer, false)
        ProjectileSettings.StartingCFrame = CFrame.lookAt(ProjectileSettings.StartingCFrame.Position, Direction)
    end

    -- Move the projectile to the start using its Pivot or CFrame, depending on whether or not its a model – "Man, I wish there was a centralized way to move by CFrame that would work for both..." – Itred
    if ProjectileInstance.Model:IsA("Model") then
        ProjectileInstance.Model:PivotTo(ProjectileSettings.StartingCFrame)
    else
        ProjectileInstance.Model.CFrame = ProjectileSettings.StartingCFrame
    end

    -- Add the projectile's model to the debris system, to schedule it for destruction at the end of its lifetime.
    Debris:AddItem(ProjectileInstance.Model, ProjectileSettings.Lifetime)

    -- Math out the goal position, and start to tween the projectile from the start to that goal position.
    local Goal = ProjectileSettings.StartingCFrame * CFrame.new(0, 0, -ProjectileSettings.Speed * ProjectileSettings.Lifetime)
    if ProjectileSettings.FinalRotation then
        Goal *= ProjectileSettings.FinalRotation
    end
    ProjectileInstance.Tween = TweenService:Create(ProjectileInstance.Model:IsA("Model") and ProjectileInstance.Model.WorldPivot or ProjectileInstance.Model, TweenInfo.new(ProjectileSettings.Lifetime), {
        CFrame = Goal,
    })
    ProjectileInstance.Tween:Play()

    -- Configure a raycast for collision detection
    local DestroyParams = RaycastParams.new()
    DestroyParams.FilterType = Enum.RaycastFilterType.Exclude
    DestroyParams.FilterDescendantsInstances = {ProjectileSettings.SourcePlayer.Character}
    DestroyParams.RespectCanCollide = true

    -- If the projectile is set to be destroyed on collision, start looking ahead of it for such collision.
    if ProjectileSettings.DestroyOnCollision then

        task.defer(function() -- Use task.defer here to avoid conflicts with wedging things into the task scheduler

            -- Starting from 0, count up to the maximum lifetime of the projectile
            -- If the collision box initially doesn't exist, the projectile got cancelled, the instance stops existing, or the hitbox within the instance stops existing, stop these checks

            local CollisionBox = ProjectileInstance.Model:FindFirstChild("CollisionBox")

            if not CollisionBox then
                return
            end

            while not (Cancel or not ProjectileInstance.Model or not CollisionBox) do

                -- Find anything just ahead of the projectile with a shapecast
                local Touching = workspace:Shapecast(CollisionBox, CollisionBox.CFrame.LookVector, DestroyParams)

                -- If the shapecast returned a hit, and the hit is an existing instance, fire the OnHitDestroy callback and destroy the projectile soon after.
                if Touching and Touching.Instance then
                    local PreventDestruction = if ProjectileSettings.OnHitDestroy then ProjectileSettings:OnHitDestroy(ProjectileInstance) == "PreventDestruction" else false
                    
                    if not PreventDestruction then
                        ProjectileInstance:Destroy()
                    end
                    
                    break
                end

                task.wait()
            end
        end)

    end

    return ProjectileInstance
end

return Projectile
