--!strict
-- One builder function per obstacle kind. Each builder receives a `BuildContext`
-- and returns the unparented parts that make up the obstacle, plus the landing
-- position for the next floor to anchor against.
--
-- Builders MUST NOT parent parts to workspace — TowerService owns that.
-- This keeps generation pure and easy to test in isolation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))

type ObstacleKind = Types.ObstacleKind
type Obstacle = Types.Obstacle

export type BuildContext = {
	floorIndex: number,
	yPosition: number, -- The Y at which the obstacle's top surface should sit.
	previousLandingXZ: Vector2, -- (X, Z) of the prior obstacle's landing point.
	rng: Random, -- Per-floor deterministic RNG.
	color: Color3,
}

local ObstacleTypes = {}

-- Maximum horizontal offset from previous landing — kept well under
-- a Humanoid's max running jump distance (~18 studs) for clearable spacing.
local MAX_OFFSET_PER_STEP = 8

-- Helper: build a single Anchored Part with shared visual conventions.
local function newPart(size: Vector3, color: Color3): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Anchored = true
	p.CanCollide = true
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Add a thin Neon underglow strip beneath the main platform for the
-- Tower of Hell aesthetic. Cheap visual ROI.
local function addUnderglow(parent: Part, color: Color3): Part
	local glow = newPart(Vector3.new(parent.Size.X + 0.4, 0.1, parent.Size.Z + 0.4), color)
	glow.Material = Enum.Material.Neon
	glow.CanCollide = false
	glow.CFrame = parent.CFrame * CFrame.new(0, -parent.Size.Y / 2 - 0.05, 0)
	return glow
end

-- Pick a landing X/Z within MAX_OFFSET_PER_STEP of the previous one.
local function offsetXZ(previous: Vector2, rng: Random): Vector2
	local angle = rng:NextNumber() * math.pi * 2
	local distance = rng:NextNumber() * MAX_OFFSET_PER_STEP
	return previous + Vector2.new(math.cos(angle) * distance, math.sin(angle) * distance)
end

-- ============================================================
-- Jump: standard 6x1x6 square platform.
-- ============================================================
function ObstacleTypes.Jump(ctx: BuildContext): Obstacle
	local xz = offsetXZ(ctx.previousLandingXZ, ctx.rng)
	local platform = newPart(Vector3.new(6, 1, 6), ctx.color)
	platform.Name = `Jump_F{ctx.floorIndex}`
	platform.CFrame = CFrame.new(xz.X, ctx.yPosition, xz.Y)

	local glow = addUnderglow(platform, ctx.color)

	return {
		kind = "Jump",
		floorIndex = ctx.floorIndex,
		yPosition = ctx.yPosition,
		parts = { platform, glow },
		landingCFrame = CFrame.new(xz.X, ctx.yPosition + platform.Size.Y / 2, xz.Y),
	}
end

-- ============================================================
-- WideJump: smaller 4x1x4 platform forced further from previous one.
-- ============================================================
function ObstacleTypes.WideJump(ctx: BuildContext): Obstacle
	-- Force a longer offset by sampling angle then using near-max distance.
	local angle = ctx.rng:NextNumber() * math.pi * 2
	local distance = MAX_OFFSET_PER_STEP * (0.75 + ctx.rng:NextNumber() * 0.25)
	local xz = ctx.previousLandingXZ
		+ Vector2.new(math.cos(angle) * distance, math.sin(angle) * distance)

	local platform = newPart(Vector3.new(4, 1, 4), ctx.color)
	platform.Name = `WideJump_F{ctx.floorIndex}`
	platform.CFrame = CFrame.new(xz.X, ctx.yPosition, xz.Y)

	local glow = addUnderglow(platform, ctx.color)

	return {
		kind = "WideJump",
		floorIndex = ctx.floorIndex,
		yPosition = ctx.yPosition,
		parts = { platform, glow },
		landingCFrame = CFrame.new(xz.X, ctx.yPosition + platform.Size.Y / 2, xz.Y),
	}
end

-- ============================================================
-- Beam: narrow 2x1x14 walkway at a random yaw.
-- ============================================================
function ObstacleTypes.Beam(ctx: BuildContext): Obstacle
	local xz = offsetXZ(ctx.previousLandingXZ, ctx.rng)
	local yaw = ctx.rng:NextNumber() * math.pi * 2

	local beam = newPart(Vector3.new(2, 1, 14), ctx.color)
	beam.Name = `Beam_F{ctx.floorIndex}`
	beam.CFrame = CFrame.new(xz.X, ctx.yPosition, xz.Y) * CFrame.Angles(0, yaw, 0)

	local glow = addUnderglow(beam, ctx.color)

	return {
		kind = "Beam",
		floorIndex = ctx.floorIndex,
		yPosition = ctx.yPosition,
		parts = { beam, glow },
		-- Landing point is the *far end* of the beam, in the direction it points.
		landingCFrame = beam.CFrame * CFrame.new(0, beam.Size.Y / 2, -beam.Size.Z / 2 + 1),
	}
end

return ObstacleTypes
