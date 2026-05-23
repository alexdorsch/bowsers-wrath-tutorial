--!strict
-- Shared metadata about each obstacle type.
-- Server uses this for generation; client may use it later for hints/preview UI.
-- Keeping this shared prevents drift between gen logic and rendering.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

type ObstacleKind = Types.ObstacleKind

export type ObstacleMetadata = {
	kind: ObstacleKind,
	-- Weight in the spawn pool at difficulty 0 (early floors).
	easyWeight: number,
	-- Weight at difficulty 1 (deep into the tower).
	hardWeight: number,
}

local ObstacleConfig = {}

ObstacleConfig.METADATA = {
	Jump = { kind = "Jump", easyWeight = 5, hardWeight = 1 } :: ObstacleMetadata,
	WideJump = { kind = "WideJump", easyWeight = 2, hardWeight = 3 } :: ObstacleMetadata,
	Beam = { kind = "Beam", easyWeight = 2, hardWeight = 4 } :: ObstacleMetadata,
	-- Reserved for Phase 2 — weights set to 0 in Phase 1 so they won't be picked.
	SwingingBar = { kind = "SwingingBar", easyWeight = 0, hardWeight = 0 } :: ObstacleMetadata,
	RotatingBar = { kind = "RotatingBar", easyWeight = 0, hardWeight = 0 } :: ObstacleMetadata,
	DisappearingTile = { kind = "DisappearingTile", easyWeight = 0, hardWeight = 0 } :: ObstacleMetadata,
} :: { [ObstacleKind]: ObstacleMetadata }

-- Returns the list of kinds with a nonzero weight at either difficulty.
-- Used by the generator to enumerate the active pool.
function ObstacleConfig.activeKinds(): { ObstacleKind }
	local result: { ObstacleKind } = {}
	for kind, meta in ObstacleConfig.METADATA do
		if meta.easyWeight > 0 or meta.hardWeight > 0 then
			table.insert(result, kind)
		end
	end
	return result
end

return ObstacleConfig
