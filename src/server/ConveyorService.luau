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

local function spawnOne()
	if #belt >= Config.CONVEYOR_MAX_BRAINROTS then
		return
	end
	local def = BrainrotData.rollDef()
	local mutationIndex = BrainrotData.rollMutation()
	local model = BrainrotFactory.createBrainrot(def, mutationIndex)
	model:SetAttribute("Price", BrainrotData.costOf(def))
	model:SetAttribute("State", "Belt")
	model:PivotTo(CFrame.new(Config.CONVEYOR_MIN_X, 3, Config.CONVEYOR_Z))
	model.Parent = Workspace
	table.insert(belt, model)
end

function ConveyorService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	BrainrotFactory = services.BrainrotFactory
	buyRemote = services.Remotes.BuyBrainrot

	-- The belt walk: every frame, each brainrot steps east; past the end
	-- it despawns. Anchored while walking so physics never tips it over.
	RunService.Heartbeat:Connect(function(dt)
		for i = #belt, 1, -1 do
			local model = belt[i]
			if not model.Parent then
				table.remove(belt, i)
			else
				local pivot = model:GetPivot()
				local nextX = pivot.Position.X + Config.CONVEYOR_SPEED * dt
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
