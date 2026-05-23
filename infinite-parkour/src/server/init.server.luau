--!strict
-- Server bootstrap. Loaded automatically by Roblox because this is named init.server.luau
-- and lives at the root of the server source tree (mapped to ServerScriptService/Server).
--
-- Responsibility: start services in dependency order, then get out of the way.

local TowerService = require(script:WaitForChild("TowerService"))
local PlayerService = require(script:WaitForChild("PlayerService"))

print("[Server] Booting Infinite Parkour…")

-- TowerService must run first so the SpawnLocation exists before any player
-- spawn attempts (Players join after this script returns control).
TowerService.start()
PlayerService.start()

print("[Server] Boot complete.")
