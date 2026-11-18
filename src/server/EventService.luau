-- Brainrot Boulevard: events. One rolls every 90 seconds and runs for a
-- minute: Golden Hour doubles everyone's income, Brainrot Rain drops rare
-- characters on the conveyor, and the Tsunami sweeps the map — anyone not
-- standing on their own base is knocked down and drops what they carry.
-- startEvent is also the TOUR.json hook reviewers use to reach a screen.
-- v6: a replaced event's background tasks stop at once via an epoch guard.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local EventService = {}

local DataService
local ConveyorService
local BaseService
local WorldBuilder
local BrainrotFactory
-- v3: RaidService is optional here — the Boss Raid event spawns a
-- boss through it when registered, and skips quietly when it is not.
local RaidService

-- v2.5: all six events with their roll weights (Config.EVENT_WEIGHTS).
-- GoldenHour and DoubleCashHour both double income; MeteorShower drops
-- free brainrots on random bases; SlimeInvasion spawns cash slimes to
-- pop. The roll is Utils.weightedPick, so a weight-3 event fires 3x as
-- often as a weight-1 one would.
local EVENT_DEFS = {
	{ name = "GoldenHour", weight = 3 },
	{ name = "BrainrotRain", weight = 3 },
	{ name = "Tsunami", weight = 2 },
	{ name = "MeteorShower", weight = 3 },
	{ name = "DoubleCashHour", weight = 2 },
	{ name = "SlimeInvasion", weight = 3 },
	-- v3: the Boss Raid joins the rotation — a boss on the raid pad
	-- that the whole server fights together for a shared reward pool.
	{ name = "BossRaid", weight = 2 },
}
local activeEvent = ""
local eventEndsAt = 0
-- v2.5: which event owns the current income multiplier ("" when none).
-- A multiplier event that is replaced by a non-multiplier event loses
-- its bonus at once; a replacement multiplier event takes ownership.
local multOwner = ""
-- v6: each startEvent bumps the epoch; a replaced event's background
-- tasks watch their epoch and stop at once when a newer one appears,
-- so they never run to completion under a successor event.
local eventEpoch = 0

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

function EventService.init(services)
	DataService = services.DataService
	ConveyorService = services.ConveyorService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	BrainrotFactory = services.BrainrotFactory
	RaidService = services.RaidService

	task.spawn(function()
		while true do
			task.wait(Config.EVENT_INTERVAL_SECONDS)
			-- v2.5: refresh the weights from Config, then roll weighted
			-- over all six events instead of a flat pick of three.
			for _, entry in ipairs(EVENT_DEFS) do
				entry.weight = Config.EVENT_WEIGHTS[entry.name] or entry.weight
			end
			EventService.startEvent(Utils.weightedPick(EVENT_DEFS).name)
		end
	end)
end

function EventService.active()
	if os.clock() < eventEndsAt then
		return activeEvent
	end
	return ""
end

-- v2.5: apply an income multiplier for a while, then drop it — but only
-- if this event still owns the multiplier when the timer fires. Both
-- GoldenHour and the new DoubleCashHour use this; a replacement event
-- takes ownership (or clears it, see startEvent), so a Tsunami mid-hour
-- never leaves a doubled income behind, and a Double Cash Hour that
-- follows a Golden Hour is never cut short by the first hour's timer.
function EventService.applyTimedMultiplier(mult, eventName, seconds)
	DataService.setEventMultiplier(mult)
	multOwner = eventName
	task.delay(seconds, function()
		if multOwner == eventName then
			DataService.setEventMultiplier(1)
			multOwner = ""
		end
	end)
end

