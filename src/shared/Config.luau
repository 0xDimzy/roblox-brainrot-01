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
}
Config.LOCK_DURATION_SECONDS = 60
Config.TRAP_SLOW_SECONDS = 5
Config.COIL_SPEED_BONUS = 6

-- Rebirth: cost grows with the square of (rebirths + 1).
Config.REBIRTH_BASE_COST = 100000
Config.REBIRTH_MULTIPLIER = 2

function Config.rebirthCost(rebirths)
	return Config.REBIRTH_BASE_COST * (rebirths + 1) * (rebirths + 1)
end

-- Events: one rolls every interval, lasts up to its duration.
Config.EVENT_INTERVAL_SECONDS = 90
Config.EVENT_DURATION_SECONDS = 60
Config.TSUNAMI_SWEEP_SECONDS = 12

-- Spawn
Config.SPAWN_POSITION = Vector3.new(0, 3, 45)

return Config
