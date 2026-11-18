-- Brainrot Boulevard: the whole interface, built in code. Top bar with cash,
-- income, collection and rebirths; a bottom prompt; toasts; the event
-- banner; the shop; the rebirth button; the collection list; and the v2
-- leaderboard panel (top earners) plus a personal stats line.
-- v3 adds the trade panel (T), the boss raid bar, the coin rush panel
-- and the team panel (Y), all fed by the same once-a-second snapshot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local Hud = {}

local player = Players.LocalPlayer
local gui
local cashLabel
local incomeLabel
local countLabel
local rebirthLabel
local eventChip
local promptLabel
local toastLabel
local bannerLabel
local shopFrame
local collectionList
local leaderboardRows = {}
local statsLabel
local rebirthButton
local rebirthProgress
local toastQueue = {}
local toastBusy = false
-- v2.5: pets and quests panels (P and J) with their live rows.
local petsFrame
local questsFrame
local petButtons = {}
local questClaimButtons = {}
local questProgressLabels = {}
local activePetLabel
local petsSummaryLabel
local questSummaryLabel
-- v3: trade (T), raid bar, minigame and team (Y) panels.
local tradeFrame
local tradeHintLabel
local tradeIncomingLabels = {}
local tradeRowButtons = {}
local tradeSendButton
local tradeTargetBox
local raidFrame
local raidBossLabel
local raidHpFill
local raidTimerLabel
local raidMyLabel
local raidTopLabels = {}
local minigameFrame
local minigameStatusLabel
local minigameScoreLabel
local minigameTopLabel
local teamFrame
local teamStatusLabel
local teamMembersLabel
local teamVaultLabel
local teamTopLabel
local teamNameBox
local teamDepositBox
local teamCreateButton
local teamJoinButton
local teamLeaveButton
local teamDepositButton

