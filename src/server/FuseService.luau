-- Brainrot Boulevard v7: the Fuse Machine. Fuse 3 same-rarity brainrots
-- into 1 of the next rarity at the Fuse Machine (press G near the pad).
-- The three lowest earners of the lowest fusable rarity go in; one
-- random brainrot of the rarity above comes out with a fresh mutation
-- roll. The machine sits east of spawn, and the server re-checks the
-- cooldown, the distance and the stock before anything is consumed —
-- the client only asks, the server decides.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local FuseService = {}

local DataService
local BaseService
local WorldBuilder
local BrainrotFactory
local Remotes

local lastFuse = {} -- [Player] = os.clock() of last fuse (cooldown)

local function announceTo(player, text)
	if Remotes and Remotes.Announce then
		Remotes.Announce:FireClient(player, text)
	end
end

function FuseService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	BrainrotFactory = services.BrainrotFactory
	Remotes = services.Remotes

	services.Remotes.FuseBrainrots.OnServerEvent:Connect(function(player)
		FuseService.fuseLowest(player)
	end)
end

-- Every model this player owns whose character sits at one rarity.
-- The def comes from the model's BrainrotId attribute, the same way
-- DataService.baseIncome reads it, so a model with no def is skipped.
function FuseService.ownedOfRarity(state, rarityIndex)
	local owned = {}
	for _, model in ipairs(state.Owned) do
		local def = BrainrotData.getById(model:GetAttribute("BrainrotId"))
		if def and def.rarity == rarityIndex then
			table.insert(owned, model)
		end
	end
	return owned
end

-- The lowest rarity that can still fuse up: 1..#RARITIES-1 with at
-- least FUSE_COUNT owned, else 0. The top rarity never fuses — there
-- is nothing above OG to fuse into.
function FuseService.lowestFusableRarity(state)
	for rarityIndex = 1, #BrainrotData.RARITIES - 1 do
		if #FuseService.ownedOfRarity(state, rarityIndex) >= Config.FUSE_COUNT then
			return rarityIndex
		end
	end
	return 0
end

-- Fuse one rarity up: sort the candidates by income, take the
-- FUSE_COUNT lowest earners, remove them from the plot and the owned
-- list, then roll one brainrot of the rarity above and place it.
function FuseService.fuseRarity(player, rarityIndex)
	local state = DataService.get(player)
	if not state then
		return
	end
	if rarityIndex < 1 or rarityIndex >= #BrainrotData.RARITIES then
		announceTo(player, "Nothing above OG to fuse into!")
		return
	end
	local candidates = FuseService.ownedOfRarity(state, rarityIndex)
	if #candidates < Config.FUSE_COUNT then
		announceTo(player, "You need 3 brainrots of the same rarity to fuse!")
		return
	end
	local rebirthMult = DataService.rebirthMultiplier(state)
	table.sort(candidates, function(a, b)
		local defA = BrainrotData.getById(a:GetAttribute("BrainrotId"))
		local defB = BrainrotData.getById(b:GetAttribute("BrainrotId"))
		local rateA = defA and BrainrotData.incomeOf(defA, a:GetAttribute("MutationIndex") or 1, rebirthMult) or 0
		local rateB = defB and BrainrotData.incomeOf(defB, b:GetAttribute("MutationIndex") or 1, rebirthMult) or 0
		return rateA < rateB
	end)
	for i = 1, Config.FUSE_COUNT do
		local model = candidates[i]
		BaseService.removeFromPlot(model)
		DataService.removeOwned(state, model)
		model:Destroy()
	end
	local def2 = BrainrotData.rollDefOfRarity(rarityIndex + 1)
	local model2 = BrainrotFactory.createBrainrot(def2, BrainrotData.rollMutation())
	model2:SetAttribute("State", "Owned")
	model2:SetAttribute("Owner", player.Name)
	model2.Parent = Workspace
	DataService.addOwned(state, model2)
	BaseService.placeOnPlot(state.PlotIndex, model2, WorldBuilder)
	state.Fuses += 1
	local rarityName = BrainrotData.RARITIES[rarityIndex].name
	local displayName = BrainrotData.displayName(def2, model2:GetAttribute("MutationIndex") or 1)
	announceTo(player, "Fused 3 " .. rarityName .. " brainrots into " .. displayName .. "!")
end

-- The G-key entry point: cooldown first, then the walk to the machine,
-- then the lowest fusable rarity. A player with only a top-rarity
-- triple gets the dedicated line; anyone else short of a triple gets
-- the need-3 line, so the toast always says what to do next.
function FuseService.fuseLowest(player)
	local state = DataService.get(player)
	if not state then
		return
	end
	local now = os.clock()
	if lastFuse[player] and now - lastFuse[player] < Config.FUSE_COOLDOWN_SECONDS then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - Config.FUSE_MACHINE_POSITION).Magnitude > Config.FUSE_RANGE_STUDS then
		announceTo(player, "Walk to the Fuse Machine (east of spawn) to fuse!")
		return
	end
	local rarityIndex = FuseService.lowestFusableRarity(state)
	if rarityIndex == 0 then
		if #FuseService.ownedOfRarity(state, #BrainrotData.RARITIES) >= Config.FUSE_COUNT then
			announceTo(player, "Nothing above OG to fuse into!")
		else
			announceTo(player, "You need 3 brainrots of the same rarity to fuse!")
		end
		return
	end
	lastFuse[player] = now
	FuseService.fuseRarity(player, rarityIndex)
end

return FuseService
