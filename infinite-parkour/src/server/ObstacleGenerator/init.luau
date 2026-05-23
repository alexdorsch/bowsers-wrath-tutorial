--!strict
-- Public API of the ObstacleGenerator subsystem.
-- Stateless and deterministic: same (seed, floorIndex) always produces the same obstacle.
-- TowerService is the only caller in Phase 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))

local ObstacleTypes = require(script:WaitForChild("ObstacleTypes"))
local DifficultyCurve = require(script:WaitForChild("DifficultyCurve"))

type Obstacle = Types.Obstacle
type ObstacleKind = Types.ObstacleKind

local ObstacleGenerator = {}

-- Mix the daily seed and floor index into a per-floor RNG.
-- Multiplying by a prime keeps adjacent floors from feeling correlated.
local function rngForFloor(seed: number, floorIndex: number): Random
	return Random.new(seed + floorIndex * 2654435761)
end

-- Pick the neon color for a floor by cycling the palette.
local function colorForFloor(floorIndex: number): Color3
	local palette = Constants.NEON_PALETTE
	return palette[((floorIndex - 1) % #palette) + 1]
end

-- Generate the obstacle for a given floor.
-- `previousLandingXZ` lets the generator place the obstacle near where the
-- player will be standing after the prior floor. For floor 0 pass the spawn pad's XZ.
function ObstacleGenerator.generate(
	seed: number,
	floorIndex: number,
	previousLandingXZ: Vector2
): Obstacle
	local rng = rngForFloor(seed, floorIndex)
	local difficulty = DifficultyCurve.getDifficulty(floorIndex)
	local kind = DifficultyCurve.pickKind(rng, difficulty)

	local yPosition = Constants.FIRST_FLOOR_Y + (floorIndex * Constants.FLOOR_SPACING_STUDS)

	local ctx = {
		floorIndex = floorIndex,
		yPosition = yPosition,
		previousLandingXZ = previousLandingXZ,
		rng = rng,
		color = colorForFloor(floorIndex),
	}

	local builder = (ObstacleTypes :: any)[kind]
	if not builder then
		error(`No builder for obstacle kind: {kind}`)
	end
	return builder(ctx)
end

return ObstacleGenerator