-- Start an event by name. Safe to call twice: a running event is replaced,
-- and the replaced event's background tasks stop at once (epoch guard).
function EventService.startEvent(name)
	eventEpoch += 1
	local epoch = eventEpoch
	activeEvent = name
	eventEndsAt = os.clock() + Config.EVENT_DURATION_SECONDS
	-- v2.5: a non-multiplier event ends any running multiplier bonus.
	if name ~= "GoldenHour" and name ~= "DoubleCashHour" and multOwner ~= "" then
		DataService.setEventMultiplier(1)
		multOwner = ""
	end

	if name == "GoldenHour" then
		EventService.applyTimedMultiplier(2, name, Config.EVENT_DURATION_SECONDS)
		announceAll("GOLDEN HOUR! All income DOUBLED for 60 seconds!")
	elseif name == "BrainrotRain" then
		ConveyorService.rainRares(5)
		announceAll("BRAINROT RAIN! Five Epic-or-better brainrots hit the conveyor!")
	elseif name == "Tsunami" then
		announceAll("TSUNAMI! A wave is sweeping the map — DASH HOME to your base!")
		EventService.sweepTsunami()
	elseif name == "MeteorShower" then
		announceAll("METEOR SHOWER! Meteors are crashing on random bases — free brainrots!")
		EventService.meteorShower()
	elseif name == "DoubleCashHour" then
		EventService.applyTimedMultiplier(2, name, Config.EVENT_DURATION_SECONDS)
		announceAll("DOUBLE CASH HOUR! All income DOUBLED for 60 seconds — stack it with pets!")
	elseif name == "SlimeInvasion" then
		announceAll("SLIME INVASION! Green slimes are loose on the plaza — touch one for +$750!")
		EventService.slimeInvasion()
	elseif name == "BossRaid" then
		-- v3: the raid event asks RaidService to spawn a boss; when
		-- one is already fighting, the event is a dud and the banner
		-- says so instead of spawning a second boss.
		if RaidService and RaidService.spawnBoss() then
			announceAll("BOSS RAID EVENT! A boss appeared on the raid pad — press F near it to fight!")
		else
			announceAll("BOSS RAID EVENT! A boss is already fighting on the raid pad — join in!")
		end
	end
end

-- v2.5 Meteor Shower: eight meteors fall over twenty seconds. Each one
-- picks a random base with a free pedestal (owned bases first), crashes
-- in a flash of light, and leaves a free wild brainrot on that base for
-- its owner. An unowned or full base sends the brainrot to the conveyor
-- instead, so nothing is ever wasted.
function EventService.meteorShower()
	local epoch = eventEpoch
	local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
	task.spawn(function()
		for i = 1, 8 do
			if epoch ~= eventEpoch then break end
			local plotIndex = BaseService.randomPlotWithFreePedestal()
			local center = plotIndex > 0 and BaseService.plotCenter(plotIndex) or Vector3.new(math.random(-60, 60), 1, math.random(-40, 40))
			-- The meteor: a glowing rock that drops from the sky.
			local meteor = Instance.new("Part")
			meteor.Name = "Meteor" .. tostring(i)
			meteor.Shape = Enum.PartType.Ball
			meteor.Size = Vector3.new(4, 4, 4)
			meteor.Color = Color3.fromRGB(255, 120, 40)
			meteor.Material = Enum.Material.Neon
			meteor.Anchored = true
			meteor.CanCollide = false
			meteor.Position = center + Vector3.new(0, 60, 0)
			meteor.Parent = Workspace
			for step = 1, 20 do
				if not meteor.Parent then
					break
				end
				meteor.Position = center + Vector3.new(0, 60 - step * 3, 0)
				task.wait(0.05)
			end
			if meteor.Parent then
				meteor:Destroy()
			end
			-- The crash leaves a wild brainrot behind for the base owner.
			local def = BrainrotData.rollDef()
			local model = BrainrotFactory.createBrainrot(def, BrainrotData.rollMutation())
			model:SetAttribute("State", "Owned")
			if plotIndex > 0 then
				local owner = BaseService.ownerOf(plotIndex)
				if owner then
					local ownerState = DataService.get(owner)
					model:SetAttribute("Owner", owner.Name)
					if ownerState then
						DataService.addOwned(ownerState, model)
					end
					model.Parent = Workspace
					BaseService.placeOnPlot(plotIndex, model, WorldBuilder)
					announceAll("A meteor crashed on Plot " .. tostring(plotIndex) .. " — " .. BrainrotData.displayName(def, model:GetAttribute("MutationIndex") or 1) .. " for " .. owner.Name .. "!")
				else
					model:SetAttribute("State", "Belt")
					model:SetAttribute("Price", BrainrotData.costOf(def))
					model:PivotTo(CFrame.new(Config.CONVEYOR_MIN_X, 3, Config.CONVEYOR_Z))
					model.Parent = Workspace
				end
			else
				model:SetAttribute("State", "Belt")
				model:SetAttribute("Price", BrainrotData.costOf(def))
				model:PivotTo(CFrame.new(Config.CONVEYOR_MIN_X, 3, Config.CONVEYOR_Z))
				model.Parent = Workspace
			end
			if plotIndex == 0 then
				announceAll("A meteor crashed on an empty base — its brainrot rolled onto the conveyor!")
			end
			task.wait(1.5)
		end
	end)
