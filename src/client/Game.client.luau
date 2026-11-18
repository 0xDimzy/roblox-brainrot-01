-- Brainrot Boulevard: client bootstrap. Builds the HUD, watches the world
-- for the nearest thing to interact with, and turns one key — E — into
-- buy, steal, or claim, depending on what is in front of the player.
-- Q toggles the shop; clicking the slap tool slaps the nearest thief.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

Hud.build(remotes)

local carrying = false
local onOwnPlot = false
local myPlotIndex = 0

-- The server's snapshot carries our plot index (for the on-plot check).
remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
	myPlotIndex = snapshot.plotIndex or 0
end)

-- Scan the world for the nearest brainrot the player can act on.
-- Returns: kind ("buy" | "steal" | "claim" | "none"), the model, its text.
local function nearestAction()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return "none", nil, ""
	end
	local pos = root.Position

	if carrying then
		if onOwnPlot then
			return "claim", nil, "Hold E — claim your steal for your base!"
		end
		return "none", nil, "Dash home to your base and hold E to claim the steal!"
	end

	-- A belt brainrot to buy.
	local bestBuy = nil
	local bestBuyDist = Config.BUY_RANGE_STUDS
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("State") == "Belt" then
			local d = (model:GetPivot().Position - pos).Magnitude
			if d < bestBuyDist then
				bestBuyDist = d
				bestBuy = model
			end
		end
	end
	if bestBuy then
		local def = BrainrotData.getById(bestBuy:GetAttribute("BrainrotId"))
		local price = bestBuy:GetAttribute("Price") or 0
		if def then
			return "buy", bestBuy, "E — Buy " .. BrainrotData.displayName(def, bestBuy:GetAttribute("MutationIndex") or 1) .. " for " .. Utils.formatMoney(price) .. "  (" .. Utils.formatRate(BrainrotData.incomeOf(def, bestBuy:GetAttribute("MutationIndex") or 1, 1)) .. ")"
		end
	end

	-- Someone else's brainrot to steal (not on a locked base).
	local bestSteal = nil
	local bestStealDist = Config.STEAL_RANGE_STUDS
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("BrainrotId") then
			local state = model:GetAttribute("State")
			if (state == "Owned" or state == "Dropped") and model:GetAttribute("Owner") ~= player.Name then
				local d = (model:GetPivot().Position - pos).Magnitude
				if d < bestStealDist then
					bestStealDist = d
					bestSteal = model
				end
			end
		end
	end
	if bestSteal then
		local def = BrainrotData.getById(bestSteal:GetAttribute("BrainrotId"))
		if def then
			return "steal", bestSteal, "E — Steal " .. BrainrotData.displayName(def, bestSteal:GetAttribute("MutationIndex") or 1) .. "!"
		end
	end

	return "none", nil, "Walk to the conveyor and press E to buy a brainrot!"
end

local function doInteract(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local kind, model = nearestAction()
	if kind == "buy" and model then
		remotes.BuyBrainrot:FireServer(model)
	elseif kind == "steal" and model then
		remotes.StealBrainrot:FireServer(model)
	elseif kind == "claim" then
		remotes.ClaimCarried:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardInteract", doInteract, false, Enum.KeyCode.E)

local function toggleShop(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Hud.toggleShop()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardShop", toggleShop, false, Enum.KeyCode.Q)

-- Shop buttons buy their item.
for _, item in ipairs(Config.SHOP_ITEMS) do
	local btn = Hud.shopButton(item.id)
	if btn then
		btn.MouseButton1Click:Connect(function()
			remotes.BuyItem:FireServer(item.id)
		end)
	end
end

-- Rebirth button asks the server; the server checks the cost.
Hud.rebirthButton().MouseButton1Click:Connect(function()
	remotes.Rebirth:FireServer()
end)

-- The slap tool: clicking it slaps the nearest thief.
local function wireSlapTool(character)
	local backpack = player:WaitForChild("Backpack")
	local function hook(tool)
		if tool.Name ~= "Slap Hand" then
			return
		end
		tool.Activated:Connect(function()
			remotes.Slap:FireServer()
		end)
	end
	for _, tool in ipairs(backpack:GetChildren()) do
		hook(tool)
	end
	backpack.ChildAdded:Connect(hook)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			hook(child)
		end
	end)
end

if player.Character then
	wireSlapTool(player.Character)
end
player.CharacterAdded:Connect(wireSlapTool)

-- Prompt refresh, four times a second, plus the carried / on-plot flags the
-- prompt depends on. The server is the authority; these flags are display.
local promptClock = 0
RunService.RenderStepped:Connect(function(dt)
	promptClock += dt
	if promptClock < 0.25 then
		return
	end
	promptClock = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- Am I carrying? A carried brainrot rides right in front of its carrier.
	carrying = false
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("State") == "Carried" then
			if (model:GetPivot().Position - root.Position).Magnitude < 6 then
				carrying = true
				break
			end
		end
	end
	-- Am I on my own plot? The pad or pedestal under my feet carries the
	-- plot's index; it must match the one the server gave me.
	onOwnPlot = false
	if myPlotIndex > 0 then
		local ray = Workspace:Raycast(root.Position, Vector3.new(0, -10, 0))
		if ray and ray.Instance then
			local plotIndex = ray.Instance:GetAttribute("PlotIndex")
			if plotIndex and plotIndex == myPlotIndex then
				onOwnPlot = true
			end
		end
	end
	local _, _, text = nearestAction()
	Hud.setPrompt(text)
end)
