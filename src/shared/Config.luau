-- Brainrot Boulevard: shared tuning. One place for every number the
-- server and the client both need, so a balance change is one edit.

local Config = {}

-- Economy
Config.START_CASH = 100
Config.INCOME_TICK_SECONDS = 1
Config.BUY_RANGE_STUDS = 14
Config.STEAL_RANGE_STUDS = 12
Config.CARRY_CHANNEL_SECONDS = 3
Config.DROPPED_RETURN_SECONDS = 15

-- Conveyor
Config.CONVEYOR_MIN_X = -62
Config.CONVEYOR_MAX_X = 62
Config.CONVEYOR_Z = -25
Config.CONVEYOR_SPEED = 4 -- studs per second
Config.CONVEYOR_SPAWN_SECONDS = 4
Config.CONVEYOR_MAX_BRAINROTS = 10

-- Plots: 8 bases, 4 north and 4 south of the plaza.
Config.PLOT_COUNT = 8
Config.PLOT_PEDESTALS = 6
Config.PLOT_POSITIONS = {
	Vector3.new(-60, 1, -58),
	Vector3.new(-20, 1, -58),
	Vector3.new(20, 1, -58),
	Vector3.new(60, 1, -58),
	Vector3.new(-60, 1, 58),
	Vector3.new(-20, 1, 58),
	Vector3.new(20, 1, 58),
	Vector3.new(60, 1, 58),
}
Config.PLOT_COLORS = {
	Color3.fromRGB(255, 107, 107),
	Color3.fromRGB(255, 195, 0),
	Color3.fromRGB(88, 214, 141),
	Color3.fromRGB(93, 173, 226),
	Color3.fromRGB(175, 122, 197),
	Color3.fromRGB(244, 114, 182),
	Color3.fromRGB(72, 201, 176),
	Color3.fromRGB(245, 176, 65),
}

-- Shop
Config.SHOP_ITEMS = {
	{ id = "Coil", name = "Speed Coil", cost = 1000, desc = "+6 walk speed, forever" },
	{ id = "Lock", name = "Base Lock", cost = 2000, desc = "Your base cannot be stolen from for 60s" },
	{ id = "Trap", name = "Slime Trap", cost = 750, desc = "Slows thieves on your base for 5s" },
	{ id = "Egg", name = "Lucky Egg", cost = 5000, desc = "Hatches a random Epic-or-better brainrot" },
	-- v2: Freeze Trap — thieves crossing it are frozen solid for 4 seconds.
	{ id = "Freeze", name = "Freeze Trap", cost = 1500, desc = "Freezes thieves on your base for 4s" },
}
Config.LOCK_DURATION_SECONDS = 60
Config.TRAP_SLOW_SECONDS = 5
Config.COIL_SPEED_BONUS = 6
Config.FREEZE_SECONDS = 4

-- v2 leaderboard: top N players by lifetime earnings, broadcast often.
Config.LEADERBOARD_TOP = 5
Config.LEADERBOARD_BROADCAST_SECONDS = 5

-- Rebirth: cost grows with the square of (rebirths + 1).
Config.REBIRTH_BASE_COST = 100000
Config.REBIRTH_MULTIPLIER = 2

function Config.rebirthCost(rebirths)
	return Config.REBIRTH_BASE_COST * (rebirths + 1) * (rebirths + 1)
end

-- v2.5 pets: six companions that follow the player and boost all income.
-- bonus adds to the income multiplier (0.10 = +10% while owned, equipped
-- or not). Costs are in-game cash only; pets survive a rebirth.
Config.PETS = {
	{ id = "milo-moth", name = "Milo the Moth", cost = 2500, bonus = 0.10, color = Color3.fromRGB(220, 200, 140), desc = "+10% income, flutters along" },
	{ id = "biscuit-blob", name = "Biscuit Blob", cost = 6000, bonus = 0.15, color = Color3.fromRGB(255, 170, 120), desc = "+15% income, wobbles happily" },
	{ id = "sir-peeps", name = "Sir Peeps", cost = 12000, bonus = 0.20, color = Color3.fromRGB(255, 230, 80), desc = "+20% income, a tiny knight" },
	{ id = "noodle-nibbler", name = "Noodle Nibbler", cost = 25000, bonus = 0.25, color = Color3.fromRGB(255, 210, 140), desc = "+25% income, slurps luck" },
	{ id = "captain-crumbs", name = "Captain Crumbs", cost = 50000, bonus = 0.35, color = Color3.fromRGB(140, 180, 255), desc = "+35% income, sails the plaza" },
	{ id = "void-kitten", name = "Void Kitten", cost = 100000, bonus = 0.50, color = Color3.fromRGB(60, 60, 90), desc = "+50% income, stares into profit" },
}

function Config.petById(id)
	for _, pet in ipairs(Config.PETS) do
		if pet.id == id then
			return pet
		end
	end
	return nil
end

-- v2.5 events: weights for the weighted roll in EventService. A higher
-- weight rolls more often; the three v2.5 events sit beside the original
-- three, so any of the six can fire each interval.
Config.EVENT_WEIGHTS = {
	GoldenHour = 3,
	BrainrotRain = 3,
	Tsunami = 2,
	MeteorShower = 3,
	DoubleCashHour = 2,
	SlimeInvasion = 3,
}

-- v2.5 rebirth milestones: rebirths -> a title and a one-off cash bonus,
-- paid the moment the rebirth lands. The pet bonus is separate (see
-- RebirthService.petBonusFor): +5% income per pet owned at rebirth time.
Config.REBIRTH_MILESTONES = {
	[3] = { title = "Boulevard Regular", bonus = 5000 },
	[5] = { title = "Boulevard Legend", bonus = 25000 },
	[10] = { title = "Ohio Royalty", bonus = 100000 },
}

-- Events: one rolls every interval, lasts up to its duration.
Config.EVENT_INTERVAL_SECONDS = 90
Config.EVENT_DURATION_SECONDS = 60
Config.TSUNAMI_SWEEP_SECONDS = 12

-- Spawn
Config.SPAWN_POSITION = Vector3.new(0, 3, 45)

return Config
