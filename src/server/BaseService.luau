-- Brainrot Boulevard: bases. Claims a plot for each player, places owned
-- brainrots on its pedestals, enforces the base lock, and tracks which
-- pedestal is free. Stealing itself lives in StealService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BaseService = {}

local plots = {} -- [plotIndex] = { Owner = Player?, Pedestals = { [1..6] = Model? } }

function BaseService.init()
	for i = 1, Config.PLOT_COUNT do
		plots[i] = { Owner = nil, Pedestals = {} }
		for j = 1, Config.PLOT_PEDESTALS do
			plots[i].Pedestals[j] = nil
		end
	end
end

function BaseService.claimPlot(player)
	for i, plot in ipairs(plots) do
		if plot.Owner == nil then
			plot.Owner = player
			return i
		end
	end
	return 0
end

function BaseService.freePlot(player, DataService)
	for i, plot in ipairs(plots) do
		if plot.Owner == player then
			plot.Owner = nil
			for j, model in ipairs(plot.Pedestals) do
				if model then
					model:Destroy()
					plot.Pedestals[j] = nil
				end
			end
			return
		end
	end
end

function BaseService.plotOf(player)
	for i, plot in ipairs(plots) do
		if plot.Owner == player then
			return i
		end
	end
	return 0
end

function BaseService.ownerOf(plotIndex)
	local plot = plots[plotIndex]
	return plot and plot.Owner or nil
end

function BaseService.freePedestalIndex(plotIndex)
	local plot = plots[plotIndex]
	if not plot then
		return 0
	end
	for j = 1, Config.PLOT_PEDESTALS do
		if plot.Pedestals[j] == nil then
			return j
		end
	end
	return 0
end

function BaseService.hasFreePedestal(plotIndex)
	return BaseService.freePedestalIndex(plotIndex) > 0
end

-- Move a brainrot model onto a free pedestal of a plot and record it.
-- Returns the pedestal index, or 0 when the plot is full.
function BaseService.placeOnPlot(plotIndex, model, WorldBuilder)
	local pedIndex = BaseService.freePedestalIndex(plotIndex)
	if pedIndex == 0 then
		return 0
	end
	plots[plotIndex].Pedestals[pedIndex] = model
	local target = WorldBuilder.pedestalPosition(plotIndex, pedIndex)
	model:PivotTo(CFrame.new(target))
	model:SetAttribute("PlotIndex", plotIndex)
	model:SetAttribute("PedestalIndex", pedIndex)
	return pedIndex
end

-- Remove a brainrot from its pedestal (stolen, sold, or rebirth-cleared).
function BaseService.removeFromPlot(model)
	local plotIndex = model:GetAttribute("PlotIndex") or 0
	local pedIndex = model:GetAttribute("PedestalIndex") or 0
	if plotIndex > 0 and pedIndex > 0 and plots[plotIndex] then
		if plots[plotIndex].Pedestals[pedIndex] == model then
			plots[plotIndex].Pedestals[pedIndex] = nil
		end
	end
	model:SetAttribute("PlotIndex", 0)
	model:SetAttribute("PedestalIndex", 0)
end

-- Is this point on the given player's own plot pad? Used by the tsunami
-- (safe ground) and by the steal channel (home base).
function BaseService.isOnPlot(position, plotIndex)
	if plotIndex == 0 then
		return false
	end
	local center = Config.PLOT_POSITIONS[plotIndex]
	return math.abs(position.X - center.X) <= 12 and math.abs(position.Z - center.Z) <= 10
end

function BaseService.plotCenter(plotIndex)
	return Config.PLOT_POSITIONS[plotIndex]
end

-- v2.5: how full a base is — used pedestals and the total (6). The
-- meteor shower and the quest board read this to pick a base that can
-- still take a brainrot.
function BaseService.plotOccupancy(plotIndex)
	local plot = plots[plotIndex]
	if not plot then
		return 0, 0
	end
	local used = 0
	for j = 1, Config.PLOT_PEDESTALS do
		if plot.Pedestals[j] ~= nil then
			used += 1
		end
	end
	return used, Config.PLOT_PEDESTALS
end

-- v2.5: is this base completely full?
function BaseService.isPlotFull(plotIndex)
	local used, total = BaseService.plotOccupancy(plotIndex)
	return used >= total
end

-- v2.5: every plot index that currently has an owner, in plot order.
function BaseService.plotsWithOwners()
	local owned = {}
	for i, plot in ipairs(plots) do
		if plot.Owner ~= nil then
			table.insert(owned, i)
		end
	end
	return owned
end

-- v2.5: a random plot with a free pedestal, preferring owned bases so a
-- meteor's free brainrot lands with a player. Returns 0 when every base
-- is full (or no base exists yet) — the caller then falls back to the
-- conveyor, so the brainrot is never lost.
function BaseService.randomPlotWithFreePedestal()
	local candidates = {}
	for _, i in ipairs(BaseService.plotsWithOwners()) do
		if not BaseService.isPlotFull(i) then
			table.insert(candidates, i)
		end
	end
	if #candidates > 0 then
		return candidates[math.random(1, #candidates)]
	end
	for i = 1, Config.PLOT_COUNT do
		if not BaseService.isPlotFull(i) then
			table.insert(candidates, i)
		end
	end
	if #candidates > 0 then
		return candidates[math.random(1, #candidates)]
	end
	return 0
end

return BaseService
