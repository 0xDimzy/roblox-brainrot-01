-- Brainrot Boulevard: one place for player state. Cash, income, rebirths,
-- total earned, and the plot a player owns. The income tick runs here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local DataService = {}

local states = {} -- [Player] = state
local eventMultiplier = 1

function DataService.setEventMultiplier(mult)
	eventMultiplier = mult
end

function DataService.getEventMultiplier()
	return eventMultiplier
end

function DataService.newState(player)
	local state = {
		Player = player,
		Cash = Config.START_CASH,
		TotalEarned = 0,
		Rebirths = 0,
		Owned = {}, -- brainrot Models placed on this player's plot
		PlotIndex = 0,
		Carrying = nil, -- brainrot Model being carried, if any
		HasCoil = false,
		LockUntil = 0,
		Traps = 0,
		-- v2 stats, fed by the leaderboard service and the HUD stats line.
		Bought = 0,
		Steals = 0,
		Slaps = 0,
		BestIncome = 0,
	}
	states[player] = state

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = state.Cash
	cash.Parent = leaderstats

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	state.LeaderCash = cash
	state.LeaderBrainrots = brainrots
	state.LeaderRebirths = rebirths
	return state
end

function DataService.get(player)
	return states[player]
end

function DataService.remove(player)
	states[player] = nil
end

function DataService.rebirthMultiplier(state)
	return Config.REBIRTH_MULTIPLIER ^ state.Rebirths
end

-- $/s across everything this player owns, before the event multiplier.
function DataService.baseIncome(state)
	local total = 0
	local rebirthMult = DataService.rebirthMultiplier(state)
	for _, model in ipairs(state.Owned) do
		local def = BrainrotData.getById(model:GetAttribute("BrainrotId"))
		if def then
			total += BrainrotData.incomeOf(def, model:GetAttribute("MutationIndex") or 1, rebirthMult)
		end
	end
	return total
end

function DataService.incomePerSecond(state)
	return DataService.baseIncome(state) * eventMultiplier
end

function DataService.addCash(state, amount)
	state.Cash += amount
	state.TotalEarned += amount
	state.LeaderCash.Value = math.floor(state.Cash)
end

-- Returns true when the player could afford it; never goes negative.
function DataService.spendCash(state, amount)
	if state.Cash < amount then
		return false
	end
	state.Cash -= amount
	state.LeaderCash.Value = math.floor(state.Cash)
	return true
end

function DataService.addOwned(state, model)
	table.insert(state.Owned, model)
	state.LeaderBrainrots.Value = #state.Owned
end

function DataService.removeOwned(state, model)
	for i, m in ipairs(state.Owned) do
		if m == model then
			table.remove(state.Owned, i)
			break
		end
	end
	state.LeaderBrainrots.Value = #state.Owned
end

function DataService.isLocked(state)
	return os.clock() < state.LockUntil
end

-- The 1-second income tick: every owned brainrot pays its rate.
function DataService.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Config.INCOME_TICK_SECONDS)
			for player, state in pairs(states) do
				if player.Parent then
					local income = DataService.incomePerSecond(state)
					-- v2: track the player's best-ever $/s for the leaderboard.
					if income > state.BestIncome then
						state.BestIncome = income
					end
					if income > 0 then
						DataService.addCash(state, income)
					end
				end
			end
		end
	end)
end

-- Push a fresh HUD snapshot to one player (called by the state broadcaster).
function DataService.snapshot(state)
	return {
		cash = math.floor(state.Cash),
		income = DataService.incomePerSecond(state),
		count = #state.Owned,
		rebirths = state.Rebirths,
		rebirthCost = Config.rebirthCost(state.Rebirths),
		totalEarned = math.floor(state.TotalEarned),
		plotIndex = state.PlotIndex,
		lockedFor = math.max(0, state.LockUntil - os.clock()),
		eventMult = eventMultiplier,
		-- v2: personal stats for the HUD stats line.
		bought = state.Bought,
		steals = state.Steals,
		slaps = state.Slaps,
		bestIncome = math.floor(state.BestIncome),
		owned = (function()
			local list = {}
			for _, model in ipairs(state.Owned) do
				local def = BrainrotData.getById(model:GetAttribute("BrainrotId"))
				if def then
					table.insert(list, {
						name = BrainrotData.displayName(def, model:GetAttribute("MutationIndex") or 1),
						rarity = BrainrotData.rarityOf(def).name,
						rate = BrainrotData.incomeOf(def, model:GetAttribute("MutationIndex") or 1, DataService.rebirthMultiplier(state)),
					})
				end
			end
			return list
		end)(),
	}
end

Players.PlayerRemoving:Connect(function(player)
	DataService.remove(player)
end)

return DataService
