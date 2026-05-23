--!strict
-- Client bootstrap. Loaded as a LocalScript via init.client.luau convention,
-- mapped to StarterPlayer.StarterPlayerScripts.Client.

local UI = script:WaitForChild("UI")
local HUD = require(UI:WaitForChild("HUD"))

print("[Client] Booting HUD…")
HUD.mount()
print("[Client] Boot complete.")
