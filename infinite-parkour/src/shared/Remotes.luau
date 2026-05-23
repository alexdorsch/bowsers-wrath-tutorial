--!strict
-- Lazy-initialized registry of all RemoteEvents and RemoteFunctions.
-- Calling `Remotes.get(name)` returns the remote, creating it on the server
-- and waiting for it on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local Remotes = {}

local remotesFolder: Folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local cache: { [string]: Instance } = {}

-- Internal: returns the remote, creating it on the server if absent.
local function fetchRemote(name: string, className: "RemoteEvent" | "RemoteFunction"): Instance
	if cache[name] then
		return cache[name]
	end

	local existing = remotesFolder:FindFirstChild(name)
	if existing then
		cache[name] = existing
		return existing
	end

	if RunService:IsServer() then
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
		cache[name] = remote
		return remote
	else
		-- Client: wait for the server to create it.
		local remote = remotesFolder:WaitForChild(name, 10)
		assert(remote, `Remote {name} did not replicate within 10s`)
		cache[name] = remote
		return remote
	end
end

function Remotes.getEvent(name: string): RemoteEvent
	return fetchRemote(name, "RemoteEvent") :: RemoteEvent
end

function Remotes.getFunction(name: string): RemoteFunction
	return fetchRemote(name, "RemoteFunction") :: RemoteFunction
end

-- Convenience: validate the name against the canonical list in Constants.
function Remotes.getEventChecked(name: string): RemoteEvent
	local canonical = Constants.REMOTE_NAMES[name]
	assert(canonical == name, `Unknown remote name: {name}. Add it to Constants.REMOTE_NAMES.`)
	return Remotes.getEvent(name)
end

return Remotes
