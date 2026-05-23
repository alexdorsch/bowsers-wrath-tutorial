--!strict
-- Minimal Phase 1 HUD: current height + personal best, top-center.
-- Subscribes to the HeightUpdated remote and animates on every change.
--
-- This module exposes a single mount() that returns nothing — fire-and-forget.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local HUD = {}

local function buildGui(): (ScreenGui, TextLabel, TextLabel)
	local screen = Instance.new("ScreenGui")
	screen.Name = "ParkourHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 0, 28)
	container.Size = UDim2.new(0, 360, 0, 88)
	container.BackgroundTransparency = 1
	container.Parent = screen

	-- Big height label
	local heightLabel = Instance.new("TextLabel")
	heightLabel.Name = "Height"
	heightLabel.AnchorPoint = Vector2.new(0.5, 0)
	heightLabel.Position = UDim2.new(0.5, 0, 0, 0)
	heightLabel.Size = UDim2.new(1, 0, 0, 56)
	heightLabel.BackgroundTransparency = 1
	heightLabel.Font = Enum.Font.GothamBold
	heightLabel.TextSize = 52
	heightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	heightLabel.TextStrokeTransparency = 0.5
	heightLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	heightLabel.Text = "0"
	heightLabel.Parent = container

	-- Subtle "studs" suffix label, positioned below
	local pbLabel = Instance.new("TextLabel")
	pbLabel.Name = "PersonalBest"
	pbLabel.AnchorPoint = Vector2.new(0.5, 0)
	pbLabel.Position = UDim2.new(0.5, 0, 0, 60)
	pbLabel.Size = UDim2.new(1, 0, 0, 24)
	pbLabel.BackgroundTransparency = 1
	pbLabel.Font = Enum.Font.Gotham
	pbLabel.TextSize = 16
	pbLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	pbLabel.TextStrokeTransparency = 0.7
	pbLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	pbLabel.Text = "best 0"
	pbLabel.Parent = container

	return screen, heightLabel, pbLabel
end

-- Brief scale-up pop on every meaningful height change.
local function popLabel(label: TextLabel)
	label.TextTransparency = 0
	TweenService:Create(
		label,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextSize = 60 }
	):Play()
	task.delay(0.08, function()
		TweenService:Create(
			label,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextSize = 52 }
		):Play()
	end)
end

function HUD.mount()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local screen, heightLabel, pbLabel = buildGui()
	screen.Parent = playerGui

	local remote = Remotes.getEvent(Constants.REMOTE_NAMES.HeightUpdated)
	remote.OnClientEvent:Connect(function(height: number, personalBest: number)
		heightLabel.Text = tostring(height)
		pbLabel.Text = `best {personalBest}`
		popLabel(heightLabel)
	end)
end

return HUD
