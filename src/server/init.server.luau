-- Brainrot Boulevard: server bootstrap. Creates the remotes, starts every
-- service in dependency order, hands each joining player a plot and a slap
-- tool, and broadcasts a HUD snapshot to every player once a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- The remotes every service and the client share.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage
local REMOTE_NAMES = {
	"BuyBrainrot", -- client -> server: buy the belt brainrot in front of you
	"StealBrainrot", -- client -> server: grab a brainrot off another base
	"ClaimCarried", -- client -> server: claim what you carry, on your base
	"Slap", -- client -> server: slap the nearest thief
	"BuyItem", -- client -> server: buy a shop item by id
	"Rebirth", -- client -> server: rebirth
	"Announce", -- server -> client: one-line toast message
	"EventBanner", -- server -> client: big event banner text
	"StateUpdate", -- server -> client: HUD snapshot, once a second
	"LeaderboardUpdate", -- server -> client: top-5 leaderboard, every 5s (v2)
}
local Remotes = {}
for _, name in ipairs(REMOTE_NAMES) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	Remotes[name] = remote
end

local DataService = require(script.Parent:WaitForChild("DataService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local StealService = require(script.Parent:WaitForChild("StealService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local EventService = require(script.Parent:WaitForChild("EventService"))
local RebirthService = require(script.Parent:WaitForChild("RebirthService"))
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))

local services = {
	DataService = DataService,
	BaseService = BaseService,
	WorldBuilder = WorldBuilder,
	BrainrotFactory = BrainrotFactory,
	ConveyorService = ConveyorService,
	StealService = StealService,
	ShopService = ShopService,
	EventService = EventService,
	RebirthService = RebirthService,
	LeaderboardService = LeaderboardService,
	Remotes = Remotes,
}

WorldBuilder.build(game:GetService("Workspace"))
BaseService.init()
ConveyorService.init(services)
StealService.init(services)
ShopService.init(services)
EventService.init(services)
RebirthService.init(services)
LeaderboardService.init(services)
DataService.startIncomeLoop()

local function giveSlapTool(player)
	local character = player.Character
	if not character then
		return
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack and not backpack:FindFirstChild("Slap Hand") and not character:FindFirstChild("Slap Hand") then
		BrainrotFactory.createSlapTool().Parent = backpack
	end
end

local function onPlayerAdded(player)
	local state = DataService.newState(player)
	state.PlotIndex = BaseService.claimPlot(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		giveSlapTool(player)
		-- A reborn player keeps their crown on every respawn.
		if state.Rebirths > 0 then
			for _ = 1, state.Rebirths do
				BrainrotFactory.giveCrown(character)
			end
		end
		-- A coil buyer keeps their speed on every respawn.
		if state.HasCoil then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed += Config.COIL_SPEED_BONUS
			end
		end
	end)
	-- If the player drops what they carry by resetting, it drops, not vanishes.
	player.CharacterRemoving:Connect(function()
		if state.Carrying then
			StealService.dropCarried(player, state)
		end
	end)
end

local function onPlayerRemoving(player)
	local state = DataService.get(player)
	if state then
		if state.Carrying then
			StealService.dropCarried(player, state)
		end
		BaseService.freePlot(player, DataService)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- The HUD heartbeat: one snapshot per player per second.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = DataService.get(player)
			if state then
				Remotes.StateUpdate:FireClient(player, DataService.snapshot(state))
			end
		end
	end
end)

print("Brainrot Boulevard v2 is live: 8 plots, a conveyor, 27 brainrots, a leaderboard.")
