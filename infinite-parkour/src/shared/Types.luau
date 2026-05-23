--!strict
-- Centralized Luau type definitions for the project.
-- Import via `local Types = require(ReplicatedStorage.Shared.Types)`.

local Types = {}

-- An obstacle type identifier. Add to this union when introducing new obstacles.
export type ObstacleKind =
	"Jump"
	| "WideJump"
	| "Beam"
	| "SwingingBar"
	| "RotatingBar"
	| "DisappearingTile"

-- One physical obstacle in the tower.
export type Obstacle = {
	kind: ObstacleKind,
	floorIndex: number, -- 0-indexed from the bottom.
	yPosition: number, -- Y coordinate of the obstacle's landing surface.
	parts: { BasePart }, -- All parts composing the obstacle (for cleanup).
	landingCFrame: CFrame, -- Where the player ends up after clearing this obstacle.
}

-- Per-player runtime state held by PlayerService.
export type PlayerState = {
	player: Player,
	currentHeight: number, -- Highest Y this run.
	personalBest: number, -- All-time best (loaded from DataStore in Phase 2).
	runStartTick: number, -- os.clock() at the start of this run.
}

return Types
