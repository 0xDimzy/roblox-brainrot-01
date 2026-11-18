-- Brainrot Boulevard v2.5: daily quests. Three quests rotate every day —
-- one earn, one buy, one steal — picked deterministically from the pool
-- by the day of the year, so every player in the server chases the same
-- three and the board never needs a network call. Progress is tracked
-- server-side: the income tick feeds "earn", ConveyorService feeds "buy"
-- on every purchase, StealService feeds "steal" on every claimed steal.
-- A finished quest pays its cash reward once, claimed from the quest
-- panel (J) — the server checks progress and the claimed flag, never
-- the client. Quests reset at midnight: the first progress event of a
-- new day clears yesterday's counters and claims.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local QuestService = {}

local DataService

-- The pool: three quests per kind, easy / medium / hard. The day's pick
-- is one of each kind, so the board always shows all three play styles.
-- reward is in-game cash, paid once per quest per day.
local QUEST_POOL = {
	{ id = "earn-1", kind = "earn", target = 5000, reward = 1500, title = "Earn $5,000 today" },
	{ id = "earn-2", kind = "earn", target = 25000, reward = 6000, title = "Earn $25,000 today" },
	{ id = "earn-3", kind = "earn", target = 100000, reward = 20000, title = "Earn $100,000 today" },
	{ id = "buy-1", kind = "buy", target = 3, reward = 1000, title = "Buy 3 brainrots" },
	{ id = "buy-2", kind = "buy", target = 8, reward = 3000, title = "Buy 8 brainrots" },
	{ id = "buy-3", kind = "buy", target = 15, reward = 8000, title = "Buy 15 brainrots" },
	{ id = "steal-1", kind = "steal", target = 1, reward = 2000, title = "Steal 1 brainrot" },
	{ id = "steal-2", kind = "steal", target = 3, reward = 6000, title = "Steal 3 brainrots" },
	{ id = "steal-3", kind = "steal", target = 5, reward = 15000, title = "Steal 5 brainrots" },
}

local KINDS = { "earn", "buy", "steal" }

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

-- Today's date key, e.g. "2026-11-18". The day of the year seeds the
-- rotation, so the board is the same for everyone and changes at midnight.
local function todayKey()
	return os.date("%Y-%m-%d")
end

local function dayOfYear()
	return tonumber(os.date("%j")) or 1
end

