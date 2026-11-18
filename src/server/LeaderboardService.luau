-- Brainrot Boulevard v2: the leaderboard. Every player's lifetime
-- earnings, best $/s, brainrots bought, steals claimed and slaps landed
-- are tracked live, ranked top-5, and broadcast to every client every
-- few seconds. Personal bests persist across sessions in a DataStore
-- (pcall-guarded: in Studio without API access it falls back to the
-- live session table, so the game never breaks). The server stays the
-- authority — clients only ever display what this service sends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LeaderboardService = {}

local DataService
local boardRemote

-- Session table: [userId] = { name, earned, bestIncome, bought, steals, slaps }
local sessionBests = {}
local store = nil

local function loadStore()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("BoulevardBestsV2")
	end)
	if ok then
		store = result
	end
end

local function loadBest(player)
	local best = { name = player.Name, earned = 0, bestIncome = 0, bought = 0, steals = 0, slaps = 0 }
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("best_" .. tostring(player.UserId))
		end)
		if ok and type(saved) == "table" then
			best.earned = saved.earned or 0
			best.bestIncome = saved.bestIncome or 0
			best.bought = saved.bought or 0
			best.steals = saved.steals or 0
			best.slaps = saved.slaps or 0
		end
	end
	sessionBests[player.UserId] = best
	return best
end

local function saveBest(player)
	local best = sessionBests[player.UserId]
	if not best or not store then
		return
	end
	pcall(function()
		store:SetAsync("best_" .. tostring(player.UserId), {
			earned = best.earned,
			bestIncome = best.bestIncome,
			bought = best.bought,
			steals = best.steals,
			slaps = best.slaps,
		})
	end)
end

-- Fold this session's live state into the player's persistent bests.
function LeaderboardService.record(player, state)
	if not player or not state then
		return
	end
	local best = sessionBests[player.UserId] or loadBest(player)
	best.name = player.Name
	best.earned = math.max(best.earned, math.floor(state.TotalEarned))
	local income = DataService and DataService.incomePerSecond(state) or 0
	best.bestIncome = math.max(best.bestIncome, math.floor(income))
	best.bought = math.max(best.bought, state.Bought or 0)
	best.steals = math.max(best.steals, state.Steals or 0)
	best.slaps = math.max(best.slaps, state.Slaps or 0)
end

-- Top N players by lifetime earnings, best first.
function LeaderboardService.top(count)
	local rows = {}
	for _, best in pairs(sessionBests) do
		table.insert(rows, {
			name = best.name,
			earned = best.earned,
			bestIncome = best.bestIncome,
			bought = best.bought,
			steals = best.steals,
			slaps = best.slaps,
		})
	end
	table.sort(rows, function(a, b)
		return a.earned > b.earned
	end)
	local out = {}
	for i = 1, math.min(count or Config.LEADERBOARD_TOP, #rows) do
		table.insert(out, rows[i])
	end
	return out
end

-- One player's own persistent bests, for the HUD stats line.
function LeaderboardService.personalBest(player)
	local best = sessionBests[player.UserId]
	if not best then
		return nil
	end
	return {
		earned = best.earned,
		bestIncome = best.bestIncome,
		bought = best.bought,
		steals = best.steals,
		slaps = best.slaps,
	}
end

function LeaderboardService.init(services)
	DataService = services.DataService
	boardRemote = services.Remotes.LeaderboardUpdate
	loadStore()

	Players.PlayerAdded:Connect(function(player)
		loadBest(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local state = DataService and DataService.get(player)
		if state then
			LeaderboardService.record(player, state)
		end
		saveBest(player)
		sessionBests[player.UserId] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		loadBest(player)
	end

	-- Broadcast the top 5 every few seconds; the HUD panel is display-only.
	task.spawn(function()
		while true do
			task.wait(Config.LEADERBOARD_BROADCAST_SECONDS)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = DataService and DataService.get(player)
				if state then
					LeaderboardService.record(player, state)
				end
			end
			if boardRemote then
				boardRemote:FireAllClients(LeaderboardService.top())
			end
		end
	end)
end

return LeaderboardService
