-- Brainrot Boulevard: the conveyor. Brainrots spawn at the west gate, walk
-- the belt east, and despawn at the far end. A player buys one by standing
-- close and pressing E; the brainrot then walks to their base and takes a
-- pedestal. Buying is server-validated: cash, range, and a free pedestal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local ConveyorService = {}

local belt = {} -- brainrot Models currently walking the belt
local DataService
local BaseService
local WorldBuilder
local BrainrotFactory
local buyRemote
-- v2.5: QuestService is optional here (it registers after this service in
-- some boot orders), so the hook is guarded — a buy with no quest service
-- still buys, it just feeds no quest.
local QuestService
-- v3: every 10th spawn is a Sky Express — a brainrot that walks the
-- belt twice as fast, flagged so the client can show it streaking.
-- It costs the same as any other brainrot; the speed is the thrill.
local spawnCounter = 0
local EXPRESS_EVERY = 10
local EXPRESS_SPEED_MULT = 2

local function spawnOne()
	if #belt >= Config.CONVEYOR_MAX_BRAINROTS then
		return
	end
	spawnCounter += 1
	local def = BrainrotData.rollDef()
	local mutationIndex = BrainrotData.rollMutation()
	local model = BrainrotFactory.createBrainrot(def, mutationIndex)
	model:SetAttribute("Price", BrainrotData.costOf(def))
	model:SetAttribute("State", "Belt")
	-- v3: every 10th spawn is a Sky Express — twice the belt speed.
	if spawnCounter % EXPRESS_EVERY == 0 then
		model:SetAttribute("Express", true)
		model:SetAttribute("ExpressSpeed", EXPRESS_SPEED_MULT)
	end
	model:PivotTo(CFrame.new(Config.CONVEYOR_MIN_X, 3, Config.CONVEYOR_Z))
	model.Parent = Workspace
	table.insert(belt, model)
end

function ConveyorService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	BrainrotFactory = services.BrainrotFactory
	QuestService = services.QuestService
	buyRemote = services.Remotes.BuyBrainrot

	-- The belt walk: every frame, each brainrot steps east; past the end
	-- it despawns. Anchored while walking so physics never tips it over.
	-- v3: Sky Express brainrots step twice as fast.
	RunService.Heartbeat:Connect(function(dt)
		for i = #belt, 1, -1 do
			local model = belt[i]
			if not model.Parent then
				table.remove(belt, i)
			else
				local speed = Config.CONVEYOR_SPEED
				if model:GetAttribute("Express") then
					speed *= EXPRESS_SPEED_MULT
				end
				local pivot = model:GetPivot()
				local nextX = pivot.Position.X + speed * dt
				if nextX >= Config.CONVEYOR_MAX_X then
					model:Destroy()
					table.remove(belt, i)
				else
					model:PivotTo(CFrame.new(nextX, 3, Config.CONVEYOR_Z))
				end
			end
		end
	end)

	-- Steady spawn of fresh brainrots.
	task.spawn(function()
		while true do
			task.wait(Config.CONVEYOR_SPAWN_SECONDS)
			spawnOne()
		end
	end)

	buyRemote.OnServerEvent:Connect(function(player, model)
		ConveyorService.tryBuy(player, model)
	end)
end

-- The nearest belt brainrot to a position, for the client's prompt.
function ConveyorService.nearestTo(position, maxDist)
	local best = nil
	local bestDist = maxDist
	for _, model in ipairs(belt) do
		if model.Parent then
			local d = (model:GetPivot().Position - position).Magnitude
			if d < bestDist then
				bestDist = d
				best = model
			end
		end
	end
	return best, bestDist
end

function ConveyorService.tryBuy(player, model)
	local state = DataService.get(player)
	if not state or not model or not model.Parent then
		return
	end
	if model:GetAttribute("State") ~= "Belt" then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if (model:GetPivot().Position - root.Position).Magnitude > Config.BUY_RANGE_STUDS then
		return
	end
	local plotIndex = state.PlotIndex
	if plotIndex == 0 or not BaseService.hasFreePedestal(plotIndex) then
		return
	end
	local price = model:GetAttribute("Price") or 0
	if not DataService.spendCash(state, price) then
		return
	end

	-- Leave the belt, walk to the plot, take a pedestal.
	for i, m in ipairs(belt) do
		if m == model then
			table.remove(belt, i)
			break
		end
	end
	model:SetAttribute("State", "Owned")
	model:SetAttribute("Owner", player.Name)
	DataService.addOwned(state, model)
	state.Bought += 1 -- v2: feeds the leaderboard's bought count.
	-- v2.5: every purchase feeds the daily "buy" quest.
	if QuestService then
		QuestService.addProgress(player, "buy", 1)
	end
	BaseService.placeOnPlot(plotIndex, model, WorldBuilder)

	local def = BrainrotData.getById(model:GetAttribute("BrainrotId"))
	if def then
		servicesAnnounce(state, player, "Bought " .. BrainrotData.displayName(def, model:GetAttribute("MutationIndex") or 1) .. " for " .. Utils.formatMoney(price) .. "!")
	end
end

function servicesAnnounce(state, player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

-- v3: spawn one brainrot straight onto the belt for a reward — the
-- raid's top contributor sometimes gets a belt drop instead of a plot
-- drop, and this is the hook RaidService would call for it. The
-- brainrot is flagged as a reward so the client can spot it.
function ConveyorService.spawnReward(def, mutationIndex)
	if #belt >= Config.CONVEYOR_MAX_BRAINROTS then
		return nil
	end
	local model = BrainrotFactory.createBrainrot(def, mutationIndex or BrainrotData.rollMutation())
	model:SetAttribute("Price", BrainrotData.costOf(def))
	model:SetAttribute("State", "Belt")
	model:SetAttribute("Reward", true)
	model:PivotTo(CFrame.new(Config.CONVEYOR_MIN_X, 3, Config.CONVEYOR_Z))
	model.Parent = Workspace
	table.insert(belt, model)
	return model
end

-- For events: wash every belt brainrot away (the tsunami takes them).
function ConveyorService.clearBelt()
	for _, model in ipairs(belt) do
		if model.Parent then
			model:Destroy()
		end
	end
	table.clear(belt)
end

-- For events: drop extra rare brainrots straight onto the belt.
function ConveyorService.rainRares(count)
	for _ = 1, count do
		local def = BrainrotData.rollDef()
		-- Rain only brings Epic or better.
		while def.rarity < 3 do
			def = BrainrotData.rollDef()
		end
		local model = BrainrotFactory.createBrainrot(def, BrainrotData.rollMutation())
		model:SetAttribute("Price", BrainrotData.costOf(def))
		model:SetAttribute("State", "Belt")
		model:PivotTo(CFrame.new(Config.CONVEYOR_MIN_X + math.random(0, 30), 3, Config.CONVEYOR_Z))
		model.Parent = Workspace
		table.insert(belt, model)
	end
end

return ConveyorService
