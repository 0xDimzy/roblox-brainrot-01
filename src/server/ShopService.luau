-- Brainrot Boulevard: the shop. Four items, all bought with in-game cash:
-- a permanent speed coil, a 60-second base lock, a slime trap for the
-- base entrance, and a lucky egg that hatches an Epic-or-better brainrot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local ShopService = {}

local DataService
local BaseService
local WorldBuilder
local BrainrotFactory

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

function ShopService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	BrainrotFactory = services.BrainrotFactory

	services.Remotes.BuyItem.OnServerEvent:Connect(function(player, itemId)
		ShopService.buy(player, itemId)
	end)
end

function ShopService.buy(player, itemId)
	local state = DataService.get(player)
	if not state then
		return
	end
	local item = nil
	for _, candidate in ipairs(Config.SHOP_ITEMS) do
		if candidate.id == itemId then
			item = candidate
			break
		end
	end
	if not item then
		return
	end
	if not DataService.spendCash(state, item.cost) then
		announceTo(player, "Not enough cash for " .. item.name .. "!")
		return
	end

	if itemId == "Coil" then
		state.HasCoil = true
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed += Config.COIL_SPEED_BONUS
		end
		announceTo(player, "Speed Coil equipped! +6 walk speed forever.")
	elseif itemId == "Lock" then
		state.LockUntil = os.clock() + Config.LOCK_DURATION_SECONDS
		announceTo(player, "Base locked for 60 seconds. Nobody can steal from you!")
	elseif itemId == "Trap" then
		ShopService.placeTrap(state)
		announceTo(player, "Slime Trap set at your base entrance!")
	elseif itemId == "Freeze" then
		ShopService.placeFreezeTrap(state)
		announceTo(player, "Freeze Trap set! Thieves crossing it freeze solid for 4s!")
	elseif itemId == "Egg" then
		ShopService.hatchEgg(player, state)
	end
end

function ShopService.placeTrap(state)
	state.Traps += 1
	local plotCenter = BaseService.plotCenter(state.PlotIndex)
	local trap = Instance.new("Part")
	trap.Name = "SlimeTrap"
	trap.Size = Vector3.new(6, 0.6, 6)
	trap.Color = Color3.fromRGB(120, 255, 120)
	trap.Material = Enum.Material.Neon
	trap.Transparency = 0.25
	trap.Anchored = true
	trap.CanCollide = false
	trap.Position = plotCenter + Vector3.new(0, 1.3, -12)
	trap.Parent = Workspace
	-- A thief crossing the trap is slowed hard for five seconds.
	local debounce = {}
	trap.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local thief = humanoid and game:GetService("Players"):GetPlayerFromCharacter(character)
		if not thief or debounce[thief] then
			return
		end
		local thiefState = DataService.get(thief)
		if not thiefState or thiefState.PlotIndex == state.PlotIndex then
			return
		end
		debounce[thief] = true
		local oldSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 4
		announceTo(thief, "Slime Trap! You are slowed!")
		task.delay(Config.TRAP_SLOW_SECONDS, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = oldSpeed
			end
			debounce[thief] = nil
		end)
	end)
	-- Traps melt away after two minutes.
	task.delay(120, function()
		if trap.Parent then
			trap:Destroy()
		end
		state.Traps = math.max(0, state.Traps - 1)
	end)
end

-- v2: Freeze Trap — an ice-blue pad at the base entrance. A thief
-- crossing it is frozen solid (walk speed 0) for FREEZE_SECONDS, long
-- enough for the owner to slap the steal loose. Melts after two minutes.
function ShopService.placeFreezeTrap(state)
	local plotCenter = BaseService.plotCenter(state.PlotIndex)
	local trap = Instance.new("Part")
	trap.Name = "FreezeTrap"
	trap.Size = Vector3.new(6, 0.6, 6)
	trap.Color = Color3.fromRGB(120, 200, 255)
	trap.Material = Enum.Material.Ice
	trap.Transparency = 0.25
	trap.Anchored = true
	trap.CanCollide = false
	trap.Position = plotCenter + Vector3.new(0, 1.3, 12)
	trap.Parent = Workspace
	local debounce = {}
	trap.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local thief = humanoid and game:GetService("Players"):GetPlayerFromCharacter(character)
		if not thief or debounce[thief] then
			return
		end
		local thiefState = DataService.get(thief)
		if not thiefState or thiefState.PlotIndex == state.PlotIndex then
			return
		end
		debounce[thief] = true
		local oldSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		announceTo(thief, "Freeze Trap! You are frozen solid!")
		task.delay(Config.FREEZE_SECONDS, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = oldSpeed
			end
			debounce[thief] = nil
		end)
	end)
	task.delay(120, function()
		if trap.Parent then
			trap:Destroy()
		end
	end)
end

function ShopService.hatchEgg(player, state)
	if state.PlotIndex == 0 or not BaseService.hasFreePedestal(state.PlotIndex) then
		announceTo(player, "Your base is full — the egg has nowhere to hatch!")
		DataService.addCash(state, 5000) -- refund: no pedestal, no egg
		return
	end
	local def = BrainrotData.rollDef()
	while def.rarity < 3 do
		def = BrainrotData.rollDef()
	end
	local model = BrainrotFactory.createBrainrot(def, BrainrotData.rollMutation())
	model:SetAttribute("State", "Owned")
	model:SetAttribute("Owner", player.Name)
	DataService.addOwned(state, model)
	BaseService.placeOnPlot(state.PlotIndex, model, WorldBuilder)
	announceTo(player, "The Lucky Egg hatched " .. BrainrotData.displayName(def, model:GetAttribute("MutationIndex") or 1) .. "!")
end

return ShopService
