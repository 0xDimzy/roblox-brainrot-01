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
-- v3: 4 more bases float in the Sky Plaza, 40 studs up at the same
-- north x/z as plots 1-4. Sky bases earn a 25% income multiplier
-- (Config.SKY_PLOT_MULTIPLIER) — the climb is the reward.
Config.PLOT_COUNT = 12
Config.PLOT_PEDESTALS = 6
Config.SKY_PLOT_FIRST_INDEX = 9
Config.SKY_PLOT_MULTIPLIER = 1.25
Config.SKY_LIFT_POSITION = Vector3.new(0, 1, 20)
Config.SKY_RETURN_POSITION = Vector3.new(0, 41, -40)
Config.PLOT_POSITIONS = {
	Vector3.new(-60, 1, -58),
	Vector3.new(-20, 1, -58),
	Vector3.new(20, 1, -58),
	Vector3.new(60, 1, -58),
	Vector3.new(-60, 1, 58),
	Vector3.new(-20, 1, 58),
	Vector3.new(20, 1, 58),
	Vector3.new(60, 1, 58),
	Vector3.new(-60, 40, -58),
	Vector3.new(-20, 40, -58),
	Vector3.new(20, 40, -58),
	Vector3.new(60, 40, -58),
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
	Color3.fromRGB(255, 140, 220),
	Color3.fromRGB(140, 220, 255),
	Color3.fromRGB(255, 220, 140),
	Color3.fromRGB(180, 255, 140),
}

-- Shop
Config.SHOP_ITEMS = {
	{ id = "Coil", name = "Speed Coil", cost = 1000, desc = "+6 walk speed, forever" },
	{ id = "Lock", name = "Base Lock", cost = 2000, desc = "Your base cannot be stolen from for 60s" },
	{ id = "Trap", name = "Slime Trap", cost = 750, desc = "Slows thieves on your base for 5s" },
	{ id = "Egg", name = "Lucky Egg", cost = 5000, desc = "Hatches a random Epic-or-better brainrot" },
	-- v2: Freeze Trap — thieves crossing it are frozen solid for 4 seconds.
	{ id = "Freeze", name = "Freeze Trap", cost = 1500, desc = "Freezes thieves on your base for 4s" },
	-- v3: Raid Potion (+50% boss damage for 5 minutes), Trade Pass
	-- (your next 3 trades are free of the trade fee), Sky Key (one
	-- teleport straight up to the Sky Plaza, no lift queue).
	{ id = "RaidPotion", name = "Raid Potion", cost = 3000, desc = "+50% boss damage for 5 min" },
	{ id = "TradePass", name = "Trade Pass", cost = 2500, desc = "Next 3 trades are fee-free" },
	{ id = "SkyKey", name = "Sky Key", cost = 5000, desc = "Teleport to the Sky Plaza at once" },
}
Config.LOCK_DURATION_SECONDS = 60
Config.TRAP_SLOW_SECONDS = 5
Config.COIL_SPEED_BONUS = 6
Config.FREEZE_SECONDS = 4

-- v3 shop: the raid potion lasts 5 minutes; the trade pass covers 3
-- trades; the sky key is spent the moment it teleports you.
Config.RAID_POTION_SECONDS = 300
Config.RAID_POTION_BONUS = 0.5
Config.TRADE_PASS_USES = 3

-- v3 trading: an offer lives 60 seconds, a player holds at most 3 live
-- offers at once, and a completed trade takes a 5% cash fee from the
-- cash side of the deal (waived while a Trade Pass is active).
Config.TRADE_OFFER_EXPIRY_SECONDS = 60
Config.TRADE_MAX_ACTIVE = 3
Config.TRADE_FEE_RATE = 0.05

-- v3 boss raids: every hour a boss brainrot spawns on the raid pad
-- south of the spawn. Slap it or press F near it to deal damage; the
-- reward pool splits by damage share when it dies. Slaps deal double
-- a normal hit, pets add +5% damage each, rebirths +5% each.
Config.RAID_PAD_POSITION = Vector3.new(0, 1, 70)
Config.RAID_BOSS_HP = 5000
Config.RAID_INTERVAL_SECONDS = 3600
Config.RAID_DURATION_SECONDS = 300
Config.RAID_REWARD_POOL = 50000
Config.RAID_HIT_DAMAGE = 25
Config.RAID_SLAP_DAMAGE = 50
Config.RAID_HIT_RANGE_STUDS = 16
Config.RAID_HIT_COOLDOWN = 0.8
Config.RAID_BOSS_IDS = { "mega-ohio-boss", "ohio-boss", "ceo-of-ohio", "the-algorithm" }

-- v3 minigames: every 3 minutes a coin rush runs for 45 seconds. Gold
-- coins pop up around the fountain ring; click one to collect it for
-- cash. The top collector takes a bonus on top of their coins.
Config.MINIGAME_INTERVAL_SECONDS = 180
Config.MINIGAME_DURATION_SECONDS = 45
Config.MINIGAME_COIN_VALUE = 250
Config.MINIGAME_MAX_COINS = 12
Config.MINIGAME_TOP_BONUS = 5000
Config.MINIGAME_RING_RADIUS = 18
Config.MINIGAME_RING_CENTER = Vector3.new(0, 1, 10)

-- v3 teams: at most 5 players per team, creating one costs $10,000 in
-- game cash, and the shared vault pays every member $500 an hour.
-- Members deposit cash into the vault; the vault never pays out more
-- than it holds, so a team that never deposits earns nothing.
Config.TEAM_MAX_MEMBERS = 5
Config.TEAM_CREATE_COST = 10000
Config.TEAM_VAULT_HOURLY = 500
Config.TEAM_DEPOSIT_MIN = 100
Config.TEAM_NAME_MAX_LEN = 16

-- v7 fuse machine: stand at the Fuse Machine east of spawn and press G
-- to fuse 3 brainrots of the same rarity into 1 brainrot of the next
-- rarity up. The three lowest earners of that rarity go in; one random
-- brainrot of the rarity above comes out with a fresh mutation roll.
Config.FUSE_COUNT = 3
Config.FUSE_MACHINE_POSITION = Vector3.new(45, 1, 42)
Config.FUSE_RANGE_STUDS = 14
Config.FUSE_COOLDOWN_SECONDS = 5

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
	-- v3: the Boss Raid joins the rotation at weight 2.
	BossRaid = 2,
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

-- v6 daily login rewards: the 7-day ladder at the Daily Shrine, east of
-- the fountain. Each day pays more than the last; day 7 is the jackpot,
-- and every 7th day in a row adds the milestone chest on top. Claim on
-- the shrine pad and the shrine blesses the day's cash with +25%.
Config.DAILY_REWARD_LADDER = {
	{ day = 1, cash = 2500 },
	{ day = 2, cash = 5000 },
	{ day = 3, cash = 9000 },
	{ day = 4, cash = 15000 },
	{ day = 5, cash = 24000 },
	{ day = 6, cash = 38000 },
	{ day = 7, cash = 60000 },
}
Config.DAILY_REWARD_MILESTONE_DAY = 7
Config.DAILY_REWARD_MILESTONE_BONUS = 25000
Config.DAILY_SHRINE_POSITION = Vector3.new(30, 1, 12)
Config.DAILY_SHRINE_RADIUS = 8
Config.DAILY_SHRINE_BLESSING = 0.25

-- Spawn
Config.SPAWN_POSITION = Vector3.new(0, 3, 45)

return Config
