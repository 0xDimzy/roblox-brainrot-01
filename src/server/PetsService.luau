-- Brainrot Boulevard v2.5: pets and companions. Six purchasable pets that
-- follow the player (rendered by the client, see Game.client.luau) and
-- grant a permanent income multiplier while owned. Everything money-side
-- is server-authoritative: the client only ever displays what the server
-- sends, and a buy or equip is validated here against cash and ownership.
-- Pets survive a rebirth — they are companions, not base stock — and each
-- pet owned at rebirth time adds +5% to the permanent rebirth pet bonus
-- (see RebirthService.petBonusFor). The multiplier itself lives in
-- DataService.petMultiplier so the income tick needs no cross-service call.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local PetsService = {}

local DataService

-- The six pets, in shop order. bonus is added to the income multiplier:
-- Milo's 0.10 means +10% income while owned. Costs are in-game cash only.
local PET_DEFS = Config.PETS

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
	if announce then
		announce:FireAllClients(text)
	end
end

-- The pet definition for an id, or nil when no pet has that id.
function PetsService.getDef(petId)
	return Config.petById(petId)
end

-- Does this player's state already own this pet?
function PetsService.ownsPet(state, petId)
	for _, ownedId in ipairs(state.Pets) do
		if ownedId == petId then
			return true
		end
	end
	return false
end

-- How many pets this player owns.
function PetsService.petCount(state)
	return #state.Pets
end

-- The active (following) pet's id, or "" when none is equipped.
function PetsService.activePetOf(state)
	return state.ActivePet or ""
end

-- The active pet's definition, or nil when none is equipped.
function PetsService.activePetDef(state)
	local activeId = PetsService.activePetOf(state)
	if activeId == "" then
		return nil
	end
	return Config.petById(activeId)
end

-- The income bonus from pets alone, as a multiplier: 1.00 with no pets,
-- 1.10 with Milo, and so on. DataService.petMultiplier is the authority
-- for the income tick; this is the same sum, for messages and the HUD.
function PetsService.bonusFor(state)
	local bonus = 0
	for _, petId in ipairs(state.Pets) do
		local def = Config.petById(petId)
		if def then
			bonus += def.bonus
		end
	end
	return bonus
end

-- v3: the raid damage bonus from pets — +5% boss damage per pet owned,
-- equipped or not. A full six-pet collection cheers the boss down 30%
-- faster. RaidService.damageFor reads this for every hit.
function PetsService.raidDamageBonus(state)
	return #state.Pets * 0.05
end

-- v3: the pet cheer line for the raid bar — "3 pets cheer you on
-- (+15% boss damage)" — so the player sees why their hits land hard.
function PetsService.raidCheerLine(state)
	local count = #state.Pets
	if count == 0 then
		return "No pets cheering — buy one (P) for +5% boss damage each!"
	end
	return tostring(count) .. " pet" .. (count == 1 and "" or "s") .. " cheer you on (+" .. tostring(math.floor(PetsService.raidDamageBonus(state) * 100 + 0.5)) .. "% boss damage)!"
end

-- The next pet this player does not own yet, cheapest first — the one the
-- quest board and the HUD suggest when the player asks what to buy next.
function PetsService.nextPetToBuy(state)
	for _, def in ipairs(PET_DEFS) do
		if not PetsService.ownsPet(state, def.id) then
			return def
		end
	end
	return nil
end

-- The cheapest pet the player can afford right now, or nil.
function PetsService.cheapestAffordable(state)
	for _, def in ipairs(PET_DEFS) do
		if not PetsService.ownsPet(state, def.id) and state.Cash >= def.cost then
			return def
		end
	end
	return nil
end

-- A one-line summary for toasts: "3 pets (+45% income)".
function PetsService.summaryLine(state)
	local count = PetsService.petCount(state)
	local bonus = PetsService.bonusFor(state)
	if count == 0 then
		return "No pets yet — press P to meet them!"
	end
	local pct = math.floor(bonus * 100 + 0.5)
	local word = "pet"
	if count ~= 1 then
		word = "pets"
	end
	return tostring(count) .. " " .. word .. " (+ " .. tostring(pct) .. "% income)"
end