local function label(parent, name, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.TextStrokeTransparency = 0
	l.Font = font or Enum.Font.FredokaOne
	l.Parent = parent
	return l
end

local function chip(parent, name, width)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.new(0, width, 0, 44)
	f.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = f
	f.Parent = parent
	return f
end

function Hud.build(remotes)
	gui = Instance.new("ScreenGui")
	gui.Name = "BoulevardGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Top bar, centered so the top-left stays clear for Roblox's menu.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 12)
	topBar.Size = UDim2.new(0, 720, 0, 52)
	topBar.BackgroundTransparency = 1
	topBar.Parent = gui
	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	topLayout.Padding = UDim.new(0, 8)
	topLayout.Parent = topBar

	local cashChip = chip(topBar, "CashChip", 190)
	cashLabel = label(cashChip, "Cash", "$100", 26, Color3.fromRGB(120, 255, 140))
	cashLabel.Size = UDim2.fromScale(1, 1)
	cashLabel.Parent = cashChip

	local incomeChip = chip(topBar, "IncomeChip", 170)
	incomeLabel = label(incomeChip, "Income", "$0/s", 26, Color3.fromRGB(255, 230, 120))
	incomeLabel.Size = UDim2.fromScale(1, 1)
	incomeLabel.Parent = incomeChip

	local countChip = chip(topBar, "CountChip", 150)
	countLabel = label(countChip, "Count", "0 brainrots", 22)
	countLabel.Size = UDim2.fromScale(1, 1)
	countLabel.Parent = countChip

	local rebirthChip = chip(topBar, "RebirthChip", 130)
	rebirthLabel = label(rebirthChip, "Rebirths", "Rebirth x1", 22, Color3.fromRGB(255, 180, 255))
	rebirthLabel.Size = UDim2.fromScale(1, 1)
	rebirthLabel.Parent = rebirthChip

	eventChip = chip(topBar, "EventChip", 150)
	eventChip.Visible = false
	local eventLabel = label(eventChip, "Event", "GOLDEN HOUR x2", 22, Color3.fromRGB(255, 215, 0))
	eventLabel.Size = UDim2.fromScale(1, 1)
	eventLabel.Parent = eventChip

	-- Title, under the top bar.
	local title = label(gui, "Title", "BRAINROT BOULEVARD", 34, Color3.fromRGB(255, 195, 0))
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0, 72)
	title.Size = UDim2.new(0, 560, 0, 40)
	title.Parent = gui

	-- Personal stats line, under the title: bought / steals / best $/s.
	statsLabel = label(gui, "StatsLine", "Bought 0  ·  Steals 0  ·  Best $0/s", 20, Color3.fromRGB(200, 220, 255))
	statsLabel.AnchorPoint = Vector2.new(0.5, 0)
	statsLabel.Position = UDim2.new(0.5, 0, 0, 112)
	statsLabel.Size = UDim2.new(0, 560, 0, 26)
	statsLabel.Parent = gui

	-- Event banner, center screen, hidden until an event fires.
	bannerLabel = label(gui, "EventBanner", "", 44, Color3.fromRGB(255, 215, 0))
	bannerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	bannerLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	bannerLabel.Size = UDim2.new(0, 900, 0, 110)
	bannerLabel.Visible = false
	bannerLabel.TextWrapped = true
	bannerLabel.Parent = gui

	-- Toast, one line under the banner.
	toastLabel = label(gui, "Toast", "", 26, Color3.fromRGB(255, 255, 255))
	toastLabel.AnchorPoint = Vector2.new(0.5, 0)
	toastLabel.Position = UDim2.new(0.5, 0, 0, 130)
	toastLabel.Size = UDim2.new(0, 900, 0, 36)
	toastLabel.Visible = false
	toastLabel.Parent = gui

	-- Interact prompt, bottom center.
	local promptBack = Instance.new("Frame")
	promptBack.Name = "PromptBack"
	promptBack.AnchorPoint = Vector2.new(0.5, 1)
	promptBack.Position = UDim2.new(0.5, 0, 1, -24)
	promptBack.Size = UDim2.new(0, 640, 0, 48)
	promptBack.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	promptBack.BackgroundTransparency = 0.15
	promptBack.BorderSizePixel = 0
	local promptCorner = Instance.new("UICorner")
	promptCorner.CornerRadius = UDim.new(0, 10)
	promptCorner.Parent = promptBack
	promptBack.Parent = gui
	promptLabel = label(promptBack, "Prompt", "Walk to the conveyor and press E to buy a brainrot!", 24)
	promptLabel.Size = UDim2.fromScale(1, 1)
	promptLabel.Parent = promptBack

	-- Controls hint, bottom left.
	local hint = label(gui, "Hint", "WASD move  ·  E interact  ·  Q shop  ·  P pets  ·  J quests  ·  Click to slap thieves", 18, Color3.fromRGB(220, 220, 220))
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.new(0, 16, 1, -16)
	hint.Size = UDim2.new(0, 520, 0, 24)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = gui

	-- Shop, right side, hidden until Q.
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "Shop"
	shopFrame.AnchorPoint = Vector2.new(1, 0)
	shopFrame.Position = UDim2.new(1, -16, 0, 130)
	shopFrame.Size = UDim2.new(0, 300, 0, 400)
	shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	shopFrame.BackgroundTransparency = 0.1
	shopFrame.BorderSizePixel = 0
	shopFrame.Visible = false
	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 12)
	shopCorner.Parent = shopFrame
	shopFrame.Parent = gui
	local shopTitle = label(shopFrame, "ShopTitle", "SHOP  (Q to close)", 24, Color3.fromRGB(255, 195, 0))
	shopTitle.Position = UDim2.new(0, 0, 0, 8)
	shopTitle.Size = UDim2.new(1, 0, 0, 32)
	shopTitle.Parent = shopFrame
	local shopList = Instance.new("UIListLayout")
	shopList.Padding = UDim.new(0, 8)
	shopList.SortOrder = Enum.SortOrder.LayoutOrder
	shopList.Parent = shopFrame
	local shopPad = Instance.new("UIPadding")
	shopPad.PaddingTop = UDim.new(0, 48)
	shopPad.PaddingLeft = UDim.new(0, 12)
	shopPad.PaddingRight = UDim.new(0, 12)
	shopPad.Parent = shopFrame
	for i, item in ipairs(Config.SHOP_ITEMS) do
		local btn = Instance.new("TextButton")
		btn.Name = "Shop_" .. item.id
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1, 0, 0, 56)
		btn.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
		btn.Text = item.name .. "  ·  " .. Utils.formatMoney(item.cost) .. "\n" .. item.desc
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 18
		btn.Font = Enum.Font.FredokaOne
		btn.Parent = shopFrame
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn
	end

	-- Rebirth button + progress, bottom right.
	rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.AnchorPoint = Vector2.new(1, 1)
	rebirthButton.Position = UDim2.new(1, -16, 1, -80)
	rebirthButton.Size = UDim2.new(0, 300, 0, 56)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 40, 180)
	rebirthButton.Text = "REBIRTH  x2 income"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.TextSize = 22
	rebirthButton.Font = Enum.Font.FredokaOne
	rebirthButton.Parent = gui
	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 10)
	rebirthCorner.Parent = rebirthButton
	rebirthProgress = label(gui, "RebirthProgress", "", 18, Color3.fromRGB(255, 180, 255))
	rebirthProgress.AnchorPoint = Vector2.new(1, 1)
	rebirthProgress.Position = UDim2.new(1, -16, 1, -140)
	rebirthProgress.Size = UDim2.new(0, 300, 0, 24)
	rebirthProgress.TextXAlignment = Enum.TextXAlignment.Right
	rebirthProgress.Parent = gui

	-- Collection list, left side.
	local collectionFrame = Instance.new("Frame")
	collectionFrame.Name = "Collection"
	collectionFrame.AnchorPoint = Vector2.new(0, 0)
	collectionFrame.Position = UDim2.new(0, 16, 0, 130)
	collectionFrame.Size = UDim2.new(0, 300, 0, 330)
	collectionFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	collectionFrame.BackgroundTransparency = 0.1
	collectionFrame.BorderSizePixel = 0
	local collectionCorner = Instance.new("UICorner")
	collectionCorner.CornerRadius = UDim.new(0, 12)
	collectionCorner.Parent = collectionFrame
	collectionFrame.Parent = gui
	local collectionTitle = label(collectionFrame, "CollectionTitle", "MY BRAINROTS", 24, Color3.fromRGB(120, 255, 140))
	collectionTitle.Position = UDim2.new(0, 0, 0, 8)
	collectionTitle.Size = UDim2.new(1, 0, 0, 32)
	collectionTitle.Parent = collectionFrame
	collectionList = Instance.new("ScrollingFrame")
	collectionList.Name = "List"
	collectionList.Position = UDim2.new(0, 0, 0, 48)
	collectionList.Size = UDim2.new(1, 0, 1, -56)
	collectionList.BackgroundTransparency = 1
	collectionList.ScrollBarThickness = 4
	collectionList.CanvasSize = UDim2.new(0, 0, 0, 0)
	collectionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	collectionList.Parent = collectionFrame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = collectionList
	local listPad = Instance.new("UIPadding")
	listPad.PaddingLeft = UDim.new(0, 12)
	listPad.PaddingRight = UDim.new(0, 12)
	listPad.Parent = collectionList

	-- v2 leaderboard panel, left side under the collection: top 5 earners.
	local boardFrame = Instance.new("Frame")
	boardFrame.Name = "Leaderboard"
	boardFrame.AnchorPoint = Vector2.new(0, 0)
	boardFrame.Position = UDim2.new(0, 16, 0, 476)
	boardFrame.Size = UDim2.new(0, 300, 0, 200)
	boardFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	boardFrame.BackgroundTransparency = 0.1
	boardFrame.BorderSizePixel = 0
	local boardCorner = Instance.new("UICorner")
	boardCorner.CornerRadius = UDim.new(0, 12)
	boardCorner.Parent = boardFrame
	boardFrame.Parent = gui
	local boardTitle = label(boardFrame, "BoardTitle", "TOP EARNERS", 24, Color3.fromRGB(255, 215, 0))
	boardTitle.Position = UDim2.new(0, 0, 0, 8)
	boardTitle.Size = UDim2.new(1, 0, 0, 32)
	boardTitle.Parent = boardFrame
	for i = 1, 5 do
		local row = label(boardFrame, "BoardRow" .. tostring(i), tostring(i) .. ". —", 18)
		row.Position = UDim2.new(0, 12, 0, 44 + (i - 1) * 28)
		row.Size = UDim2.new(1, -24, 0, 26)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = boardFrame
		leaderboardRows[i] = row
	end

	-- v2.5 pets panel, right side overlay (P to open, like the shop): the
	-- six pets, the active follower, and the income bonus they grant.
	petsFrame = Instance.new("Frame")
	petsFrame.Name = "Pets"
	petsFrame.AnchorPoint = Vector2.new(1, 0)
	petsFrame.Position = UDim2.new(1, -16, 0, 130)
	petsFrame.Size = UDim2.new(0, 300, 0, 470)
	petsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	petsFrame.BackgroundTransparency = 0.1
	petsFrame.BorderSizePixel = 0
	petsFrame.Visible = false
	local petsCorner = Instance.new("UICorner")
	petsCorner.CornerRadius = UDim.new(0, 12)
	petsCorner.Parent = petsFrame
	petsFrame.Parent = gui
	local petsTitle = label(petsFrame, "PetsTitle", "PETS  (P to close)", 24, Color3.fromRGB(255, 215, 0))
	petsTitle.Position = UDim2.new(0, 0, 0, 8)
	petsTitle.Size = UDim2.new(1, 0, 0, 32)
	petsTitle.Parent = petsFrame
	activePetLabel = label(petsFrame, "ActivePet", "No pet following you", 18, Color3.fromRGB(120, 255, 140))
	activePetLabel.Position = UDim2.new(0, 12, 0, 44)
	activePetLabel.Size = UDim2.new(1, -24, 0, 26)
	activePetLabel.TextXAlignment = Enum.TextXAlignment.Left
	activePetLabel.Parent = petsFrame
	petsSummaryLabel = label(petsFrame, "PetsSummary", "0 pets (+0% income)", 18, Color3.fromRGB(200, 220, 255))
	petsSummaryLabel.Position = UDim2.new(0, 12, 0, 70)
	petsSummaryLabel.Size = UDim2.new(1, -24, 0, 26)
	petsSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	petsSummaryLabel.Parent = petsFrame
	local petsList = Instance.new("UIListLayout")
	petsList.Padding = UDim.new(0, 8)
	petsList.SortOrder = Enum.SortOrder.LayoutOrder
	petsList.Parent = petsFrame
	local petsPad = Instance.new("UIPadding")
	petsPad.PaddingTop = UDim.new(0, 0)
	petsPad.PaddingLeft = UDim.new(0, 12)
	petsPad.PaddingRight = UDim.new(0, 12)
	petsPad.Parent = petsFrame
	for i, pet in ipairs(Config.PETS) do
		local btn = Instance.new("TextButton")
		btn.Name = "Pet_" .. pet.id
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1, 0, 0, 52)
		btn.BackgroundColor3 = Color3.fromRGB(90, 60, 140)
		btn.Text = pet.name .. "  ·  " .. Utils.formatMoney(pet.cost) .. "\n" .. pet.desc
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 18
		btn.Font = Enum.Font.FredokaOne
		btn.Parent = petsFrame
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn
		petButtons[pet.id] = btn
	end

	-- v2.5 quests panel, left side overlay (J to open): today's three
	-- daily quests with live progress bars and claim buttons.
	questsFrame = Instance.new("Frame")
	questsFrame.Name = "Quests"
	questsFrame.AnchorPoint = Vector2.new(0, 0)
	questsFrame.Position = UDim2.new(0, 16, 0, 130)
	questsFrame.Size = UDim2.new(0, 300, 0, 330)
	questsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	questsFrame.BackgroundTransparency = 0.1
	questsFrame.BorderSizePixel = 0
	questsFrame.Visible = false
	local questsCorner = Instance.new("UICorner")
	questsCorner.CornerRadius = UDim.new(0, 12)
	questsCorner.Parent = questsFrame
	questsFrame.Parent = gui
	local questsTitle = label(questsFrame, "QuestsTitle", "DAILY QUESTS  (J to close)", 24, Color3.fromRGB(120, 255, 140))
	questsTitle.Position = UDim2.new(0, 0, 0, 8)
	questsTitle.Size = UDim2.new(1, 0, 0, 32)
	questsTitle.Parent = questsFrame
	questSummaryLabel = label(questsFrame, "QuestSummary", "0 of 3 quests done", 18, Color3.fromRGB(200, 220, 255))
	questSummaryLabel.Position = UDim2.new(0, 12, 0, 44)
	questSummaryLabel.Size = UDim2.new(1, -24, 0, 26)
	questSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	questSummaryLabel.Parent = questsFrame
	for i = 1, 3 do
		local row = Instance.new("Frame")
		row.Name = "QuestRow" .. tostring(i)
		row.Position = UDim2.new(0, 12, 0, 78 + (i - 1) * 80)
		row.Size = UDim2.new(1, -24, 0, 72)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.BorderSizePixel = 0
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row
		row.Parent = questsFrame
		local rowTitle = label(row, "QuestTitle", "Quest " .. tostring(i), 18)
		rowTitle.Position = UDim2.new(0, 8, 0, 4)
		rowTitle.Size = UDim2.new(1, -16, 0, 24)
		rowTitle.TextXAlignment = Enum.TextXAlignment.Left
		rowTitle.Parent = row
		local progress = label(row, "QuestProgress", "0 / 0", 16, Color3.fromRGB(200, 220, 255))
		progress.Position = UDim2.new(0, 8, 0, 28)
		progress.Size = UDim2.new(1, -16, 0, 20)
		progress.TextXAlignment = Enum.TextXAlignment.Left
		progress.Parent = row
		questProgressLabels[i] = progress
		local claim = Instance.new("TextButton")
		claim.Name = "QuestClaim" .. tostring(i)
		claim.Position = UDim2.new(0, 8, 0, 50)
		claim.Size = UDim2.new(1, -16, 0, 20)
		claim.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
		claim.Text = "CLAIM"
		claim.TextColor3 = Color3.fromRGB(255, 255, 255)
		claim.TextSize = 15
		claim.Font = Enum.Font.FredokaOne
		claim.Parent = row
		questClaimButtons[i] = claim
	end

	-- v3 trade panel, right side overlay (T to open): the inbox. Three
	-- incoming rows, each with Accept / Decline / Confirm, plus the
	-- outgoing list and a hint for how to send an offer (stand near a
	-- brainrot, press E on it — no wait, offers are sent from here:
	-- type a player's name, then click a brainrot of yours and one of
	-- theirs in the world; the panel walks you through it).
	tradeFrame = Instance.new("Frame")
	tradeFrame.Name = "Trade"
	tradeFrame.AnchorPoint = Vector2.new(1, 0)
	tradeFrame.Position = UDim2.new(1, -16, 0, 130)
	tradeFrame.Size = UDim2.new(0, 300, 0, 470)
	tradeFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	tradeFrame.BackgroundTransparency = 0.1
	tradeFrame.BorderSizePixel = 0
	tradeFrame.Visible = false
	local tradeCorner = Instance.new("UICorner")
	tradeCorner.CornerRadius = UDim.new(0, 12)
	tradeCorner.Parent = tradeFrame
	tradeFrame.Parent = gui
	local tradeTitle = label(tradeFrame, "TradeTitle", "TRADING  (T to close)", 24, Color3.fromRGB(120, 255, 140))
	tradeTitle.Position = UDim2.new(0, 0, 0, 8)
	tradeTitle.Size = UDim2.new(1, 0, 0, 32)
	tradeTitle.Parent = tradeFrame
	tradeHintLabel = label(tradeFrame, "TradeHint", "No offers yet — walk up to a brainrot and press E to offer it!", 16, Color3.fromRGB(200, 220, 255))
	tradeHintLabel.Position = UDim2.new(0, 12, 0, 44)
	tradeHintLabel.Size = UDim2.new(1, -24, 0, 40)
	tradeHintLabel.TextWrapped = true
	tradeHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	tradeHintLabel.Parent = tradeFrame
	for i = 1, 3 do
		local row = Instance.new("Frame")
		row.Name = "TradeRow" .. tostring(i)
		row.Position = UDim2.new(0, 12, 0, 92 + (i - 1) * 118)
		row.Size = UDim2.new(1, -24, 0, 110)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.BorderSizePixel = 0
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row
		row.Parent = tradeFrame
		local info = label(row, "TradeInfo", "—", 15)
		info.Position = UDim2.new(0, 8, 0, 4)
		info.Size = UDim2.new(1, -16, 0, 52)
		info.TextWrapped = true
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.Parent = row
		tradeIncomingLabels[i] = info
		local accept = Instance.new("TextButton")
		accept.Name = "TradeAccept" .. tostring(i)
		accept.Position = UDim2.new(0, 8, 0, 60)
		accept.Size = UDim2.new(0, 82, 0, 40)
		accept.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
		accept.Text = "ACCEPT"
		accept.TextColor3 = Color3.fromRGB(255, 255, 255)
		accept.TextSize = 15
		accept.Font = Enum.Font.FredokaOne
		accept.Parent = row
		local decline = Instance.new("TextButton")
		decline.Name = "TradeDecline" .. tostring(i)
		decline.Position = UDim2.new(0, 98, 0, 60)
		decline.Size = UDim2.new(0, 82, 0, 40)
		decline.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		decline.Text = "DECLINE"
		decline.TextColor3 = Color3.fromRGB(255, 255, 255)
		decline.TextSize = 15
		decline.Font = Enum.Font.FredokaOne
		decline.Parent = row
		local confirm = Instance.new("TextButton")
		confirm.Name = "TradeConfirm" .. tostring(i)
		confirm.Position = UDim2.new(0, 188, 0, 60)
		confirm.Size = UDim2.new(0, 80, 0, 40)
		confirm.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
		confirm.Text = "CONFIRM"
		confirm.TextColor3 = Color3.fromRGB(255, 255, 255)
		confirm.TextSize = 15
		confirm.Font = Enum.Font.FredokaOne
		confirm.Parent = row
		tradeRowButtons[i] = { accept = accept, decline = decline, confirm = confirm }
	end
	-- The offer sender: type the other player's name, then press E on
	-- one of your brainrots and one of theirs to pick the two sides,
	-- then SEND OFFER. The server validates both sides before the
	-- offer ever reaches the inbox.
	tradeTargetBox = Instance.new("TextBox")
	tradeTargetBox.Name = "TradeTargetBox"
	tradeTargetBox.PlaceholderText = "Player name to trade with"
	tradeTargetBox.Position = UDim2.new(0, 12, 0, 448)
	tradeTargetBox.Size = UDim2.new(1, -24, 0, 32)
	tradeTargetBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	tradeTargetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	tradeTargetBox.TextSize = 16
	tradeTargetBox.Font = Enum.Font.FredokaOne
	tradeTargetBox.Parent = tradeFrame
	tradeFrame.Size = UDim2.new(0, 300, 0, 540)
	tradeSendButton = Instance.new("TextButton")
	tradeSendButton.Name = "TradeSend"
	tradeSendButton.Position = UDim2.new(0, 12, 0, 486)
	tradeSendButton.Size = UDim2.new(1, -24, 0, 36)
	tradeSendButton.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
	tradeSendButton.Text = "SEND OFFER"
	tradeSendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	tradeSendButton.TextSize = 16
	tradeSendButton.Font = Enum.Font.FredokaOne
	tradeSendButton.Parent = tradeFrame

	-- v3 raid bar, top-center under the title: the boss's name, a red
	-- HP bar, the timer, your damage and share, and the top 3 hitters.
	-- It hides itself between raids (the snapshot says active=false).
	raidFrame = Instance.new("Frame")
	raidFrame.Name = "RaidBar"
	raidFrame.AnchorPoint = Vector2.new(0.5, 0)
	raidFrame.Position = UDim2.new(0.5, 0, 0, 64)
	raidFrame.Size = UDim2.new(0, 420, 0, 108)
	raidFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	raidFrame.BackgroundTransparency = 0.1
	raidFrame.BorderSizePixel = 0
	raidFrame.Visible = false
	local raidCorner = Instance.new("UICorner")
	raidCorner.CornerRadius = UDim.new(0, 12)
	raidCorner.Parent = raidFrame
	raidFrame.Parent = gui
	raidBossLabel = label(raidFrame, "RaidBoss", "BOSS RAID", 20, Color3.fromRGB(255, 80, 80))
	raidBossLabel.Position = UDim2.new(0, 0, 0, 6)
	raidBossLabel.Size = UDim2.new(1, 0, 0, 26)
	raidBossLabel.Parent = raidFrame
	local raidHpBack = Instance.new("Frame")
	raidHpBack.Name = "RaidHpBack"
	raidHpBack.Position = UDim2.new(0, 12, 0, 36)
	raidHpBack.Size = UDim2.new(1, -24, 0, 18)
	raidHpBack.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
	raidHpBack.BorderSizePixel = 0
	raidHpBack.Parent = raidFrame
	raidHpFill = Instance.new("Frame")
	raidHpFill.Name = "RaidHpFill"
	raidHpFill.Size = UDim2.new(1, 0, 1, 0)
	raidHpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	raidHpFill.BorderSizePixel = 0
	raidHpFill.Parent = raidHpBack
	raidTimerLabel = label(raidFrame, "RaidTimer", "5:00 left", 16, Color3.fromRGB(255, 215, 0))
	raidTimerLabel.Position = UDim2.new(0, 12, 0, 58)
	raidTimerLabel.Size = UDim2.new(1, -24, 0, 20)
	raidTimerLabel.Parent = raidFrame
	raidMyLabel = label(raidFrame, "RaidMine", "Your damage: 0 (0%)", 16, Color3.fromRGB(120, 255, 140))
	raidMyLabel.Position = UDim2.new(0, 12, 0, 78)
	raidMyLabel.Size = UDim2.new(1, -24, 0, 20)
	raidMyLabel.Parent = raidFrame
	for i = 1, 3 do
		local topRow = label(raidFrame, "RaidTop" .. tostring(i), "", 14, Color3.fromRGB(200, 220, 255))
		topRow.Position = UDim2.new(0, 12, 0, 78 + i * 0)
		topRow.Size = UDim2.new(0, 0, 0, 0)
		topRow.Visible = false
		topRow.Parent = raidFrame
		raidTopLabels[i] = topRow
	end

	-- v3 minigame panel, right side under the top bar: the coin rush
	-- status, your score and best, and the best-score board. It shows
	-- only while a rush is running (or just ended, with the board).
	minigameFrame = Instance.new("Frame")
	minigameFrame.Name = "Minigame"
	minigameFrame.AnchorPoint = Vector2.new(1, 0)
	minigameFrame.Position = UDim2.new(1, -16, 0, 76)
	minigameFrame.Size = UDim2.new(0, 300, 0, 170)
	minigameFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	minigameFrame.BackgroundTransparency = 0.1
	minigameFrame.BorderSizePixel = 0
	minigameFrame.Visible = false
	local minigameCorner = Instance.new("UICorner")
	minigameCorner.CornerRadius = UDim.new(0, 12)
	minigameCorner.Parent = minigameFrame
	minigameFrame.Parent = gui
	local minigameTitle = label(minigameFrame, "MinigameTitle", "COIN RUSH!", 24, Color3.fromRGB(255, 215, 0))
	minigameTitle.Position = UDim2.new(0, 0, 0, 8)
	minigameTitle.Size = UDim2.new(1, 0, 0, 32)
	minigameTitle.Parent = minigameFrame
	minigameStatusLabel = label(minigameFrame, "MinigameStatus", "Click the gold coins around the fountain!", 16, Color3.fromRGB(200, 220, 255))
	minigameStatusLabel.Position = UDim2.new(0, 12, 0, 44)
	minigameStatusLabel.Size = UDim2.new(1, -24, 0, 26)
	minigameStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	minigameStatusLabel.Parent = minigameFrame
	minigameScoreLabel = label(minigameFrame, "MinigameScore", "Coins: 0  ·  Best: 0", 16, Color3.fromRGB(120, 255, 140))
	minigameScoreLabel.Position = UDim2.new(0, 12, 0, 72)
	minigameScoreLabel.Size = UDim2.new(1, -24, 0, 26)
	minigameScoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	minigameScoreLabel.Parent = minigameFrame
	minigameTopLabel = label(minigameFrame, "MinigameTop", "", 15, Color3.fromRGB(200, 220, 255))
	minigameTopLabel.Position = UDim2.new(0, 12, 0, 100)
	minigameTopLabel.Size = UDim2.new(1, -24, 0, 60)
	minigameTopLabel.TextWrapped = true
	minigameTopLabel.TextXAlignment = Enum.TextXAlignment.Left
	minigameTopLabel.Parent = minigameFrame

	-- v3 team panel, left side overlay (Y to open): your team, its
	-- members and vault, the deposit box, and the top-5 team board.
	-- A text box takes the team name for create / join.
	teamFrame = Instance.new("Frame")
	teamFrame.Name = "Team"
	teamFrame.AnchorPoint = Vector2.new(0, 0)
	teamFrame.Position = UDim2.new(0, 16, 0, 130)
	teamFrame.Size = UDim2.new(0, 300, 0, 420)
	teamFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	teamFrame.BackgroundTransparency = 0.1
	teamFrame.BorderSizePixel = 0
	teamFrame.Visible = false
	local teamCorner = Instance.new("UICorner")
	teamCorner.CornerRadius = UDim.new(0, 12)
	teamCorner.Parent = teamFrame
	teamFrame.Parent = gui
	local teamTitle = label(teamFrame, "TeamTitle", "TEAMS  (Y to close)", 24, Color3.fromRGB(120, 255, 140))
	teamTitle.Position = UDim2.new(0, 0, 0, 8)
	teamTitle.Size = UDim2.new(1, 0, 0, 32)
	teamTitle.Parent = teamFrame
	teamNameBox = Instance.new("TextBox")
	teamNameBox.Name = "TeamNameBox"
	teamNameBox.PlaceholderText = "Team name (create / join)"
	teamNameBox.Position = UDim2.new(0, 12, 0, 44)
	teamNameBox.Size = UDim2.new(1, -24, 0, 32)
	teamNameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	teamNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamNameBox.TextSize = 16
	teamNameBox.Font = Enum.Font.FredokaOne
	teamNameBox.Parent = teamFrame
	teamCreateButton = Instance.new("TextButton")
	teamCreateButton.Name = "TeamCreate"
	teamCreateButton.Position = UDim2.new(0, 12, 0, 82)
	teamCreateButton.Size = UDim2.new(0, 132, 0, 32)
	teamCreateButton.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
	teamCreateButton.Text = "CREATE ($10K)"
	teamCreateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamCreateButton.TextSize = 15
	teamCreateButton.Font = Enum.Font.FredokaOne
	teamCreateButton.Parent = teamFrame
	teamJoinButton = Instance.new("TextButton")
	teamJoinButton.Name = "TeamJoin"
	teamJoinButton.Position = UDim2.new(1, -144, 0, 82)
	teamJoinButton.Size = UDim2.new(0, 132, 0, 32)
	teamJoinButton.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
	teamJoinButton.Text = "JOIN"
	teamJoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamJoinButton.TextSize = 15
	teamJoinButton.Font = Enum.Font.FredokaOne
	teamJoinButton.Parent = teamFrame
	teamStatusLabel = label(teamFrame, "TeamStatus", "Not on a team yet", 17, Color3.fromRGB(200, 220, 255))
	teamStatusLabel.Position = UDim2.new(0, 12, 0, 122)
	teamStatusLabel.Size = UDim2.new(1, -24, 0, 26)
	teamStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	teamStatusLabel.Parent = teamFrame
	teamMembersLabel = label(teamFrame, "TeamMembers", "", 16, Color3.fromRGB(255, 255, 255))
	teamMembersLabel.Position = UDim2.new(0, 12, 0, 150)
	teamMembersLabel.Size = UDim2.new(1, -24, 0, 52)
	teamMembersLabel.TextWrapped = true
	teamMembersLabel.TextXAlignment = Enum.TextXAlignment.Left
	teamMembersLabel.Parent = teamFrame
	teamVaultLabel = label(teamFrame, "TeamVault", "Vault: $0", 16, Color3.fromRGB(255, 215, 0))
	teamVaultLabel.Position = UDim2.new(0, 12, 0, 206)
	teamVaultLabel.Size = UDim2.new(1, -24, 0, 26)
	teamVaultLabel.TextXAlignment = Enum.TextXAlignment.Left
	teamVaultLabel.Parent = teamFrame
	teamDepositBox = Instance.new("TextBox")
	teamDepositBox.Name = "TeamDepositBox"
	teamDepositBox.PlaceholderText = "Deposit amount (min $100)"
	teamDepositBox.Position = UDim2.new(0, 12, 0, 236)
	teamDepositBox.Size = UDim2.new(1, -24, 0, 32)
	teamDepositBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	teamDepositBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamDepositBox.TextSize = 16
	teamDepositBox.Font = Enum.Font.FredokaOne
	teamDepositBox.Parent = teamFrame
	teamDepositButton = Instance.new("TextButton")
	teamDepositButton.Name = "TeamDeposit"
	teamDepositButton.Position = UDim2.new(0, 12, 0, 274)
	teamDepositButton.Size = UDim2.new(0, 132, 0, 32)
	teamDepositButton.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
	teamDepositButton.Text = "DEPOSIT"
	teamDepositButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamDepositButton.TextSize = 15
	teamDepositButton.Font = Enum.Font.FredokaOne
	teamDepositButton.Parent = teamFrame
	teamLeaveButton = Instance.new("TextButton")
	teamLeaveButton.Name = "TeamLeave"
	teamLeaveButton.Position = UDim2.new(1, -144, 0, 274)
	teamLeaveButton.Size = UDim2.new(0, 132, 0, 32)
	teamLeaveButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	teamLeaveButton.Text = "LEAVE TEAM"
	teamLeaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamLeaveButton.TextSize = 15
	teamLeaveButton.Font = Enum.Font.FredokaOne
	teamLeaveButton.Parent = teamFrame
	teamTopLabel = label(teamFrame, "TeamTop", "No teams yet — found the first one!", 15, Color3.fromRGB(200, 220, 255))
	teamTopLabel.Position = UDim2.new(0, 12, 0, 314)
	teamTopLabel.Size = UDim2.new(1, -24, 0, 96)
	teamTopLabel.TextWrapped = true
	teamTopLabel.TextXAlignment = Enum.TextXAlignment.Left
	teamTopLabel.Parent = teamFrame

	-- Wire the remotes to the HUD.
	remotes.Announce.OnClientEvent:Connect(function(text)
		Hud.toast(text)
	end)
	remotes.EventBanner.OnClientEvent:Connect(function(text)
		Hud.banner(text)
	end)
	remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
		Hud.update(snapshot)
	end)
	-- v2: the server's top-5 broadcast fills the leaderboard panel.
	remotes.LeaderboardUpdate.OnClientEvent:Connect(function(rows)
		Hud.updateLeaderboard(rows)
	end)
