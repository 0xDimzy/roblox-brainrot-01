-- Brainrot Boulevard v3: coin rush minigame. Every 3 minutes a 45
-- second rush starts: up to 12 gold coins pop up around the fountain
-- ring, one at a time, each worth $250 when clicked. Coins are real
-- 3D models with a ClickDetector, so collecting one is a click on the
-- world, not a button — and the server owns the click: it checks the
-- rush is live, the coin exists, and the clicker is within 20 studs,
-- so a far-away clicker can never farm coins through the wall. The
-- top collector takes a $5,000 bonus on top of their coins, and every
-- player's best score is kept in state for the HUD's best-score board.
-- The rush also feeds the daily "minigame" quest counter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local MinigameService = {}

local DataService
local BrainrotFactory
local QuestService
local updateRemote

local active = false
local rushEndsAt = 0
local coins = {} -- live coin Models on the ring
local scores = {} -- [Player] = coins collected this rush
local bestScores = {} -- [Player] = best coins in one rush, all time
local rushNumber = 0
local spawnedThisRush = 0

local COLLECT_RANGE = 20

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

local function announceAll(text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	local banner = remotes and remotes:FindFirstChild("EventBanner")
	if announce then
		announce:FireAllClients(text)
	end
	if banner then
		banner:FireAllClients(text)
	end
end

function MinigameService.active()
	return active
end

-- A random spot on the fountain ring: a random angle and a radius
-- jittered around the ring, so coins never stack on one another.
local function ringSpot()
	local angle = math.random() * math.pi * 2
	local radius = Config.MINIGAME_RING_RADIUS + math.random(-4, 4)
	local center = Config.MINIGAME_RING_CENTER
	return Vector3.new(
		center.X + math.cos(angle) * radius,
		center.Y + 2,
		center.Z + math.sin(angle) * radius
	)
end

-- The best-score board: every player's best rush, best first.
function MinigameService.topScores(count)
	local rows = {}
	for player, best in pairs(bestScores) do
		table.insert(rows, { name = player.Name, best = best })
	end
	table.sort(rows, function(a, b)
		return a.best > b.best
	end)
	local top = {}
	for i = 1, math.min(count or 5, #rows) do
		table.insert(top, rows[i])
	end
	return top
end

-- The snapshot the HUD minigame panel reads: live or not, time left,
-- coins still on the ring, the caller's score and best, and the board.
function MinigameService.snapshotFor(player)
	local state = DataService and DataService.get(player)
	return {
		active = active,
		timeLeft = active and math.max(0, rushEndsAt - os.clock()) or 0,
		coinsLeft = #coins,
		myScore = scores[player] or 0,
		myBest = bestScores[player] or (state and state.MinigameBest or 0),
		top = MinigameService.topScores(5),
		rushNumber = rushNumber,
	}
end

local function pushUpdate()
	if updateRemote then
		for _, player in ipairs(Players:GetPlayers()) do
			updateRemote:FireClient(player, MinigameService.snapshotFor(player))
		end
	end
end

local function pushUpdateTo(player)
	if updateRemote and player and player.Parent then
		updateRemote:FireClient(player, MinigameService.snapshotFor(player))
	end
end

-- Spawn one coin on the ring and wire its click. The coin spins in
-- place (its own little loop) and vanishes if the rush ends first.
function MinigameService.spawnCoin()
	if not active then
		return
	end
	if #coins >= Config.MINIGAME_MAX_COINS then
		return
	end
	local coin = BrainrotFactory.createCoinModel()
	coin:PivotTo(CFrame.new(ringSpot()))
	coin.Parent = Workspace
	table.insert(coins, coin)
	spawnedThisRush += 1
	local detector = coin:FindFirstChildOfClass("ClickDetector")
	if detector then
		detector.MouseClick:Connect(function(player)
			MinigameService.tryCollect(player, coin)
		end)
	end
	-- The coin bobs and spins while it waits to be collected.
	task.spawn(function()
		local base = coin:GetPivot()
		local t = 0
		while coin.Parent and active do
			t += 0.1
			task.wait(0.1)
			if coin.Parent then
				coin:PivotTo(base * CFrame.new(0, math.sin(t * 3) * 0.5, 0) * CFrame.Angles(0, t, 0))
			end
		end
	end)
	pushUpdate()
end

-- Collect a coin: the rush must be live, the coin must still be on
-- the ring, and the clicker must stand within 20 studs of it. Pays
-- $250 at once, bumps the score, and keeps the best-score board fresh.
function MinigameService.tryCollect(player, coin)
	if not active then
		return
	end
	local state = DataService and DataService.get(player)
	if not state then
		return
	end
	local found = false
	for i, c in ipairs(coins) do
		if c == coin then
			table.remove(coins, i)
			found = true
			break
		end
	end
	if not found or not coin.Parent then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if (coin:GetPivot().Position - root.Position).Magnitude > COLLECT_RANGE then
		announceTo(player, "Too far from that coin — get closer and click it!")
		table.insert(coins, coin)
		return
	end
	coin:Destroy()
	DataService.addCash(state, Config.MINIGAME_COIN_VALUE)
	scores[player] = (scores[player] or 0) + 1
	local best = math.max(bestScores[player] or 0, scores[player])
	bestScores[player] = best
	if scores[player] > (state.MinigameBest or 0) then
		state.MinigameBest = scores[player]
	end
	if QuestService then
		QuestService.addProgress(player, "minigame", 1)
	end
	pushUpdateTo(player)
end

-- Start a rush: clear the old scores, spawn the first coins, and let
-- the spawner top the ring up until the timer ends.
function MinigameService.startRush()
	if active then
		return
	end
	active = true
	rushEndsAt = os.clock() + Config.MINIGAME_DURATION_SECONDS
	table.clear(scores)
	table.clear(coins)
	spawnedThisRush = 0
	rushNumber += 1
	announceAll("COIN RUSH #" .. tostring(rushNumber) .. "! Gold coins are popping up around the fountain — click them for " .. Utils.formatMoney(Config.MINIGAME_COIN_VALUE) .. " each! Top collector wins " .. Utils.formatMoney(Config.MINIGAME_TOP_BONUS) .. "!")
	for _ = 1, 4 do
		MinigameService.spawnCoin()
	end
	pushUpdate()
	-- Top the ring up every few seconds while the rush runs.
	task.spawn(function()
		while active do
			task.wait(4)
			if active then
				MinigameService.spawnCoin()
			end
		end
	end)
	-- The rush ends on its timer; the bonus goes to the top collector.
	task.delay(Config.MINIGAME_DURATION_SECONDS, function()
		if active then
			MinigameService.endRush()
		end
	end)
end

-- End a rush: pay the top collector their bonus, sweep the leftover
-- coins off the ring, and publish the final board.
function MinigameService.endRush()
	active = false
	for _, coin in ipairs(coins) do
		if coin.Parent then
			coin:Destroy()
		end
	end
	table.clear(coins)
	local bestPlayer = nil
	local bestScore = 0
	for player, score in pairs(scores) do
		if score > bestScore then
			bestScore = score
			bestPlayer = player
		end
	end
	if bestPlayer and bestScore > 0 then
		local state = DataService and DataService.get(bestPlayer)
		if state then
			DataService.addCash(state, Config.MINIGAME_TOP_BONUS)
			announceAll("COIN RUSH OVER! " .. bestPlayer.Name .. " collected " .. tostring(bestScore) .. " coins and wins the " .. Utils.formatMoney(Config.MINIGAME_TOP_BONUS) .. " bonus!")
		end
	else
		announceAll("Coin rush over — nobody collected a coin this time!")
	end
	pushUpdate()
end

-- A player's best rush, for the HUD and the leaderboard. Zero when
-- they have never played a rush.
function MinigameService.bestOf(player)
	return bestScores[player] or 0
end

-- A player's score in the live rush, for the prompt line. Zero when
-- no rush is running or they have collected nothing yet.
function MinigameService.scoreOf(player)
	return scores[player] or 0
end

function MinigameService.init(services)
	DataService = services.DataService
	BrainrotFactory = services.BrainrotFactory
	QuestService = services.QuestService
	updateRemote = services.Remotes.MinigameUpdate

	-- A rush every 3 minutes, plus one 45 seconds after the server
	-- starts so the first players see the game at once.
	task.spawn(function()
		task.wait(45)
		while true do
			if not active then
				MinigameService.startRush()
			end
			task.wait(Config.MINIGAME_INTERVAL_SECONDS)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		scores[player] = nil
		bestScores[player] = nil
		pushUpdate()
	end)
end

return MinigameService
