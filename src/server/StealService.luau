-- Brainrot Boulevard: stealing. Grab a brainrot off someone else's base,
-- carry it home, and hold E on your own plot for the channel to claim it.
-- The victim can slap you to knock it loose; a locked base cannot be
-- stolen from at all. A dropped brainrot waits on the floor, then walks
-- home to its owner on its own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local StealService = {}

local DataService
local BaseService
local WorldBuilder
-- v2.5: QuestService is optional here (guarded like in ConveyorService),
-- so a claim with no quest service still claims, it just feeds no quest.
local QuestService

local SLAP_RANGE = 9
local SLAP_COOLDOWN = 1.5
local lastSlap = {}

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

local function weldToCarrier(model, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local primary = model.PrimaryPart
	if not root or not primary then
		return false
	end
	primary.Anchored = false
	primary.CanCollide = false
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = primary
	weld.C0 = CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.rad(180), 0)
	weld.Parent = primary
	model:SetAttribute("CarriedWeld", true)
	return true
end

local function unweld(model)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	for _, child in ipairs(primary:GetChildren()) do
		if child:IsA("Weld") then
			child:Destroy()
		end
	end
	model:SetAttribute("CarriedWeld", false)
end

-- Drop what the player is carrying where they stand; it becomes fair game.
function StealService.dropCarried(player, state)
	local model = state and state.Carrying
	if not model or not model.Parent then
		if state then
			state.Carrying = nil
		end
		return
	end
	unweld(model)
	state.Carrying = nil
	model:SetAttribute("State", "Dropped")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dropPos = root and root.Position or model:GetPivot().Position
	model:PivotTo(CFrame.new(dropPos + Vector3.new(0, 3, 0)))
	model.PrimaryPart.Anchored = true
	model:SetAttribute("DropTime", os.clock())
end

-- A dropped brainrot walks home to its owner's plot after a while.
function StealService.startReturnWatch()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, model in ipairs(Workspace:GetChildren()) do
				if model:IsA("Model") and model:GetAttribute("State") == "Dropped" then
					local dropTime = model:GetAttribute("DropTime") or 0
					if os.clock() - dropTime >= Config.DROPPED_RETURN_SECONDS then
						local ownerName = model:GetAttribute("Owner")
						local owner = ownerName and Players:FindFirstChild(ownerName) or nil
						local ownerState = owner and DataService.get(owner)
						if ownerState and ownerState.PlotIndex > 0 then
							BaseService.placeOnPlot(ownerState.PlotIndex, model, WorldBuilder)
							model:SetAttribute("State", "Owned")
							model.PrimaryPart.Anchored = true
						else
							model:Destroy()
						end
					end
				end
			end
		end
	end)
end

function StealService.init(services)
	DataService = services.DataService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder
	QuestService = services.QuestService

	services.Remotes.StealBrainrot.OnServerEvent:Connect(function(player, model)
		StealService.trySteal(player, model)
	end)
	services.Remotes.ClaimCarried.OnServerEvent:Connect(function(player)
		StealService.tryClaim(player)
	end)
	services.Remotes.Slap.OnServerEvent:Connect(function(player)
		StealService.trySlap(player)
	end)

	StealService.startReturnWatch()

	-- Carrying ends when the carrier dies or leaves.
	Players.PlayerRemoving:Connect(function(player)
		local state = DataService.get(player)
		if state and state.Carrying then
			StealService.dropCarried(player, state)
		end
	end)
end

-- Nearest stealable brainrot to a position: someone else's, on a plot that
-- is not locked, or a dropped one on the floor.
function StealService.nearestStealable(player, position, maxDist)
	local state = DataService.get(player)
	if not state then
		return nil
	end
	local best = nil
	local bestDist = maxDist
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("BrainrotId") then
			local mState = model:GetAttribute("State")
			if mState == "Owned" or mState == "Dropped" then
				local ownerName = model:GetAttribute("Owner")
				if ownerName ~= player.Name then
					local owner = ownerName and Players:FindFirstChild(ownerName) or nil
					local ownerState = owner and DataService.get(owner)
					local locked = ownerState and DataService.isLocked(ownerState)
					if not locked then
						local d = (model:GetPivot().Position - position).Magnitude
						if d < bestDist then
							bestDist = d
							best = model
						end
					end
				end
			end
		end
	end
	return best
