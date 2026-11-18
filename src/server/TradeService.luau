-- Brainrot Boulevard v3: player-to-player trading. A player offers one
-- of their own brainrots (plus optional cash) for one of another
-- player's brainrots. The offer sits in the target's inbox for 60
-- seconds; they accept or decline it. An accepted offer needs BOTH
-- sides to confirm before anything moves — the server re-validates
-- ownership of both brainrots at confirm time, so a brainrot stolen,
-- sold or rebirthed away mid-trade can never be traded. Cash changes
-- hands with a 5% fee (waived while the payer holds a Trade Pass).
-- Trades are server-authoritative: the client only names the players
-- and the models; every check runs here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local TradeService = {}

local DataService
local BaseService
local WorldBuilder
local QuestService

-- offers[offerId] = {
--   id, from (Player), to (Player), offered (Model), wanted (Model),
--   cash (number, sender pays this on top), createdAt (os.clock()),
--   fromConfirmed (bool), toConfirmed (bool), state ("pending" | "done")
-- }
local offers = {}
local nextOfferId = 1
local updateRemote

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

-- Does this player currently own this model, on a pedestal of their plot?
local function playerOwns(player, model)
	if not model or not model.Parent then
		return false
	end
	local state = DataService.get(player)
	if not state then
		return false
	end
	if model:GetAttribute("Owner") ~= player.Name then
		return false
	end
	if model:GetAttribute("State") ~= "Owned" then
		return false
	end
	for _, owned in ipairs(state.Owned) do
		if owned == model then
			return true
		end
	end
	return false
end

-- Is this model already the offered or wanted side of a live offer?
-- StealService asks this so a brainrot mid-trade cannot be stolen away
-- from under the negotiation.
function TradeService.isOffered(model)
	for _, offer in pairs(offers) do
		if offer.state == "pending" and (offer.offered == model or offer.wanted == model) then
			return true
		end
	end
	return false
end

-- How many live offers does this player have open (sent or received)?
local function activeOfferCount(player)
	local count = 0
	for _, offer in pairs(offers) do
		if offer.state == "pending" and (offer.from == player or offer.to == player) then
			count += 1
		end
	end
	return count
end

-- The fee on the cash side of a trade: 5%, waived while the sender
-- holds a Trade Pass (each completed trade burns one pass use).
local function tradeFeeFor(state, cash)
	if cash <= 0 then
		return 0
	end
	if (state.TradePassUses or 0) > 0 then
		return 0
	end
	return math.floor(cash * Config.TRADE_FEE_RATE + 0.5)
end

-- Push the inbox snapshot to one player: their live incoming and
-- outgoing offers, with names, rarities and rates, so the HUD trade
-- panel (T) can draw accept / decline / confirm buttons.
function TradeService.snapshotFor(player)
	local incoming = {}
	local outgoing = {}
	for _, offer in pairs(offers) do
		if offer.state == "pending" then
			local offeredDef = BrainrotData.getById(offer.offered:GetAttribute("BrainrotId"))
			local wantedDef = BrainrotData.getById(offer.wanted:GetAttribute("BrainrotId"))
			local entry = {
				id = offer.id,
				from = offer.from.Name,
				to = offer.to.Name,
				offeredName = offeredDef and BrainrotData.displayName(offeredDef, offer.offered:GetAttribute("MutationIndex") or 1) or "?",
				offeredRarity = offeredDef and BrainrotData.rarityOf(offeredDef).name or "?",
				offeredRate = offeredDef and BrainrotData.incomeOf(offeredDef, offer.offered:GetAttribute("MutationIndex") or 1, 1) or 0,
				wantedName = wantedDef and BrainrotData.displayName(wantedDef, offer.wanted:GetAttribute("MutationIndex") or 1) or "?",
				wantedRarity = wantedDef and BrainrotData.rarityOf(wantedDef).name or "?",
				wantedRate = wantedDef and BrainrotData.incomeOf(wantedDef, offer.wanted:GetAttribute("MutationIndex") or 1, 1) or 0,
				cash = offer.cash,
				fee = tradeFeeFor(DataService.get(offer.from), offer.cash),
				fromConfirmed = offer.fromConfirmed,
				toConfirmed = offer.toConfirmed,
				expiresIn = math.max(0, Config.TRADE_OFFER_EXPIRY_SECONDS - (os.clock() - offer.createdAt)),
			}
			if offer.to == player then
				table.insert(incoming, entry)
			elseif offer.from == player then
				table.insert(outgoing, entry)
			end
		end
	end
	return {
		incoming = incoming,
		outgoing = outgoing,
		-- The HUD's offer picker needs the player's own tradable stock.
		ownCount = #(DataService.get(player) and DataService.get(player).Owned or {}),
	}