end

-- v2: fill the leaderboard panel from the server's top-5 broadcast.
function Hud.updateLeaderboard(rows)
	for i, row in ipairs(leaderboardRows) do
		local entry = rows and rows[i]
		if entry then
			row.Text = tostring(i) .. ". " .. entry.name .. "  ·  " .. Utils.formatMoney(entry.earned) .. "  ·  " .. Utils.formatRate(entry.bestIncome)
		else
			row.Text = tostring(i) .. ". —"
		end
	end
end

-- v2.5: toggle the pets panel (P) and the quests panel (J).
function Hud.togglePets()
	petsFrame.Visible = not petsFrame.Visible
	if petsFrame.Visible then
		questsFrame.Visible = false
	end
end

function Hud.toggleQuests()
	questsFrame.Visible = not questsFrame.Visible
	if questsFrame.Visible then
		petsFrame.Visible = false
	end
end

-- v2.5: the buy/equip button for one pet (Game.client wires the click).
function Hud.petButton(petId)
	return petButtons[petId]
end

-- v3: toggle the trade panel (T) and the team panel (Y). Opening one
-- closes the other overlays, like the pets / quests pair does.
function Hud.toggleTrade()
	tradeFrame.Visible = not tradeFrame.Visible
	if tradeFrame.Visible then
		teamFrame.Visible = false
		petsFrame.Visible = false
		questsFrame.Visible = false
	end