end

function StealService.trySteal(player, model)
	local state = DataService.get(player)
	if not state or state.Carrying or not model or not model.Parent then
		return
	end
	if model:GetAttribute("State") ~= "Owned" and model:GetAttribute("State") ~= "Dropped" then
		return
	end
	if model:GetAttribute("Owner") == player.Name then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if (model:GetPivot().Position - root.Position).Magnitude > Config.STEAL_RANGE_STUDS then
		return
	end
	-- A locked base cannot be stolen from.
	local ownerName = model:GetAttribute("Owner")
	local owner = ownerName and Players:FindFirstChild(ownerName) or nil
	local ownerState = owner and DataService.get(owner)
	if ownerState and DataService.isLocked(ownerState) then
		announceTo(player, "That base is locked!")
		return
	end

	local wasOwned = model:GetAttribute("State") == "Owned"
	if wasOwned then
		BaseService.removeFromPlot(model)
		if ownerState then
			DataService.removeOwned(ownerState, model)
		end
	end
	model:SetAttribute("State", "Carried")
	model.PrimaryPart.Anchored = false
	if weldToCarrier(model, character) then
		state.Carrying = model
		announceTo(player, "Stolen! Dash home and hold E on your base to claim it!")
		if owner then
			local def = BrainrotData.getById(model:GetAttribute("BrainrotId"))
			announceTo(owner, player.Name .. " is stealing your " .. (def and def.name or "brainrot") .. "! Slap them!")
		end
	else
		StealService.dropCarried(player, state)
	end
end

-- The carrier stands on their own plot and channels the claim.
function StealService.tryClaim(player)
	local state = DataService.get(player)
	if not state or not state.Carrying then
		return
	end
	local model = state.Carrying
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if not BaseService.isOnPlot(root.Position, state.PlotIndex) then
		announceTo(player, "Stand on your own base to claim the steal!")
		return
	end
	if not BaseService.hasFreePedestal(state.PlotIndex) then
		announceTo(player, "Your base is full! Sell or rebirth first.")
		return
	end
	unweld(model)
	state.Carrying = nil
	model:SetAttribute("State", "Owned")
	model:SetAttribute("Owner", player.Name)
	model.PrimaryPart.Anchored = true
	DataService.addOwned(state, model)
	state.Steals += 1 -- v2: feeds the leaderboard's steals count.
	-- v2.5: every claimed steal feeds the daily "steal" quest.
	if QuestService then
		QuestService.addProgress(player, "steal", 1)
	end
	BaseService.placeOnPlot(state.PlotIndex, model, WorldBuilder)
	local def = BrainrotData.getById(model:GetAttribute("BrainrotId"))
	announceTo(player, "Claimed " .. (def and BrainrotData.displayName(def, model:GetAttribute("MutationIndex") or 1) or "brainrot") .. " for your base!")
end

-- The slap: knock a carried brainrot out of the nearest thief.
function StealService.trySlap(player)
	local state = DataService.get(player) -- v2: slaps count toward the leaderboard.
	if not state then
		return
	end
	local now = os.clock()
	if lastSlap[player] and now - lastSlap[player] < SLAP_COOLDOWN then
		return
	end
	lastSlap[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherState = DataService.get(other)
			local otherChar = other.Character
			local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
			if otherState and otherState.Carrying and otherRoot then
				if (otherRoot.Position - root.Position).Magnitude <= SLAP_RANGE then
					-- Fling the thief and drop their loot.
					otherRoot.AssemblyLinearVelocity = (otherRoot.Position - root.Position).Unit * 45 + Vector3.new(0, 30, 0)
					StealService.dropCarried(other, otherState)
					state.Slaps += 1 -- v2: feeds the leaderboard's slaps count.
					announceTo(player, "SLAP! You knocked the brainrot loose!")
					announceTo(other, player.Name .. " slapped your steal away!")
					return
				end
			end
		end
	end
end

return StealService