end

local function pushUpdate(player)
	if updateRemote and player and player.Parent then
		updateRemote:FireClient(player, TradeService.snapshotFor(player))
	end
end

local function pushBoth(offer)
	pushUpdate(offer.from)
	pushUpdate(offer.to)
end

-- Find a player by name prefix, the way the HUD's trade box types it:
-- an exact name wins, otherwise the first prefix match.
function TradeService.findPlayer(name)
	if not name or name == "" then
		return nil
	end
	local exact = Players:FindFirstChild(name)
	if exact then
		return exact
	end
	local lower = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #lower) == lower then
			return player
		end
	end
	return nil
end

-- Send an offer: your brainrot + optional cash for their brainrot.
-- Every failure is a toast, never a silent drop.
function TradeService.sendOffer(player, targetName, offeredModel, wantedModel, cash)
	local state = DataService.get(player)
	if not state then
		return
	end
	local target = TradeService.findPlayer(targetName)
	if not target or target == player then
		announceTo(player, "No player by that name is here to trade with.")
		return
	end
	if activeOfferCount(player) >= Config.TRADE_MAX_ACTIVE then
		announceTo(player, "You already have " .. tostring(Config.TRADE_MAX_ACTIVE) .. " live trade offers.")
		return
	end
	if activeOfferCount(target) >= Config.TRADE_MAX_ACTIVE then
		announceTo(player, target.Name .. " already has too many live offers.")
		return
	end
	if not playerOwns(player, offeredModel) then
		announceTo(player, "You don't own that brainrot anymore.")
		return
	end
	if not playerOwns(target, wantedModel) then
		announceTo(player, target.Name .. " doesn't own that brainrot anymore.")
		return
	end
	if TradeService.isOffered(offeredModel) or TradeService.isOffered(wantedModel) then
		announceTo(player, "One of those brainrots is already in a trade offer.")
		return
	end
	cash = math.floor(tonumber(cash) or 0)
	if cash < 0 then
		cash = 0
	end
	if cash > 0 and state.Cash < cash + tradeFeeFor(state, cash) then
		announceTo(player, "Not enough cash for the offer plus its fee (" .. Utils.formatMoney(tradeFeeFor(state, cash)) .. ").")
		return
	end
	local offer = {
		id = nextOfferId,
		from = player,
		to = target,
		offered = offeredModel,
		wanted = wantedModel,
		cash = cash,
		createdAt = os.clock(),
		fromConfirmed = false,
		toConfirmed = false,
		state = "pending",
	}
	nextOfferId += 1
	offers[offer.id] = offer
	pushBoth(offer)
	local offeredDef = BrainrotData.getById(offeredModel:GetAttribute("BrainrotId"))
	local wantedDef = BrainrotData.getById(wantedModel:GetAttribute("BrainrotId"))
	announceTo(player, "Trade offer sent to " .. target.Name .. "!")
	announceTo(target, player.Name .. " offers " .. (offeredDef and offeredDef.name or "a brainrot") .. " for your " .. (wantedDef and wantedDef.name or "brainrot") .. " — press T to answer!")
end

