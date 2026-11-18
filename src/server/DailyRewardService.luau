-- Brainrot Boulevard v6: daily login rewards. Come back every day, keep
-- the streak alive, and the shrine pays out more the longer the run goes.
-- Day 7 pays the jackpot, and every seventh day in a row adds a milestone
-- chest on top. Miss a day and the streak falls back to day 1 — the
-- shrine has no patience for ghosts. The server is the only thing that
-- can pay: the client asks through the DailyReward RemoteFunction, the
-- server checks the clock, the streak and the claimed flag, then pays
-- cash. One claim per calendar day, and a streak only survives a gap of
-- exactly one day. Stand on the Daily Shrine pad in the plaza when you
-- claim and the shrine adds a 25% blessing on top of the day's reward.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local DailyRewardService = {}

local DataService

local SECONDS_PER_DAY = 86400

-- The calendar day key, e.g. "2026-11-18". The streak is a run of
-- consecutive day keys, so the same key can never pay twice.
local function dayKey(atTime)
	return os.date("%Y-%m-%d", atTime)
end

local function yesterdayKey(atTime)
	return dayKey(atTime - SECONDS_PER_DAY)
end

-- Seconds left until the next claim opens (midnight, local server time).
local function secondsUntilMidnight()
	local now = os.time()
	local parts = os.date("*t", now)
	local midnight = os.time({
		year = parts.year,
		month = parts.month,
		day = parts.day + 1,
		hour = 0,
		min = 0,
		sec = 0,
	})
	return math.max(0, midnight - now)
end

-- The day's cash from the Config ladder. Streaks longer than the ladder
-- keep paying the last rung, so day 8+ still pays like day 7.
local function ladderReward(streakDay)
	local ladder = Config.DAILY_REWARD_LADDER
	local index = math.min(streakDay, #ladder)
	return ladder[index].cash
end

-- Milestone chests land on every multiple of the milestone day: a flat
-- bonus on top of the day's cash, and a louder announcement.
local function milestoneBonus(streakDay)
	if streakDay % Config.DAILY_REWARD_MILESTONE_DAY == 0 then
		return Config.DAILY_REWARD_MILESTONE_BONUS
	end
	return 0
end

-- The streak the HUD should show. A streak whose last claim is older
-- than yesterday is already dead, even if the number is still stored.
local function effectiveStreak(state)
	local today = dayKey(os.time())
	local yesterday = yesterdayKey(os.time())
	if state.DailyClaimedDay == today or state.DailyClaimedDay == yesterday then
		return state.DailyStreak
	end
	return 0
end

-- Is the player's character standing on the shrine pad? The pad sits
-- east of the fountain; the blessing only counts inside its radius.
local function standingOnShrine(player)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	local shrine = Vector3.new(Config.DAILY_SHRINE_POSITION.X, 0, Config.DAILY_SHRINE_POSITION.Z)
	return (flat - shrine).Magnitude <= Config.DAILY_SHRINE_RADIUS
end

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

-- The full status the HUD panel renders: the live streak, whether
-- today's reward is still waiting, what it pays, and the countdown.
function DailyRewardService.statusFor(state)
	local streak = effectiveStreak(state)
	local claimedToday = state.DailyClaimedDay == dayKey(os.time())
	-- Tomorrow's rung: one past the live streak, capped at the ladder top.
	local nextDay = math.min(streak + 1, #Config.DAILY_REWARD_LADDER)
	return {
		streak = streak,
		claimedToday = claimedToday,
		canClaim = not claimedToday,
		nextDay = nextDay,
		nextCash = ladderReward(nextDay),
		nextMilestone = milestoneBonus(nextDay),
		nextIn = claimedToday and secondsUntilMidnight() or 0,
		totalClaims = state.DailyTotalClaims,
		ladder = Config.DAILY_REWARD_LADDER,
	}
end

-- Claim today's reward. The server re-checks everything the client
-- already showed: not claimed today, streak continued or restarted,
-- shrine blessing if standing on the pad. Pays once, then locks the day.
function DailyRewardService.claim(player)
	local state = DataService.get(player)
	if not state then
		return { ok = false, message = "No player state yet — try again in a second." }
	end
	local today = dayKey(os.time())
	if state.DailyClaimedDay == today then
		return { ok = false, message = "Already claimed today — come back tomorrow!" }
	end
	local yesterday = yesterdayKey(os.time())
	if state.DailyClaimedDay == yesterday then
		state.DailyStreak += 1
	else
		state.DailyStreak = 1
	end
	local day = math.min(state.DailyStreak, #Config.DAILY_REWARD_LADDER)
	local cash = ladderReward(day)
	local bonus = milestoneBonus(state.DailyStreak)
	local blessed = standingOnShrine(player)
	local blessing = 0
	if blessed then
		blessing = math.floor(cash * Config.DAILY_SHRINE_BLESSING + 0.5)
	end
	local total = cash + bonus + blessing
	DataService.addCash(state, total)
	state.DailyClaimedDay = today
	state.DailyLastClaim = os.time()
	state.DailyTotalClaims += 1
	local line = "Daily reward day " .. tostring(state.DailyStreak) .. ": +" .. Utils.formatMoney(total) .. "!"
	if bonus > 0 then
		line = line .. " Milestone chest +" .. Utils.formatMoney(bonus) .. "!"
	end
	if blessed then
		line = line .. " Shrine blessing +" .. Utils.formatMoney(blessing) .. "!"
	end
	announceTo(player, line)
	return {
		ok = true,
		message = line,
		paid = total,
		streak = state.DailyStreak,
		day = day,
		blessed = blessed,
		status = DailyRewardService.statusFor(state),
	}
end

-- The snapshot hook: the once-a-second HUD heartbeat carries the daily
-- status, so the panel never needs its own poll loop.
function DailyRewardService.snapshotFor(state)
	return DailyRewardService.statusFor(state)
end

function DailyRewardService.init(services)
	DataService = services.DataService
	DataService.setDailySnapshot(function(state)
		return DailyRewardService.snapshotFor(state)
	end)

	-- The RemoteFunction the client invokes: "status" peeks, "claim"
	-- pays. Anything else is rejected — the server never trusts the
	-- action string for more than routing.
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local fn = Instance.new("RemoteFunction")
	fn.Name = "DailyReward"
	fn.Parent = remotes
	fn.OnServerInvoke = function(player, action)
		if action == "claim" then
			return DailyRewardService.claim(player)
		end
		local state = DataService.get(player)
		if not state then
			return { ok = false, message = "No player state yet." }
		end
		return { ok = true, status = DailyRewardService.statusFor(state) }
	end
end

return DailyRewardService
