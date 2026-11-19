-- Brainrot Boulevard: client bootstrap. Builds the HUD, watches the world
-- for the nearest thing to interact with, and turns one key — E — into
-- buy, steal, or claim, depending on what is in front of the player.
-- Q toggles the shop; clicking the slap tool slaps the nearest thief.
-- v3: T opens trading (E picks the two sides of an offer), Y opens
-- teams, F hits the raid boss, and the sky lift pads teleport you up
-- to the Sky Plaza and back down.

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

-- v2.5: the pet follower. The server owns pet state; the client renders
-- the active pet as a small companion that trails the player — a chunky
-- mini-brainrot built from the pet's Config color, with a name billboard.
-- latestPets mirrors the snapshot's pets table for the shop buttons.
local latestPets = nil
local activePetId = ""
local petModel = nil

-- v3: the new systems' snapshot mirrors, for the trade / raid /
-- minigame / team wiring below. latestTrade drives the inbox buttons;
-- tradeOffered / tradeWanted are the two brainrots the player picked
-- with E while the trade panel is open (yours, then theirs).
local latestTrade = nil
local latestRaid = nil
local latestMinigame = nil
local latestTeam = nil
local tradeOffered = nil
local tradeWanted = nil
local lastLiftAt = 0

-- Build the follower model for one pet definition (client-side copy of
-- BrainrotFactory.createPetModel, half-size, parented to Workspace).
local function buildPetFollower(petDef)
	local model = Instance.new("Model")
	model.Name = petDef.name .. " (Pet)"

	local function followerPart(name, size, color, offset)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Position = offset
		p.Parent = model
		return p
	end

	local body = followerPart("Body", Vector3.new(1.2, 1, 0.8), petDef.color, Vector3.new(0, 0, 0))
	body.Material = Enum.Material.Neon
	model.PrimaryPart = body
	followerPart("Head", Vector3.new(0.95, 0.8, 0.8), petDef.color, Vector3.new(0, 0.9, 0))
	followerPart("EyeL", Vector3.new(0.18, 0.25, 0.1), Color3.fromRGB(20, 20, 20), Vector3.new(-0.22, 0.95, 0.42))
	followerPart("EyeR", Vector3.new(0.18, 0.25, 0.1), Color3.fromRGB(20, 20, 20), Vector3.new(0.22, 0.95, 0.42))
	followerPart("EarL", Vector3.new(0.25, 0.4, 0.25), petDef.color, Vector3.new(-0.35, 1.4, 0))
	followerPart("EarR", Vector3.new(0.25, 0.4, 0.25), petDef.color, Vector3.new(0.35, 1.4, 0))

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PetLabel"
	billboard.Size = UDim2.fromOffset(140, 36)
	billboard.StudsOffset = Vector3.new(0, 1.9, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = Utils.shorten(petDef.name, 18)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	model.Parent = Workspace
	return model
end

-- Swap the follower when the active pet changes; destroy it when none.
local function setActivePet(petId)
	if petId == activePetId then
		return
	end
	activePetId = petId or ""
	if petModel then
		petModel:Destroy()
		petModel = nil
	end
	if activePetId ~= "" then
		local petDef = Config.petById(activePetId)
		if petDef then
			petModel = buildPetFollower(petDef)
		end
	end
end

-- The server's snapshot carries our plot index (for the on-plot check).
remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
	myPlotIndex = snapshot.plotIndex or 0
	-- v2.5: pets ride the same snapshot — keep the follower in sync.
	latestPets = snapshot.pets
	if snapshot.pets then
		setActivePet(snapshot.pets.active or "")
	end
	-- v3: trade, raid, minigame and team ride the same snapshot — keep
	-- the panel mirrors fresh so the buttons always act on live data.
	latestTrade = snapshot.trade
	latestRaid = snapshot.raid
	latestMinigame = snapshot.minigame
	latestTeam = snapshot.team
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

-- v3: the nearest owned brainrot (yours or someone else's) within
-- trade-picking range. Belt brainrots are not tradable — they have no
-- owner yet — and carried or dropped ones are mid-theft, not a deal.
local function nearestTradeable()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local pos = root.Position
	local best = nil
	local bestDist = Config.BUY_RANGE_STUDS
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("BrainrotId") then
			if model:GetAttribute("State") == "Owned" then
				local d = (model:GetPivot().Position - pos).Magnitude
				if d < bestDist then
					bestDist = d
					best = model
				end
			end
		end
	end
	return best
end

local function doInteract(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	-- v3: with the trade panel open, E picks brainrots for an offer
	-- instead of buying or stealing — yours first, then theirs.
	if Hud.tradeVisible() then
		local picked = nearestTradeable()
		if picked then
			if picked:GetAttribute("Owner") == player.Name then
				tradeOffered = picked
				Hud.toast("Offer side set: your " .. (picked.Name or "brainrot"))
			else
				tradeWanted = picked
				Hud.toast("Want side set: their " .. (picked.Name or "brainrot"))
			end
		else
			Hud.toast("No tradable brainrot nearby — stand by a base brainrot.")
		end
		return Enum.ContextActionResult.Sink
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

-- v2.5: pet panel buttons buy or equip. Owned pets equip (the follower
-- swaps at once); unowned pets buy with in-game cash, server-validated.
for _, pet in ipairs(Config.PETS) do
	local btn = Hud.petButton(pet.id)
	if btn then
		btn.MouseButton1Click:Connect(function()
			local owned = false
			if latestPets and latestPets.owned then
				for _, ownedId in ipairs(latestPets.owned) do
					if ownedId == pet.id then
						owned = true
						break
					end
				end
			end
			if owned then
				remotes.EquipPet:FireServer(pet.id)
			else
				remotes.BuyPet:FireServer(pet.id)
			end
		end)
	end
end

-- v2.5: quest claim buttons send the quest's index in today's trio (1-3);
-- the server resolves it, checks progress, and pays the reward.
for questIndex = 1, 3 do
	local claimBtn = Hud.questClaimButton(questIndex)
	if claimBtn then
		claimBtn.MouseButton1Click:Connect(function()
			remotes.ClaimQuest:FireServer(questIndex)
		end)
	end
end

-- v2.5: P opens the pets panel, J opens the daily quests panel.
local function togglePets(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Hud.togglePets()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardPets", togglePets, false, Enum.KeyCode.P)

local function toggleQuests(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Hud.toggleQuests()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardQuests", toggleQuests, false, Enum.KeyCode.J)

-- v3: T opens the trade panel, Y opens the team panel, F hits the
-- boss when a raid is running and you stand near the raid pad.
local function toggleTrade(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Hud.toggleTrade()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardTrade", toggleTrade, false, Enum.KeyCode.T)

local function toggleTeam(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	Hud.toggleTeam()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardTeam", toggleTeam, false, Enum.KeyCode.Y)

local function doRaidHit(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if latestRaid and latestRaid.active then
		remotes.RaidHit:FireServer()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("BoulevardRaidHit", doRaidHit, false, Enum.KeyCode.F)

-- v7: G fuses at the Fuse Machine — the server checks the cooldown,
-- the distance and the stock, then fuses the lowest triple up.
local function doFuse(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	remotes.FuseBrainrots:FireServer()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BoulevardFuse", doFuse, false, Enum.KeyCode.G)

-- v3: the trade inbox buttons. Each row acts on the offer the latest
-- snapshot put in that row — accept / decline answer it, confirm
-- seals it once both sides have said yes.
for rowIndex = 1, 3 do
	local buttons = Hud.tradeRowButtons(rowIndex)
	if buttons then
		buttons.accept.MouseButton1Click:Connect(function()
			local offer = latestTrade and latestTrade.incoming and latestTrade.incoming[rowIndex]
			if offer then
				remotes.TradeRespond:FireServer(offer.id, "accept")
			end
		end)
		buttons.decline.MouseButton1Click:Connect(function()
			local offer = latestTrade and latestTrade.incoming and latestTrade.incoming[rowIndex]
			if offer then
				remotes.TradeRespond:FireServer(offer.id, "decline")
			end
		end)
		buttons.confirm.MouseButton1Click:Connect(function()
			local offer = latestTrade and latestTrade.incoming and latestTrade.incoming[rowIndex]
			if offer then
				remotes.TradeConfirm:FireServer(offer.id)
			end
		end)
	end
end

-- v3: the offer sender. Needs a target name typed in, one of your
-- brainrots picked with E and one of theirs — the server checks all
-- three again before the offer reaches the inbox.
local tradeSendButton = Hud.tradeSendButton()
if tradeSendButton then
	tradeSendButton.MouseButton1Click:Connect(function()
		local targetBox = Hud.tradeTargetBox()
		local targetName = targetBox and targetBox.Text or ""
		if targetName == "" then
			Hud.toast("Type a player's name to trade with first.")
			return
		end
		if not tradeOffered or not tradeOffered.Parent then
			Hud.toast("Pick one of YOUR brainrots with E first.")
			return
		end
		if not tradeWanted or not tradeWanted.Parent then
			Hud.toast("Pick one of THEIR brainrots with E first.")
			return
		end
		remotes.TradeOffer:FireServer(targetName, tradeOffered, tradeWanted, 0)
		tradeOffered = nil
		tradeWanted = nil
	end)
end

-- v3: the team panel buttons. Create / join read the name box; the
-- deposit reads the amount box; leave needs no input at all.
local teamCreateButton = Hud.teamCreateButton()
if teamCreateButton then
	teamCreateButton.MouseButton1Click:Connect(function()
		local nameBox = Hud.teamNameBox()
		remotes.TeamCreate:FireServer(nameBox and nameBox.Text or "")
	end)
end

local teamJoinButton = Hud.teamJoinButton()
if teamJoinButton then
	teamJoinButton.MouseButton1Click:Connect(function()
		local nameBox = Hud.teamNameBox()
		remotes.TeamJoin:FireServer(nameBox and nameBox.Text or "")
	end)
end

local teamLeaveButton = Hud.teamLeaveButton()
if teamLeaveButton then
	teamLeaveButton.MouseButton1Click:Connect(function()
		remotes.TeamLeave:FireServer()
	end)
end

local teamDepositButton = Hud.teamDepositButton()
if teamDepositButton then
	teamDepositButton.MouseButton1Click:Connect(function()
		local depositBox = Hud.teamDepositBox()
		remotes.TeamDeposit:FireServer(tonumber(depositBox and depositBox.Text or "") or 0)
	end)
end

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
	-- v3: the sky lift. Standing on the lift pad rides you up to the
	-- Sky Plaza; standing on the return pad rides you back down. A
	-- 2-second debounce stops the pads from bouncing you back and
	-- forth the moment you land on the other side.
	local rayDown = Workspace:Raycast(root.Position, Vector3.new(0, -10, 0))
	if rayDown and rayDown.Instance and os.clock() - lastLiftAt > 2 then
		if rayDown.Instance.Name == "SkyLiftPad" then
			lastLiftAt = os.clock()
			root.CFrame = CFrame.new(Config.SKY_RETURN_POSITION + Vector3.new(0, 3, 0))
			Hud.toast("Welcome to the Sky Plaza — plots here earn +25%!")
		elseif rayDown.Instance.Name == "SkyReturnPad" then
			lastLiftAt = os.clock()
			root.CFrame = CFrame.new(Config.SKY_LIFT_POSITION + Vector3.new(0, 3, 0))
			Hud.toast("Back on the boulevard.")
		end
	end
	local _, _, text = nearestAction()
	Hud.setPrompt(text)

	-- v2.5: the pet follower trails the player — a step behind and to the
	-- side, bobbing gently, teleporting back when it falls too far behind
	-- (after a respawn, say). Purely cosmetic: income and ownership are
	-- the server's, from the snapshot that built this model.
	if petModel and petModel.PrimaryPart then
		local target = root.CFrame * CFrame.new(2.5, 0.5 + math.sin(os.clock() * 3) * 0.25, 2.5)
		local current = petModel:GetPivot()
		-- The prompt refresh runs four times a second, so the follower
		-- lerps hard (0.35) to keep up between ticks.
		if (current.Position - target.Position).Magnitude > 30 then
			petModel:PivotTo(target)
		else
			petModel:PivotTo(current:Lerp(target, 0.35))
		end
	end
end)