-- The three quests of the day: one per kind, rotating through the pool.
-- Day N picks index (N + kindOffset) mod 3 for each kind, so no two days
-- in a row repeat the same trio and every quest comes up every third day.
function QuestService.todaysQuests()
	local day = dayOfYear()
	local todays = {}
	for kindIndex, kind in ipairs(KINDS) do
		local pool = {}
		for _, quest in ipairs(QUEST_POOL) do
			if quest.kind == kind then
				table.insert(pool, quest)
			end
		end
		local pick = ((day + kindIndex - 1) % #pool) + 1
		table.insert(todays, pool[pick])
	end
	return todays
end

-- Find a quest definition by id, searching today's trio first and then
-- the whole pool (so a claim for yesterday's quest can still be refused
-- cleanly instead of erroring).
function QuestService.getQuest(questId)
	for _, quest in ipairs(QuestService.todaysQuests()) do
		if quest.id == questId then
			return quest, true
		end
	end
	for _, quest in ipairs(QUEST_POOL) do
		if quest.id == questId then
			return quest, false
		end
	end
	return nil, false
end

-- Is this quest one of today's three?
function QuestService.isTodays(questId)
	local _, todays = QuestService.getQuest(questId)
	return todays
end

-- Roll the player's quest state over to a new day: counters and claims
-- clear, so yesterday's progress never pays twice.
function QuestService.resetIfNewDay(state)
	local today = todayKey()
	if state.QuestDay ~= today then
		state.QuestDay = today
		state.QuestProgress = { earn = 0, buy = 0, steal = 0 }
		state.QuestsClaimed = {}
		state.QuestsNotified = {}
	end
end

-- Add progress to one kind ("earn", "buy" or "steal"). Called by the
-- income tick, the conveyor and the steal claim. When a quest crosses
-- its target the player gets one toast — the notified flag stops repeats.
function QuestService.addProgress(player, kind, amount)
	local state = DataService.get(player)
	if not state then
		return
	end
	QuestService.resetIfNewDay(state)
	local before = state.QuestProgress[kind] or 0
	state.QuestProgress[kind] = before + amount
	for _, quest in ipairs(QuestService.todaysQuests()) do
		if quest.kind == kind and before < quest.target and state.QuestProgress[kind] >= quest.target then
			if not state.QuestsNotified[quest.id] then
				state.QuestsNotified[quest.id] = true
				announceTo(player, "QUEST COMPLETE: " .. quest.title .. "! Press J to claim " .. Utils.formatMoney(quest.reward) .. ".")
			end
		end
	end
end

-- The player's progress on one quest, by its kind counter.
function QuestService.progressOf(state, quest)
	QuestService.resetIfNewDay(state)
	return state.QuestProgress[quest.kind] or 0
end

-- Is this quest finished (progress at or past its target)?
function QuestService.isDone(state, quest)
	return QuestService.progressOf(state, quest) >= quest.target
end

-- Has this quest's reward already been claimed today?
function QuestService.isClaimed(state, questId)
	QuestService.resetIfNewDay(state)
	return state.QuestsClaimed[questId] == true
end

-- How many of today's three quests are finished (claimed or not).
function QuestService.doneCount(state)
	local done = 0
	for _, quest in ipairs(QuestService.todaysQuests()) do
		if QuestService.isDone(state, quest) then
			done += 1
		end
	end
	return done
end

-- How many of today's three are claimed already.
function QuestService.claimedCount(state)
	local claimed = 0
	for _, quest in ipairs(QuestService.todaysQuests()) do
		if QuestService.isClaimed(state, quest.id) then
			claimed += 1
		end
	end
	return claimed
end

-- Claim a finished quest's reward. The client sends the quest's index
-- in today's trio (1-3); the server resolves it, checks the day, the
-- progress and the claimed flag, then pays. Nothing here trusts the client.
function QuestService.claim(player, questIndex)
	local state = DataService.get(player)
	if not state then
		return
	end
	QuestService.resetIfNewDay(state)
	local todays = QuestService.todaysQuests()
	local quest = todays[questIndex]
	if not quest then
		return
	end
	if QuestService.isClaimed(state, quest.id) then
		announceTo(player, "Already claimed: " .. quest.title .. ".")
		return
	end
	if not QuestService.isDone(state, quest) then
		local remaining = quest.target - QuestService.progressOf(state, quest)
		local unit = ""
		if quest.kind == "earn" then
			unit = " more to earn"
		elseif quest.kind == "buy" then
			unit = " more brainrots to buy"
		else
			unit = " more brainrots to steal"
		end
		announceTo(player, "Not done yet: " .. tostring(remaining) .. unit .. " for " .. quest.title .. ".")
		return
	end
	state.QuestsClaimed[quest.id] = true
	DataService.addCash(state, quest.reward)
	announceTo(player, "QUEST REWARD: +" .. Utils.formatMoney(quest.reward) .. " for " .. quest.title .. "!")
	-- All three claimed in one day is a clean sweep: a bonus on top.
	if QuestService.claimedCount(state) == 3 then
		local sweepBonus = 5000
		DataService.addCash(state, sweepBonus)
		announceTo(player, "CLEAN SWEEP! All 3 daily quests done — bonus +" .. Utils.formatMoney(sweepBonus) .. "!")
	end
end

-- The snapshot the HUD quest panel reads: today's three quests with
-- live progress, done and claimed flags, plus the day key so the client
-- can tell when the board rolls over.
function QuestService.snapshotFor(state)
	QuestService.resetIfNewDay(state)
	local list = {}
	for _, quest in ipairs(QuestService.todaysQuests()) do
		local progress = QuestService.progressOf(state, quest)
		table.insert(list, {
			id = quest.id,
			title = quest.title,
			kind = quest.kind,
			progress = progress,
			target = quest.target,
			reward = quest.reward,
			done = progress >= quest.target,
			claimed = state.QuestsClaimed[quest.id] == true,
			frac = Utils.progress(progress, quest.target),
		})
	end
	return {
		day = state.QuestDay,
		quests = list,
		done = QuestService.doneCount(state),
		claimed = QuestService.claimedCount(state),
	}
end

function QuestService.init(services)
	DataService = services.DataService

	-- The income tick feeds "earn" progress through this hook.
	DataService.setIncomeHook(function(player, amount)
		QuestService.addProgress(player, "earn", amount)
	end)

	-- The HUD reads quests through the DataService snapshot hook.
	DataService.setQuestSnapshot(function(state)
		return QuestService.snapshotFor(state)
	end)

	services.Remotes.ClaimQuest.OnServerEvent:Connect(function(player, questIndex)
		QuestService.claim(player, questIndex)
	end)

	-- A player joining mid-day starts on today's board at once.
	Players.PlayerAdded:Connect(function(player)
		task.wait(1)
		local state = DataService.get(player)
		if state then
			QuestService.resetIfNewDay(state)
		end
	end)
end

return QuestService