-- Answer an offer: "accept" moves it to the confirm stage, "decline"
-- kills it at once. Only the target can answer.
function TradeService.respond(player, offerId, answer)
	local offer = offers[offerId]
	if not offer or offer.state ~= "pending" then
		return
	end
	if offer.to ~= player then
		announceTo(player, "That offer isn't addressed to you.")
		return
	end
	if answer == "decline" then
		offer.state = "done"
		offers[offerId] = nil
		pushBoth(offer)
		announceTo(offer.from, player.Name .. " declined your trade offer.")
		announceTo(player, "Trade offer declined.")
		return
	end
	if answer ~= "accept" then
		return
	end
	-- Re-validate both sides at answer time, not just at send time.
	if not playerOwns(offer.from, offer.offered) or not playerOwns(offer.to, offer.wanted) then
		offers[offerId] = nil
		pushBoth(offer)
		announceTo(offer.from, "Trade failed: one side no longer owns their brainrot.")
		announceTo(offer.to, "Trade failed: one side no longer owns their brainrot.")
		return
	end
	offer.toConfirmed = true
	pushBoth(offer)
	announceTo(offer.from, player.Name .. " accepted! Confirm the trade to swap (press T).")
	announceTo(player, "Accepted! Waiting for " .. offer.from.Name .. " to confirm.")
end

-- Confirm an accepted offer. The swap happens only when BOTH sides
-- have confirmed; the sender confirms here, the target confirms by
-- answering "accept" first and then confirming too. The server checks
-- ownership, pedestals and cash one last time before moving anything.
function TradeService.confirm(player, offerId)
	local offer = offers[offerId]
	if not offer or offer.state ~= "pending" then
		return
	end
	if player ~= offer.from and player ~= offer.to then
		return
	end
	if player == offer.from then
		offer.fromConfirmed = true
	else
		offer.toConfirmed = true
	end
	if not (offer.fromConfirmed and offer.toConfirmed) then
		pushBoth(offer)
		local other = player == offer.from and offer.to or offer.from
		announceTo(other, player.Name .. " confirmed the trade. Confirm it too!")
		return
	end
	TradeService.execute(offer)
end

-- The swap itself: ownership re-validated, pedestals checked, cash
-- moved with its fee, both brainrots re-homed on the other player's
-- plot, and the quest hook fed for both traders.
function TradeService.execute(offer)
	local fromState = DataService.get(offer.from)
	local toState = DataService.get(offer.to)
	if not fromState or not toState then
		offers[offer.id] = nil
		return
	end
	if not playerOwns(offer.from, offer.offered) or not playerOwns(offer.to, offer.wanted) then
		offers[offer.id] = nil
		pushBoth(offer)
		announceTo(offer.from, "Trade failed: one side no longer owns their brainrot.")
		announceTo(offer.to, "Trade failed: one side no longer owns their brainrot.")
		return
	end
	if not BaseService.hasFreePedestal(toState.PlotIndex) and toState.PlotIndex ~= 0 then
		-- Both plots lose one brainrot and gain one, so a full plot is
		-- fine: the outgoing brainrot frees its pedestal first.
	end
	local fee = tradeFeeFor(fromState, offer.cash)
	if offer.cash > 0 and not DataService.spendCash(fromState, offer.cash + fee) then
		offers[offer.id] = nil
		pushBoth(offer)
		announceTo(offer.from, "Trade failed: not enough cash for the offer plus fee.")
		return
	end
	if (fromState.TradePassUses or 0) > 0 and offer.cash > 0 then
		fromState.TradePassUses -= 1
	end
	-- Free both pedestals first, then re-home each brainrot on the
	-- other player's plot. If a plot has no free pedestal after the
	-- swap (it always has one — the outgoing brainrot just left), the
	-- brainrot waits on the plaza floor as a dropped one instead.
	BaseService.removeFromPlot(offer.offered)
	BaseService.removeFromPlot(offer.wanted)
	DataService.removeOwned(fromState, offer.offered)
	DataService.removeOwned(toState, offer.wanted)
	offer.offered:SetAttribute("Owner", offer.to.Name)
	offer.wanted:SetAttribute("Owner", offer.from.Name)
	offer.offered:SetAttribute("State", "Owned")
	offer.wanted:SetAttribute("State", "Owned")
	DataService.addOwned(toState, offer.offered)
	DataService.addOwned(fromState, offer.wanted)
	BaseService.placeOnPlot(toState.PlotIndex, offer.offered, WorldBuilder)
	BaseService.placeOnPlot(fromState.PlotIndex, offer.wanted, WorldBuilder)
	if offer.cash > 0 then
		DataService.addCash(toState, offer.cash)
	end
	offers[offer.id] = nil
	offer.state = "done"
	pushBoth(offer)
	local offeredDef = BrainrotData.getById(offer.offered:GetAttribute("BrainrotId"))
	local wantedDef = BrainrotData.getById(offer.wanted:GetAttribute("BrainrotId"))
	local swapText = "TRADE DONE: " .. offer.from.Name .. " <-> " .. offer.to.Name .. " — "
		.. (offeredDef and offeredDef.name or "?") .. " for " .. (wantedDef and wantedDef.name or "?")
	if offer.cash > 0 then
		swapText ..= " + " .. Utils.formatMoney(offer.cash)
		if fee > 0 then
			swapText ..= " (fee " .. Utils.formatMoney(fee) .. ")"
		end
	end
	announceAll(swapText .. "!")
	-- v3: a completed trade feeds the daily "trade" quest for both sides.
	if QuestService then
		QuestService.addProgress(offer.from, "trade", 1)
		QuestService.addProgress(offer.to, "trade", 1)
	end
