--!strict
-- Owns the lifecycle of the procedurally generated tower:
--   • Builds the spawn pad on init.
--   • Streams new floors above the highest climber.
--   • Despawns floors well below the lowest climber.
--
-- Daily seed: same tower for every player on the same UTC day.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))

local ObstacleGenerator = require(script.Parent:WaitForChild("ObstacleGenerator"))

type Obstacle = Types.Obstacle

local TowerService = {}

-- ------------------------------------------------------------
-- Internal state
-- ------------------------------------------------------------
local towerFolder: Folder? = nil

-- Per-floor obstacle records. Sparse: floors below the cull threshold are removed.
local floors: { [number]: Obstacle } = {}
local highestGeneratedIndex: number = -1

local dailySeed: number = 0

local UPDATE_HZ = 4 -- Cheap tick — 4 times per second is plenty for streaming.
local UPDATE_INTERVAL = 1 / UPDATE_HZ

-- ------------------------------------------------------------
-- Seed
-- ------------------------------------------------------------
local function computeDailySeed(): number
	-- Integer math: number of full UTC days since the epoch.
	return math.floor(os.time() / Constants.SECONDS_PER_DAY)
end

-- ------------------------------------------------------------
-- Spawn pad
-- ------------------------------------------------------------
local function buildSpawnPad(parent: Instance): Part
	local pad = Instance.new("Part")
	pad.Name = "SpawnPad"
	pad.Size = Vector3.new(20, 1, 20)
	pad.Anchored = true
	pad.CanCollide = true
	pad.Material = Enum.Material.SmoothPlastic
	pad.Color = Constants.SPAWN_PAD_COLOR
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.CFrame = CFrame.new(0, Constants.SPAWN_PAD_Y, 0)
	pad.Parent = parent

	-- A SpawnLocation so the default character spawns here.
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "Spawn"
	spawnLoc.Size = Vector3.new(8, 0.2, 8)
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = false
	spawnLoc.Transparency = 1
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.CFrame = CFrame.new(0, Constants.SPAWN_PAD_Y + 0.6, 0)
	spawnLoc.Neutral = true
	spawnLoc.AllowTeamChangeOnTouch = false
	spawnLoc.Parent = parent

	return pad
end

-- ------------------------------------------------------------
-- Floor lifecycle
-- ------------------------------------------------------------
local function spawnFloor(index: number)
	if floors[index] then
		return
	end

	-- Ensure all preceding floors exist so landing chain is continuous.
	-- Defensive — under normal streaming we always generate sequentially.
	if index > 0 and not floors[index - 1] then
		spawnFloor(index - 1)
	end

	local previousXZ: Vector2
	if index == 0 then
		previousXZ = Vector2.new(0, 0) -- right above the spawn pad
	else
		local prior = floors[index - 1]
		previousXZ = Vector2.new(prior.landingCFrame.X, prior.landingCFrame.Z)
	end

	local obstacle = ObstacleGenerator.generate(dailySeed, index, previousXZ)
	for _, part in obstacle.parts do
		part.Parent = towerFolder
	end
	floors[index] = obstacle

	if index > highestGeneratedIndex then
		highestGeneratedIndex = index
	end
end

local function despawnFloor(index: number)
	local obstacle = floors[index]
	if not obstacle then
		return
	end
	for _, part in obstacle.parts do
		part:Destroy()
	end
	floors[index] = nil
end

-- ------------------------------------------------------------
-- Streaming: extend ahead, cull behind.
-- ------------------------------------------------------------
local function tick()
	local players = Players:GetPlayers()
	if #players == 0 then
		return -- Nothing to stream around.
	end

	local minY, maxY = math.huge, -math.huge
	for _, player in players do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local y = root.Position.Y
			if y < minY then
				minY = y
			end
			if y > maxY then
				maxY = y
			end
		end
	end

	if maxY == -math.huge then
		return -- No live characters; nothing to do.
	end

	-- Extend ahead: ensure floors exist up to STREAM_AHEAD studs above the highest climber.
	local targetTopY = maxY + Constants.STREAM_AHEAD_DISTANCE
	local targetFloorIndex =
		math.floor((targetTopY - Constants.FIRST_FLOOR_Y) / Constants.FLOOR_SPACING_STUDS)
	while highestGeneratedIndex < targetFloorIndex do
		spawnFloor(highestGeneratedIndex + 1)
	end

	-- Cull behind: drop floors well below the lowest climber.
	local cullBelowY = minY - Constants.STREAM_BEHIND_DISTANCE
	for index, obstacle in floors do
		if obstacle.yPosition < cullBelowY then
			despawnFloor(index)
		end
	end
end

-- ------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------
function TowerService.start()
	dailySeed = computeDailySeed()

	towerFolder = Instance.new("Folder")
	towerFolder.Name = "Tower"
	towerFolder.Parent = Workspace

	buildSpawnPad(towerFolder)

	-- Seed a handful of initial floors so the first player sees a tower immediately.
	for i = 0, 9 do
		spawnFloor(i)
	end

	-- Throttle Heartbeat to UPDATE_HZ.
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= UPDATE_INTERVAL then
			accumulator = 0
			tick()
		end
	end)

	print(`[TowerService] Started. Daily seed = {dailySeed}`)
end

function TowerService.getSeed(): number
	return dailySeed
end

function TowerService.getSpawnPosition(): Vector3
	return Vector3.new(0, Constants.SPAWN_PAD_Y + 5, 0)
end

return TowerService