-- Buy a pet with in-game cash. Validates: the pet exists, is not already
-- owned, and the player can afford it. The first pet bought auto-equips
-- so it starts following at once; later pets wait for an explicit equip.
function PetsService.buy(player, petId)
	local state = DataService.get(player)
	if not state then
		return
	end
	local def = Config.petById(petId)
	if not def then
		return
	end
	if PetsService.ownsPet(state, petId) then
		announceTo(player, "You already own " .. def.name .. "!")
		return
	end
	if not DataService.spendCash(state, def.cost) then
		announceTo(player, "Not enough cash for " .. def.name .. " (" .. Utils.formatMoney(def.cost) .. ")!")
		return
	end
	table.insert(state.Pets, petId)
	if state.ActivePet == "" then
		state.ActivePet = petId
		announceTo(player, def.name .. " joined you! +" .. tostring(math.floor(def.bonus * 100 + 0.5)) .. "% income, and it follows you everywhere!")
	else
		announceTo(player, "Bought " .. def.name .. "! +" .. tostring(math.floor(def.bonus * 100 + 0.5)) .. "% income. Press P and equip it to take it along.")
	end
	-- A full set of six is a boulevard event: everyone hears about it.
	if PetsService.petCount(state) == #PET_DEFS then
		announceAll(player.Name .. " collected ALL SIX pets! The boulevard has a new Pet Master!")
	end
end

-- Equip an owned pet: it becomes the one that follows the player. The
-- income bonus counts every owned pet, equipped or not — equipping only
-- picks the follower.
function PetsService.equip(player, petId)
	local state = DataService.get(player)
	if not state then
		return
	end
	local def = Config.petById(petId)
	if not def then
		return
	end
	if not PetsService.ownsPet(state, petId) then
		announceTo(player, "You do not own " .. def.name .. " yet — buy it first!")
		return
	end
	if state.ActivePet == petId then
		announceTo(player, def.name .. " is already following you!")
		return
	end
	state.ActivePet = petId
	announceTo(player, def.name .. " is now following you!")
end

-- Unequip the follower (the pet stays owned and keeps its income bonus).
function PetsService.unequip(player)
	local state = DataService.get(player)
	if not state then
		return
	end
	if state.ActivePet == "" then
		return
	end
	local def = Config.petById(state.ActivePet)
	state.ActivePet = ""
	if def then
		announceTo(player, def.name .. " went back to the pet park. Its bonus still counts!")
	end
end

-- The snapshot the HUD reads: owned ids, the active id, the multiplier
-- and a ready-made summary line. DataService calls this through the hook
-- PetsService.init registers, so the snapshot never goes stale.
function PetsService.snapshotFor(state)
	local ownedNames = {}
	for _, petId in ipairs(state.Pets) do
		local def = Config.petById(petId)
		if def then
			table.insert(ownedNames, def.name)
		end
	end
	return {
		owned = table.clone(state.Pets),
		ownedNames = ownedNames,
		active = state.ActivePet or "",
		multiplier = 1 + PetsService.bonusFor(state),
		count = #state.Pets,
		total = #PET_DEFS,
		summary = PetsService.summaryLine(state),
		-- v3: the raid cheer line, so the pets panel shows the boss
		-- damage bonus the player's collection earns them.
		raidBonus = PetsService.raidDamageBonus(state),
		raidCheer = PetsService.raidCheerLine(state),
	}
end

function PetsService.init(services)
	DataService = services.DataService

	-- The HUD reads pets through the DataService snapshot hook.
	DataService.setPetSnapshot(function(state)
		return PetsService.snapshotFor(state)
	end)

	services.Remotes.BuyPet.OnServerEvent:Connect(function(player, petId)
		PetsService.buy(player, petId)
	end)
	services.Remotes.EquipPet.OnServerEvent:Connect(function(player, petId)
		-- The client sends "" to unequip, a pet id to equip.
		if petId == "" then
			PetsService.unequip(player)
		else
			PetsService.equip(player, petId)
		end
	end)

	-- A leaving player's pets live in their state, which DataService
	-- drops; nothing in the world needs cleaning up, because the
	-- follower is rendered client-side from the snapshot.
	Players.PlayerRemoving:Connect(function(player)
		local state = DataService.get(player)
		if state then
			state.ActivePet = ""
		end
	end)
end

return PetsService
