--!strict
-- Single source of truth for gameplay tuning, asset IDs, and visual constants.
-- Anything tweakable lives here so designers can iterate without touching logic.

local Constants = {}

-- ============================================================
-- World / Tower
-- ============================================================
Constants.FLOOR_SPACING_STUDS = 12 -- Vertical distance between obstacle floors.
Constants.FIRST_FLOOR_Y = 10 -- Y position of the first obstacle above spawn.
Constants.SPAWN_PAD_Y = 2 -- Y position of the spawn platform top.
Constants.STREAM_AHEAD_DISTANCE = 80 -- Generate obstacles within this distance above the highest climber.
Constants.STREAM_BEHIND_DISTANCE = 120 -- Despawn obstacles this far below the lowest active climber.
Constants.FALL_DEATH_Y = -50 -- Falling below this Y kills the player.

-- ============================================================
-- Difficulty
-- ============================================================
-- Difficulty 0 = floor 0, difficulty 1 = floor at SOFT_MAX_FLOOR.
-- Used by ObstacleGenerator to weight obstacle pool selection.
Constants.SOFT_MAX_FLOOR = 200

-- ============================================================
-- Daily seed
-- ============================================================
-- The tower layout is deterministic for a given seed.
-- `os.time() // SECONDS_PER_DAY` rotates the seed once per UTC day.
Constants.SECONDS_PER_DAY = 86400

-- ============================================================
-- Visual style: Tower of Hell neon palette
-- ============================================================
-- Cycled per-floor for the saturated neon aesthetic.
Constants.NEON_PALETTE = {
	Color3.fromRGB(255, 43, 214), -- hot pink
	Color3.fromRGB(0, 217, 255), -- cyan
	Color3.fromRGB(88, 255, 58), -- lime
	Color3.fromRGB(255, 228, 0), -- yellow
	Color3.fromRGB(214, 58, 255), -- magenta
	Color3.fromRGB(255, 139, 0), -- orange
}

Constants.SPAWN_PAD_COLOR = Color3.fromRGB(245, 245, 250)

-- ============================================================
-- Remote names
-- ============================================================
-- String keys for RemoteEvents/RemoteFunctions. Used by Remotes.luau.
Constants.REMOTE_NAMES = {
	HeightUpdated = "HeightUpdated", -- Server → Client: { height: number, personalBest: number }
}

-- ============================================================
-- Robux purchase IDs (filled in by you after creating products on Creator Dashboard)
-- ============================================================
-- Leave as 0 during Phase 1; populated in Phase 3.
Constants.GAMEPASS_IDS = {
	DoubleCoins = 0,
}

Constants.PRODUCT_IDS = {
	SkipStage = 0,
	SecondChance = 0,
}

return Constants