end

-- v2.5 Slime Invasion: six fat green slimes wobble around the plaza for
-- the event's duration. Touching one pops it for +$750 cash — once per
-- slime, first touch wins — then it melts away. A slime nobody pops
-- despawns when the event ends.
function EventService.slimeInvasion()
	local epoch = eventEpoch
	local slimes = {}
	for i = 1, 6 do
		local slime = Instance.new("Part")
		slime.Name = "Slime" .. tostring(i)
		slime.Shape = Enum.PartType.Ball
		slime.Size = Vector3.new(3.5, 3, 3.5)
		slime.Color = Color3.fromRGB(120, 255, 120)
		slime.Material = Enum.Material.Neon
		slime.Transparency = 0.15
		slime.Anchored = true
		slime.CanCollide = false
		slime.Position = Vector3.new(math.random(-50, 50), 2.5, math.random(-40, 40))
		slime:SetAttribute("Popped", false)
		slime.Parent = Workspace
		table.insert(slimes, slime)
		-- One pop per slime: the first player to touch it takes the cash.
		slime.Touched:Connect(function(hit)
			if slime:GetAttribute("Popped") then
				return
			end
			local character = hit.Parent
			local player = character and game:GetService("Players"):GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local state = DataService.get(player)
			if not state then
				return
			end
			slime:SetAttribute("Popped", true)
			DataService.addCash(state, 750)
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local announce = remotes and remotes:FindFirstChild("Announce")
			if announce then
				announce:FireClient(player, "SLIME POPPED! +$750!")
			end
			slime:Destroy()
		end)
	end
	-- Slimes wobble to a new spot every few seconds, then melt away.
	task.spawn(function()
		local waited = 0
		while waited < Config.EVENT_DURATION_SECONDS do
			if epoch ~= eventEpoch then break end
			task.wait(4)
			waited += 4
			for _, slime in ipairs(slimes) do
				if slime.Parent then
					slime.Position = Vector3.new(math.random(-50, 50), 2.5, math.random(-40, 40))
				end
			end
		end
		for _, slime in ipairs(slimes) do
			if slime.Parent then
				slime:Destroy()
			end
		end
	end)
end

-- The wave crosses the map west to east over 12 seconds. Players caught
-- outside their own base are knocked down and drop what they carry; the
-- conveyor's brainrots are washed away.
function EventService.sweepTsunami()
	local epoch = eventEpoch
	local wave = WorldBuilder.Wave
	if not wave then
		return
	end
	local startX = -130
	local endX = 130
	local steps = 60
	local hitPlayers = {}
	task.spawn(function()
		for i = 0, steps do
			if epoch ~= eventEpoch then break end
			local t = i / steps
			wave.Position = Vector3.new(startX + (endX - startX) * t, 13, 0)
			-- Anyone the wave passes over, off their own base, goes down.
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				if not hitPlayers[player] then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local state = DataService.get(player)
					if root and humanoid and state then
						local waveX = wave.Position.X
						if math.abs(root.Position.X - waveX) < 6 then
							if not BaseService.isOnPlot(root.Position, state.PlotIndex) then
								hitPlayers[player] = true
								humanoid.Sit = true
								root.AssemblyLinearVelocity = Vector3.new(30, 15, 0)
								if state.Carrying then
									local StealService = require(script.Parent:WaitForChild("StealService"))
									StealService.dropCarried(player, state)
								end
								local remotes = ReplicatedStorage:FindFirstChild("Remotes")
								local announce = remotes and remotes:FindFirstChild("Announce")
								if announce then
									announce:FireClient(player, "The tsunami caught you! Get back to your base!")
								end
							end
						end
					end
				end
			end
			task.wait(Config.TSUNAMI_SWEEP_SECONDS / steps)
		end
		-- The wave washes the conveyor clean, then parks off-map again.
		if epoch == eventEpoch then
			ConveyorService.clearBelt()
		end
		wave.Position = Vector3.new(-130, 13, 0)
	end)
end

return EventService
