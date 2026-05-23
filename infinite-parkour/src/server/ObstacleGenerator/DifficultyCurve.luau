--!strict
-- Maps floor index → difficulty in [0, 1], and picks an obstacle kind
-- by interpolated weights from ObstacleConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local ObstacleConfig = require(Shared:WaitForChild("ObstacleConfig"))
local Types = require(Shared:WaitForChild("Types"))

type ObstacleKind = Types.ObstacleKind

local DifficultyCurve = {}

-- Linear clamp to [0, 1].
local function clamp01(x: number): number
	if x < 0 then
		return 0
	elseif x > 1 then
		return 1
	else
		return x
	end
end

-- Returns difficulty in [0, 1] for a given floor index.
-- Linear ramp; switch to a curve later (sqrt for slower ramp early) if needed.
function DifficultyCurve.getDifficulty(floorIndex: number): number
	return clamp01(floorIndex / Constants.SOFT_MAX_FLOOR)
end

-- Lerp between easy and hard weight for a kind at the given difficulty.
local function interpolatedWeight(kind: ObstacleKind, difficulty: number): number
	local meta = ObstacleConfig.METADATA[kind]
	if not meta then
		return 0
	end
	return meta.easyWeight + (meta.hardWeight - meta.easyWeight) * difficulty
end

-- Weighted-random pick using the provided Random instance. Deterministic per (rng, difficulty).
-- Falls back to "Jump" if no kind has positive weight (shouldn't happen with valid config).
function DifficultyCurve.pickKind(rng: Random, difficulty: number): ObstacleKind
	local kinds = ObstacleConfig.activeKinds()
	local totalWeight = 0
	local weights: { number } = table.create(#kinds)

	for i, kind in kinds do
		local w = interpolatedWeight(kind, difficulty)
		weights[i] = w
		totalWeight += w
	end

	if totalWeight <= 0 then
		return "Jump"
	end

	local roll = rng:NextNumber() * totalWeight
	local cumulative = 0
	for i, kind in kinds do
		cumulative += weights[i]
		if roll <= cumulative then
			return kind
		end
	end

	return kinds[#kinds] -- numerical safety fallback
end

return DifficultyCurve
