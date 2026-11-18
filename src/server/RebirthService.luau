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

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireAllClients(player.Name .. " REBIRTHED! Income is now x" .. tostring(Config.REBIRTH_MULTIPLIER ^ state.Rebirths) .. " forever!")
	end
end

return RebirthService
