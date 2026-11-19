-- Brainrot Boulevard v3: boss raids. Once an hour a boss brainrot —
-- the Mega Ohio Final Boss by default — spawns on the raid pad south
-- of the spawn and stays for up to 5 minutes. Players deal damage by
-- pressing F near the pad, or by slapping (a slap counts double, and
-- StealService feeds slaps here through recordSlap). Every point of
-- damage is tracked per player; when the boss dies the $50,000 reward
-- pool splits by damage share, and the top contributor also wins a
-- free brainrot straight onto their base. Damage is boosted by pets
-- (+5% each), rebirths (+5% each) and the Raid Potion (+50% for 5
-- minutes). The boss model is built by BrainrotFactory.createBossModel
-- — a 3x-scale brainrot with a crown and an HP billboard. All damage
-- is server-validated: range, cooldown and a live boss.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local RaidService = {}

local DataService
local BaseService
local WorldBuilder
local BrainrotFactory
local PetsService
local RebirthService
local QuestService
local updateRemote

local boss = nil -- the live boss Model, or nil when no raid runs
local bossDef = nil
local bossHp = 0
local bossMaxHp = 0
local raidEndsAt = 0
local contributions = {} -- [Player] = damage dealt this raid
local lastHit = {} -- [Player] = os.clock() of last F-hit (cooldown)
local raidNumber = 0

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

-- Is a raid running right now?
function RaidService.active()
	return boss ~= nil and boss.Parent ~= nil
end

-- How much damage this player deals per hit: base 25, doubled for a
-- slap, then multiplied by pets (+5% each), rebirths (+5% each) and
-- the Raid Potion (+50% while it lasts). The multipliers stack.
function RaidService.damageFor(player, isSlap)
	local state = DataService and DataService.get(player)
	local mult = 1
	if state then
		if PetsService then
			mult += PetsService.raidDamageBonus(state)
		end
		if RebirthService then
			mult += RebirthService.raidBonusFor(state)
		end
		if state.RaidPotionUntil and os.clock() < state.RaidPotionUntil then
			mult += Config.RAID_POTION_BONUS
		end
	end
	local base = isSlap and Config.RAID_SLAP_DAMAGE or Config.RAID_HIT_DAMAGE
	return math.floor(base * mult + 0.5)
end

-- The boss's damage share for one player, as a 0..1 fraction of all
-- damage dealt this raid. Zero when nobody has hit it yet.
function RaidService.shareOf(player)
	local total = 0
	for _, damage in pairs(contributions) do
		total += damage
	end
	if total <= 0 then
		return 0
	end
	return (contributions[player] or 0) / total
end

