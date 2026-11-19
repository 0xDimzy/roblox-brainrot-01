-- Brainrot Boulevard: rebirth. Spend your lifetime earnings to start over
-- with twice the income forever. The cost grows with the square of
-- (rebirths + 1), so each rebirth is a real decision, not a button mash.
-- A rebirth clears your base and your cash, and crowns your character.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local RebirthService = {}

local DataService
local BaseService
local BrainrotFactory

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

-- v2.5: the rebirth pet bonus — +5% permanent income per pet owned at
-- rebirth time. Pets are companions, not base stock, so they survive the
-- rebirth that earns the bonus; the bonus stacks in state.PetBonus and
-- DataService multiplies income by (1 + PetBonus) forever after.
function RebirthService.petBonusFor(state)
	local petCount = #(state.Pets or {})
	return petCount * 0.05
end

-- v2.5: the milestone for this rebirth count, if one is defined in
-- Config.REBIRTH_MILESTONES (3 = Boulevard Regular, 5 = Legend,
-- 10 = Ohio Royalty), each with a one-off cash bonus.
function RebirthService.milestoneFor(rebirths)
	return Config.REBIRTH_MILESTONES[rebirths]
end

-- v3: the permanent raid damage bonus from rebirths — +5% boss damage
-- per rebirth, stacked in state.RaidBonus at rebirth time. A player
-- who has rebirthed 4 times hits the boss 20% harder forever.
-- RaidService.damageFor reads this for every hit.
function RebirthService.raidBonusFor(state)
	return state.RaidBonus or 0
end

-- v3: the rebirth raid line for the announcement — "+10% boss damage
-- forever" — so the rebirth toast shows the raid payoff too.
function RebirthService.raidBonusLine(state)
	local bonus = RebirthService.raidBonusFor(state)
	if bonus <= 0 then
		return ""
	end
	return " Boss damage +" .. tostring(math.floor(bonus * 100 + 0.5)) .. "% forever!"
end

function RebirthService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	BrainrotFactory = services.BrainrotFactory

	services.Remotes.Rebirth.OnServerEvent:Connect(function(player)
		RebirthService.tryRebirth(player)
	end)
end

function RebirthService.tryRebirth(player)
	local state = DataService.get(player)
	if not state then
		return
	end
	local cost = Config.rebirthCost(state.Rebirths)
	if state.TotalEarned < cost then
		announceTo(player, "Rebirth needs " .. tostring(cost) .. " total earned. You have " .. tostring(math.floor(state.TotalEarned)) .. ".")
		return
	end

	-- Clear the base: every owned brainrot goes.
	for _, model in ipairs(table.clone(state.Owned)) do
		BaseService.removeFromPlot(model)
		model:Destroy()
	end
	table.clear(state.Owned)
	state.LeaderBrainrots.Value = 0

	-- v2.5: pets survive the rebirth — and each one owned right now adds
	-- +5% permanent income to the rebirth pet bonus, stacking forever.
	local petBonus = RebirthService.petBonusFor(state)
	state.PetBonus = (state.PetBonus or 0) + petBonus

	-- v3: every rebirth also adds +5% permanent boss damage, stacked
	-- in state.RaidBonus — the raid payoff for starting over.
	state.RaidBonus = (state.RaidBonus or 0) + 0.05

	state.Cash = Config.START_CASH
	state.TotalEarned = 0
	state.Rebirths += 1
	state.LeaderCash.Value = state.Cash
	state.LeaderRebirths.Value = state.Rebirths

	-- The crown: a visible mark of the rebirth, one per rebirth.
	local character = player.Character
	if character then
		BrainrotFactory.giveCrown(character)
	end

	-- v2.5: milestone titles pay a one-off cash bonus on the rebirth
	-- that reaches them — Regular at 3, Legend at 5, Ohio Royalty at 10.
	local milestone = RebirthService.milestoneFor(state.Rebirths)
	local milestoneText = ""
	if milestone then
		DataService.addCash(state, milestone.bonus)
		milestoneText = " MILESTONE: " .. milestone.title .. " (+" .. tostring(milestone.bonus) .. " cash)!"
	end

	local rebirthText = player.Name .. " REBIRTHED! Income is now x" .. tostring(Config.REBIRTH_MULTIPLIER ^ state.Rebirths) .. " forever!"
	if petBonus > 0 then
		rebirthText ..= " Pets add +" .. tostring(math.floor(petBonus * 100 + 0.5)) .. "% more!"
	end
	-- v3: the raid bonus joins the rebirth toast.
	rebirthText ..= RebirthService.raidBonusLine(state)
	rebirthText ..= milestoneText
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireAllClients(rebirthText)
	end
end

return RebirthService