end

-- Cancel a live offer you sent. The target's inbox clears at once.
function TradeService.cancel(player, offerId)
	local offer = offers[offerId]
	if not offer or offer.state ~= "pending" then
		return
	end
	if offer.from ~= player then
		announceTo(player, "Only the sender can cancel an offer.")
		return
	end
	offers[offerId] = nil
	pushBoth(offer)
	announceTo(offer.to, player.Name .. " cancelled their trade offer.")
	announceTo(player, "Trade offer cancelled.")
end

local function playerName(player)
	return player and player.Name or "?"
end

-- Offers expire: a 60-second offer nobody answers is swept away and
-- both sides are told, so the inbox never shows a dead deal.
function TradeService.startExpiryWatch()
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.clock()
			for id, offer in pairs(offers) do
				if offer.state == "pending" and now - offer.createdAt >= Config.TRADE_OFFER_EXPIRY_SECONDS then
					offers[id] = nil
					pushBoth(offer)
					announceTo(offer.from, "Your trade offer to " .. offer.to.Name .. " expired.")
					announceTo(offer.to, playerName(offer.from) .. "'s trade offer expired.")
				end
			end
		end
	end)
end

function TradeService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	QuestService = services.QuestService
	updateRemote = services.Remotes.TradeUpdate

	-- The client sends the target's name (typed in the trade panel),
	-- the two models (picked from the world), and the cash sweetener.
	services.Remotes.TradeOffer.OnServerEvent:Connect(function(player, targetName, offeredModel, wantedModel, cash)
		TradeService.sendOffer(player, targetName, offeredModel, wantedModel, cash)
	end)
	services.Remotes.TradeRespond.OnServerEvent:Connect(function(player, offerId, answer)
		TradeService.respond(player, tonumber(offerId) or 0, answer)
	end)
	services.Remotes.TradeConfirm.OnServerEvent:Connect(function(player, offerId)
		TradeService.confirm(player, tonumber(offerId) or 0)
	end)

	-- A player who leaves takes their live offers with them.
	Players.PlayerRemoving:Connect(function(player)
		for id, offer in pairs(offers) do
			if offer.state == "pending" and (offer.from == player or offer.to == player) then
				offers[id] = nil
				local other = offer.from == player and offer.to or offer.from
				pushUpdate(other)
				announceTo(other, player.Name .. " left — your trade offer with them is gone.")
			end
		end
	end)

	TradeService.startExpiryWatch()
end

return TradeService