end

function Hud.toggleTeam()
	teamFrame.Visible = not teamFrame.Visible
	if teamFrame.Visible then
		tradeFrame.Visible = false
		petsFrame.Visible = false
		questsFrame.Visible = false
	end
end

function Hud.tradeVisible()
	return tradeFrame.Visible
end

function Hud.teamVisible()
	return teamFrame.Visible
end

-- v3: the three buttons of one incoming trade row, by row index 1-3
-- (Game.client wires the clicks to TradeRespond / TradeConfirm).
function Hud.tradeRowButtons(rowIndex)
	return tradeRowButtons[rowIndex]
end

function Hud.tradeSendButton()
	return tradeSendButton
end

function Hud.tradeTargetBox()
	return tradeTargetBox
end

function Hud.teamNameBox()
	return teamNameBox
end

function Hud.teamDepositBox()
	return teamDepositBox
end

function Hud.teamCreateButton()
	return teamCreateButton
end

function Hud.teamJoinButton()
	return teamJoinButton
end

function Hud.teamLeaveButton()
	return teamLeaveButton
end

function Hud.teamDepositButton()
	return teamDepositButton
end

-- v3: refresh the trade inbox from the snapshot's trade table. Each
-- incoming row shows who offers what for what, the cash sweetener and
-- fee, and whether each side has confirmed; ACCEPT / DECLINE / CONFIRM
-- read from the same row, so a row is one offer end to end.
function Hud.updateTrade(trade)
	if not trade then
		return
	end
	local incoming = trade.incoming or {}
	if #incoming == 0 and #(trade.outgoing or {}) == 0 then
		tradeHintLabel.Text = "No offers yet — type a player's name below, pick two brainrots with E, then SEND OFFER!"
	else
		tradeHintLabel.Text = tostring(#incoming) .. " incoming, " .. tostring(#(trade.outgoing or {})) .. " outgoing — your stock: " .. tostring(trade.ownCount or 0) .. " brainrots."
	end
	for i = 1, 3 do
		local offer = incoming[i]
		local info = tradeIncomingLabels[i]
		local buttons = tradeRowButtons[i]
		if info and buttons then
			if offer then
				local confirmState = ""
				if offer.fromConfirmed and offer.toConfirmed then
					confirmState = " — BOTH CONFIRMED!"
				elseif offer.toConfirmed then
					confirmState = " — you accepted, waiting for them."
				else
					confirmState = " — awaiting your answer."
				end
				info.Text = offer.from .. " offers " .. offer.offeredName .. " (" .. offer.offeredRarity .. ", " .. Utils.formatRate(offer.offeredRate) .. ") for your " .. offer.wantedName .. " (" .. offer.wantedRarity .. ", " .. Utils.formatRate(offer.wantedRate) .. ")"
				if offer.cash > 0 then
					info.Text ..= " + " .. Utils.formatMoney(offer.cash) .. " cash (fee " .. Utils.formatMoney(offer.fee) .. ")"
				end
				info.Text ..= confirmState .. " Expires in " .. Utils.formatDuration(offer.expiresIn) .. "."
				buttons.accept.Visible = not offer.toConfirmed
				buttons.decline.Visible = true
				buttons.confirm.Visible = offer.toConfirmed
			else
				info.Text = "—"
				buttons.accept.Visible = false
				buttons.decline.Visible = false
				buttons.confirm.Visible = false
			end
		end
	end
end

-- v3: refresh the raid bar from the snapshot's raid table. Hidden
-- between raids; while a raid runs it shows the boss name, the HP
-- bar as a fraction, the timer, your damage and share, and the top 3.
function Hud.updateRaid(raid)
	if not raid then
		return
	end
	raidFrame.Visible = raid.active == true
	if not raid.active then
		return
	end
	raidBossLabel.Text = "BOSS RAID #" .. tostring(raid.raidNumber or 0) .. ": " .. (raid.bossName or "Boss")
	local frac = 1
	if (raid.maxHp or 0) > 0 then
		frac = Utils.clamp((raid.hp or 0) / raid.maxHp, 0, 1)
	end
	raidHpFill.Size = UDim2.new(frac, 0, 1, 0)
	raidTimerLabel.Text = "HP " .. tostring(raid.hp or 0) .. " / " .. tostring(raid.maxHp or 0) .. "  ·  " .. Utils.formatDuration(raid.timeLeft or 0) .. " left  ·  Press F near the pad to fight!"
	raidMyLabel.Text = "Your damage: " .. tostring(raid.myDamage or 0) .. " (" .. Utils.formatPercent(raid.myShare or 0) .. " of the reward pool)"
end

-- v3: refresh the minigame panel from the snapshot's minigame table.
-- Visible while a rush runs; the board stays for the rush that just
-- ended, so the winner sees their name on it.
function Hud.updateMinigame(minigame)
	if not minigame then
		return
	end
	minigameFrame.Visible = minigame.active == true or (minigame.myScore or 0) > 0
	if not minigameFrame.Visible then
		return
	end
	if minigame.active then
		minigameStatusLabel.Text = "COIN RUSH #" .. tostring(minigame.rushNumber or 0) .. " — " .. Utils.formatDuration(minigame.timeLeft or 0) .. " left, " .. tostring(minigame.coinsLeft or 0) .. " coins on the ring!"
	else
		minigameStatusLabel.Text = "Rush over — your best rush: " .. tostring(minigame.myBest or 0) .. " coins."
	end
	minigameScoreLabel.Text = "Coins: " .. tostring(minigame.myScore or 0) .. "  ·  Best: " .. tostring(minigame.myBest or 0)
	local lines = {}
	for i, row in ipairs(minigame.top or {}) do
		table.insert(lines, tostring(i) .. ". " .. row.name .. " — " .. tostring(row.best) .. " coins")
	end
	if #lines == 0 then
		minigameTopLabel.Text = "No scores yet — be the first to collect a coin!"
	else
		minigameTopLabel.Text = table.concat(lines, "\n")
	end
end

-- v3: refresh the team panel from the snapshot's team table. Shows
-- your team (name, leader, members, vault, hourly pay) or the
-- not-on-a-team state, plus the top-5 team board by earnings.
function Hud.updateTeam(teamData)
	if not teamData then
		return
	end
	local mine = teamData.team
	if mine then
		teamStatusLabel.Text = "Team " .. mine.name .. " (leader: " .. mine.leader .. ")"
		teamMembersLabel.Text = "Members (" .. tostring(#mine.members) .. "/" .. tostring(teamData.maxMembers or 5) .. "): " .. table.concat(mine.members, ", ")
		teamVaultLabel.Text = "Vault: " .. Utils.formatMoney(mine.vault) .. "  ·  Pays " .. Utils.formatMoney(mine.hourly or 500) .. "/member/hour  ·  Team earned " .. Utils.formatMoney(mine.earned)
	else
		teamStatusLabel.Text = "Not on a team yet — create one for " .. Utils.formatMoney(teamData.createCost or 10000) .. " or join one below."
		teamMembersLabel.Text = ""
		teamVaultLabel.Text = "Vault: —"
	end
	local lines = {}
	for i, row in ipairs(teamData.top or {}) do
		table.insert(lines, tostring(i) .. ". " .. row.name .. " — " .. Utils.formatMoney(row.earned) .. " earned, " .. tostring(row.members) .. " members, vault " .. Utils.formatMoney(row.vault))
	end
	if #lines == 0 then
		teamTopLabel.Text = "No teams yet — found the first one!"
	else
		teamTopLabel.Text = "TOP TEAMS:\n" .. table.concat(lines, "\n")
	end
end

-- v2.5: the claim button for one of today's three quests, by index 1-3.
function Hud.questClaimButton(questIndex)
	return questClaimButtons[questIndex]
end

-- v2.5: refresh the pets panel from the snapshot's pets table. Owned
-- pets show EQUIP (or FOLLOWING for the active one); unowned ones keep
-- their price, so the button is both the shop and the equip list.
function Hud.updatePets(pets)
	if not pets then
		return
	end
	local owned = {}
	for _, petId in ipairs(pets.owned or {}) do
		owned[petId] = true
	end
	local activeName = "No pet following you"
	if pets.active and pets.active ~= "" then
		for _, pet in ipairs(Config.PETS) do
			if pet.id == pets.active then
				activeName = pet.name .. " is following you"
				break
			end
		end
	end
	activePetLabel.Text = activeName
	local pct = math.floor(((pets.multiplier or 1) - 1) * 100 + 0.5)
	petsSummaryLabel.Text = tostring(pets.count or 0) .. " of " .. tostring(pets.total or 6) .. " pets (+" .. tostring(pct) .. "% income)"
	for _, pet in ipairs(Config.PETS) do
		local btn = petButtons[pet.id]
		if btn then
			if pets.active == pet.id then
				btn.Text = pet.name .. "  ·  FOLLOWING\n" .. pet.desc
				btn.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
			elseif owned[pet.id] then
				btn.Text = pet.name .. "  ·  OWNED — click to equip\n" .. pet.desc
				btn.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
			else
				btn.Text = pet.name .. "  ·  " .. Utils.formatMoney(pet.cost) .. "\n" .. pet.desc
				btn.BackgroundColor3 = Color3.fromRGB(90, 60, 140)
			end
		end
	end
end

-- v2.5: refresh the quests panel from the snapshot's quests table. Each
-- row shows its title, live progress, and a claim button that reads
-- CLAIM (ready), CLAIMED (paid), or the remaining progress.
function Hud.updateQuests(questData)
	if not questData or not questData.quests then
		return
	end
	questSummaryLabel.Text = tostring(questData.done or 0) .. " of 3 quests done  ·  " .. tostring(questData.claimed or 0) .. " claimed"
	for i, quest in ipairs(questData.quests) do
		local row = questsFrame:FindFirstChild("QuestRow" .. tostring(i))
		local progress = questProgressLabels[i]
		local claim = questClaimButtons[i]
		if row and progress and claim then
			local titleLabel = row:FindFirstChild("QuestTitle")
			if titleLabel then
				titleLabel.Text = quest.title
			end
			progress.Text = Utils.formatMoney(quest.progress) .. " / " .. Utils.formatMoney(quest.target) .. "  (" .. tostring(math.floor((quest.frac or 0) * 100 + 0.5)) .. "%)"
			if quest.kind == "buy" or quest.kind == "steal" then
				progress.Text = tostring(quest.progress) .. " / " .. tostring(quest.target) .. "  (" .. tostring(math.floor((quest.frac or 0) * 100 + 0.5)) .. "%)"
			end
			if quest.claimed then
				claim.Text = "CLAIMED +" .. Utils.formatMoney(quest.reward)
				claim.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
			elseif quest.done then
				claim.Text = "CLAIM +" .. Utils.formatMoney(quest.reward)
				claim.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
			else
				claim.Text = "NOT DONE YET"
				claim.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
			end
		end
	end
end

function Hud.update(snapshot)
	cashLabel.Text = Utils.formatMoney(snapshot.cash)
	incomeLabel.Text = Utils.formatRate(snapshot.income)
	countLabel.Text = tostring(snapshot.count) .. " brainrots"
	rebirthLabel.Text = "Rebirth x" .. tostring(Config.REBIRTH_MULTIPLIER ^ snapshot.rebirths)
	-- v2: personal stats from the snapshot (bought / steals / best $/s).
	statsLabel.Text = "Bought " .. tostring(snapshot.bought or 0) .. "  ·  Steals " .. tostring(snapshot.steals or 0) .. "  ·  Slaps " .. tostring(snapshot.slaps or 0) .. "  ·  Best " .. Utils.formatRate(snapshot.bestIncome or 0)
	eventChip.Visible = snapshot.eventMult > 1
	rebirthProgress.Text = "Earned " .. Utils.formatMoney(snapshot.totalEarned) .. " / " .. Utils.formatMoney(snapshot.rebirthCost) .. " to rebirth"
	-- v2.5: pets and quests panels refresh from the same snapshot.
	Hud.updatePets(snapshot.pets)
	Hud.updateQuests(snapshot.quests)
	-- v3: trade, raid, minigame and team panels refresh from the same
	-- snapshot, through the same once-a-second heartbeat.
	Hud.updateTrade(snapshot.trade)
	Hud.updateRaid(snapshot.raid)
	Hud.updateMinigame(snapshot.minigame)
	Hud.updateTeam(snapshot.team)
	-- Rebuild the collection list from the snapshot.
	for _, child in ipairs(collectionList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if #snapshot.owned == 0 then
		local empty = label(collectionList, "Empty", "No brainrots yet — buy one off the conveyor!", 18, Color3.fromRGB(200, 200, 200))
		empty.Size = UDim2.new(1, 0, 0, 48)
		empty.TextWrapped = true
		empty.Parent = collectionList
	else
		for _, owned in ipairs(snapshot.owned) do
			local row = label(collectionList, "Row", owned.name .. "  ·  " .. owned.rarity .. "  ·  " .. Utils.formatRate(owned.rate), 18)
			row.Size = UDim2.new(1, 0, 0, 26)
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Parent = collectionList
		end
	end
end

function Hud.setPrompt(text)
	promptLabel.Text = text
end

function Hud.toggleShop()
	shopFrame.Visible = not shopFrame.Visible
end

function Hud.shopButton(itemId)
	return shopFrame:FindFirstChild("Shop_" .. itemId)
end

function Hud.rebirthButton()
	return rebirthButton
end

function Hud.toast(text)
	table.insert(toastQueue, text)
	if toastBusy then
		return
	end
	toastBusy = true
	task.spawn(function()
		while #toastQueue > 0 do
			local nextText = table.remove(toastQueue, 1)
			toastLabel.Text = nextText
			toastLabel.Visible = true
			task.wait(3)
			toastLabel.Visible = false
		end
		toastBusy = false
	end)
end

function Hud.banner(text)
	bannerLabel.Text = text
	bannerLabel.Visible = true
	task.delay(5, function()
		bannerLabel.Visible = false
	end)
end

return Hud
