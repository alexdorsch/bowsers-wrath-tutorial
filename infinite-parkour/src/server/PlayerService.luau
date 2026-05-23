--!strict
-- Tracks per-player runtime state:
--   • Current height (max Y this run).
--   • Personal best (Phase 1: in-memory only — DataStore wiring lands in Phase 2).
--   • Run start time.
--
-- Pushes height updates to the client via the HeightUpdated RemoteEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

type PlayerState = Types.PlayerState

local PlayerService = {}

-- Map<UserId, PlayerState>
local states: { [number]: PlayerState } = {}

-- Ensures the HeightUpdated remote exists; created lazily.
local heightUpdatedRemote: RemoteEvent? = nil
local function getHeightUpdatedRemote(): RemoteEvent
	if not heightUpdatedRemote then
		heightUpdatedRemote = Remotes.getEvent(Constants.REMOTE_NAMES.HeightUpdated)
	end
	return heightUpdatedRemote :: RemoteEvent
end

-- ------------------------------------------------------------
-- Lifecycle
-- ------------------------------------------------------------
local function resetRun(state: PlayerState)
	state.currentHeight = 0
	state.runStartTick = os.clock()
end

local function onCharacterAdded(state: PlayerState, character: Model)
	-- Reset run state for this fresh life.
	resetRun(state)
	-- Push the reset to the client immediately so the HUD shows 0.
	getHeightUpdatedRemote():FireClient(state.player, 0, state.personalBest)

	-- The Died event covers void-kills (FallenPartsDestroyHeight) and any future
	-- damage sources. We only react to clear the run; respawn is automatic via
	-- Roblox's default flow + the SpawnLocation TowerService placed.
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Once(function()
			resetRun(state)
		end)
	end
end

local function onPlayerAdded(player: Player)
	local state: PlayerState = {
		player = player,
		currentHeight = 0,
		personalBest = 0, -- Phase 2: load from DataStore.
		runStartTick = os.clock(),
	}
	states[player.UserId] = state

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(state, character)
	end)

	if player.Character then
		onCharacterAdded(state, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	-- Phase 2: persist personalBest to DataStore here.
	states[player.UserId] = nil
end

-- ------------------------------------------------------------
-- Height tracking
-- ------------------------------------------------------------
local UPDATE_HZ = 8 -- Smooth enough for a counter; light on the network.
local UPDATE_INTERVAL = 1 / UPDATE_HZ

local function tick()
	local remote = getHeightUpdatedRemote()
	for _, state in states do
		local char = state.player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local y = root.Position.Y
			-- Track height relative to the spawn pad's top, so floor 1 ~ 8 studs etc.
			local heightAboveSpawn = math.max(0, math.floor(y - Constants.SPAWN_PAD_Y))
			if heightAboveSpawn > state.currentHeight then
				state.currentHeight = heightAboveSpawn
				if heightAboveSpawn > state.personalBest then
					state.personalBest = heightAboveSpawn
				end
				-- Only fire on improvement — reduces remote chatter.
				remote:FireClient(state.player, state.currentHeight, state.personalBest)
			end
		end
	end
end

-- ------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------
function PlayerService.start()
	-- Make the void below the spawn pad lethal.
	Workspace.FallenPartsDestroyHeight = Constants.FALL_DEATH_Y

	-- Hook existing + future players.
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Run the height-tracking loop.
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= UPDATE_INTERVAL then
			accumulator = 0
			tick()
		end
	end)

	print("[PlayerService] Started.")
end

function PlayerService.getState(player: Player): PlayerState?
	return states[player.UserId]
end

return PlayerService