-- The leaderboard of this raid: players sorted by damage, best first,
-- each with their name and share. The HUD's raid bar shows the top 3.
function RaidService.topContributors(count)
	local rows = {}
	for player, damage in pairs(contributions) do
		table.insert(rows, { name = player.Name, damage = damage, share = RaidService.shareOf(player) })
	end
	table.sort(rows, function(a, b)
		return a.damage > b.damage
	end)
	local top = {}
	for i = 1, math.min(count or 3, #rows) do
		table.insert(top, rows[i])
	end
	return top
end

-- The snapshot the HUD raid bar reads: boss name, HP, time left, the
-- caller's own damage and share, and the top 3 contributors. Empty
-- (active = false) between raids, so the bar hides itself.
function RaidService.snapshotFor(player)
	if not RaidService.active() then
		return { active = false, bossName = "", hp = 0, maxHp = 0, timeLeft = 0, myDamage = 0, myShare = 0, top = {}, raidNumber = raidNumber }
	end
	return {
		active = true,
		bossName = bossDef and bossDef.name or "Boss",
		hp = bossHp,
		maxHp = bossMaxHp,
		timeLeft = math.max(0, raidEndsAt - os.clock()),
		myDamage = contributions[player] or 0,
		myShare = RaidService.shareOf(player),
		top = RaidService.topContributors(3),
		raidNumber = raidNumber,
	}
end

local function pushUpdate()
	if updateRemote then
		for _, player in ipairs(Players:GetPlayers()) do
			updateRemote:FireClient(player, RaidService.snapshotFor(player))
		end
	end
end

local function pushUpdateTo(player)
	if updateRemote and player and player.Parent then
		updateRemote:FireClient(player, RaidService.snapshotFor(player))
	end
end

-- Spawn the boss. bossId names a BrainrotData id (the TOUR.json hook
-- calls this with "mega-ohio-boss"); an unknown id falls back to the
-- hourly rotation through Config.RAID_BOSS_IDS.
function RaidService.spawnBoss(bossId)
	if RaidService.active() then
		return false
	end
	local def = bossId and BrainrotData.getById(bossId) or nil
	if not def then
		local pick = Config.RAID_BOSS_IDS[(raidNumber % #Config.RAID_BOSS_IDS) + 1]
		def = BrainrotData.getById(pick) or BrainrotData.getById("mega-ohio-boss")
	end
	bossDef = def
	bossMaxHp = Config.RAID_BOSS_HP
	bossHp = bossMaxHp
	raidEndsAt = os.clock() + Config.RAID_DURATION_SECONDS
	table.clear(contributions)
	table.clear(lastHit)
	raidNumber += 1
	boss = BrainrotFactory.createBossModel(def)
	boss:SetAttribute("State", "RaidBoss")
	boss:SetAttribute("BossHp", bossHp)
	boss:PivotTo(CFrame.new(Config.RAID_PAD_POSITION + Vector3.new(0, 4, 0)))
	boss.Parent = Workspace
	-- Seed the HP billboard so the bar reads full from the first second.
	local bossBody = boss:FindFirstChild("Body")
	local bossLabel = bossBody and bossBody:FindFirstChild("BossHpLabel")
	local bossText = bossLabel and bossLabel:FindFirstChild("BossHpText")
	if bossText then
		bossText.Text = "BOSS HP: " .. tostring(bossMaxHp) .. " / " .. tostring(bossMaxHp)
	end
	announceAll("BOSS RAID #" .. tostring(raidNumber) .. "! " .. def.name .. " appeared on the raid pad — press F near it to fight! Reward pool " .. Utils.formatMoney(Config.RAID_REWARD_POOL) .. "!")
	pushUpdate()
	return true
end

-- The boss escapes when its timer runs out: no reward, no hard
-- feelings, and the next hourly raid is the one to watch.
function RaidService.endRaidEscaped()
	if not boss then
		return
	end
	announceAll("The boss escaped! The raid is over — the next boss arrives within the hour.")
	RaidService.clearBoss()
	pushUpdate()
end

function RaidService.clearBoss()
	if boss then
		boss:Destroy()
		boss = nil
	end
	bossDef = nil
	bossHp = 0
	bossMaxHp = 0
	table.clear(contributions)
	table.clear(lastHit)
end

-- The boss dies: split the pool by damage share, pay everyone who
-- hit it at least once, and crown the top contributor with a free
-- brainrot on their base (Epic or better, rolled fresh).
function RaidService.endRaidKilled()
	local totalDamage = 0
	for _, damage in pairs(contributions) do
		totalDamage += damage
	end
	if totalDamage <= 0 then
		announceAll("The boss fell, but nobody landed a hit — the reward pool goes unclaimed!")
		RaidService.clearBoss()
		pushUpdate()
		return
	end
	local top = RaidService.topContributors(1)[1]
	local lines = {}
	for player, damage in pairs(contributions) do
		local share = damage / totalDamage
		local reward = math.floor(Config.RAID_REWARD_POOL * share + 0.5)
		local state = DataService and DataService.get(player)
		if state and reward > 0 then
			DataService.addCash(state, reward)
			table.insert(lines, player.Name .. " +" .. Utils.formatMoney(reward))
			if QuestService then
				QuestService.addProgress(player, "raid", damage)
			end
		end
	end
	-- Top contributor bonus: a free Epic-or-better brainrot on their base.
	local topPlayer = top and Players:FindFirstChild(top.name) or nil
	local topState = topPlayer and DataService and DataService.get(topPlayer)
	if topState and topState.PlotIndex > 0 and BaseService.hasFreePedestal(topState.PlotIndex) then
		local def = BrainrotData.rollDef()
		while def.rarity < 3 do
			def = BrainrotData.rollDef()
		end
		local model = BrainrotFactory.createBrainrot(def, BrainrotData.rollMutation())
		model:SetAttribute("Price", 0)
		model:SetAttribute("State", "Owned")
		model:SetAttribute("Owner", topPlayer.Name)
		DataService.addOwned(topState, model)
		BaseService.placeOnPlot(topState.PlotIndex, model, WorldBuilder)
		announceTo(topPlayer, "TOP RAIDER! You won a free " .. BrainrotData.displayName(def, model:GetAttribute("MutationIndex") or 1) .. " for your base!")
	end
	announceAll("BOSS DOWN! " .. (bossDef and bossDef.name or "The boss") .. " is defeated! Rewards: " .. table.concat(lines, ", "))
	RaidService.clearBoss()
	pushUpdate()
end

-- Deal damage to the boss. The client fires this on F; the server
-- checks the raid is live, the player is in range of the pad, and the
-- 0.8s cooldown. A hit that kills the boss pays out at once.
function RaidService.tryHit(player, isSlap)
	if not RaidService.active() then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if (root.Position - Config.RAID_PAD_POSITION).Magnitude > Config.RAID_HIT_RANGE_STUDS then
		if not isSlap then
			announceTo(player, "Get closer to the raid pad to hit the boss!")
		end
		return
	end
	if not isSlap then
		local now = os.clock()
		if lastHit[player] and now - lastHit[player] < Config.RAID_HIT_COOLDOWN then
			return
		end
		lastHit[player] = now
	end
	local damage = RaidService.damageFor(player, isSlap)
	contributions[player] = (contributions[player] or 0) + damage
	bossHp -= damage
	if boss then
		boss:SetAttribute("BossHp", math.max(0, bossHp))
		local hpBar = boss:FindFirstChild("Body")
		local label = hpBar and hpBar:FindFirstChild("BossHpLabel")
		if label then
			local text = label:FindFirstChild("BossHpText")
			if text then
				text.Text = "BOSS HP: " .. tostring(math.max(0, bossHp)) .. " / " .. tostring(bossMaxHp)
			end
		end
	end
	pushUpdateTo(player)
	if bossHp <= 0 then
		RaidService.endRaidKilled()
	end
end

-- StealService calls this when a player lands a slap: a slap near the
-- raid pad counts as a double-damage boss hit, so the slap tool pulls
-- double duty in a raid. A slap far from the pad does nothing here.
function RaidService.recordSlap(player)
	RaidService.tryHit(player, true)
end

-- The hourly loop: a boss every hour on the hour-ish, plus the escape
-- timer that ends a raid nobody finishes in 5 minutes.
function RaidService.startLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			if RaidService.active() and os.clock() >= raidEndsAt then
				RaidService.endRaidEscaped()
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.RAID_INTERVAL_SECONDS)
			if not RaidService.active() then
				RaidService.spawnBoss()
			end
		end
	end)
end

function RaidService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	BrainrotFactory = services.BrainrotFactory
	PetsService = services.PetsService
	RebirthService = services.RebirthService
	QuestService = services.QuestService
	updateRemote = services.Remotes.RaidUpdate

	services.Remotes.RaidHit.OnServerEvent:Connect(function(player)
		RaidService.tryHit(player, false)
	end)

	-- A player who leaves mid-raid keeps their damage share on the
	-- board (they earned it), but they cannot collect: the payout
	-- only fires to players still in the server.
	Players.PlayerRemoving:Connect(function(player)
		pushUpdate()
	end)

	RaidService.startLoop()
	-- The first boss arrives 60 seconds after the server starts, so
	-- the very first players in a fresh server get a raid to fight.
	task.delay(60, function()
		if not RaidService.active() then
			RaidService.spawnBoss()
		end
	end)
end

return RaidService
