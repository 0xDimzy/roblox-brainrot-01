-- Brainrot Boulevard: the whole interface, built in code. Top bar with cash,
-- income, collection and rebirths; a bottom prompt; toasts; the event
-- banner; the shop; the rebirth button; the collection list; and the v2
-- leaderboard panel (top earners) plus a personal stats line.

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
	local hint = label(gui, "Hint", "WASD move  ·  E interact  ·  Q shop  ·  Click to slap thieves", 18, Color3.fromRGB(220, 220, 220))
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

function Hud.update(snapshot)
	cashLabel.Text = Utils.formatMoney(snapshot.cash)
	incomeLabel.Text = Utils.formatRate(snapshot.income)
	countLabel.Text = tostring(snapshot.count) .. " brainrots"
	rebirthLabel.Text = "Rebirth x" .. tostring(Config.REBIRTH_MULTIPLIER ^ snapshot.rebirths)
	-- v2: personal stats from the snapshot (bought / steals / best $/s).
	statsLabel.Text = "Bought " .. tostring(snapshot.bought or 0) .. "  ·  Steals " .. tostring(snapshot.steals or 0) .. "  ·  Slaps " .. tostring(snapshot.slaps or 0) .. "  ·  Best " .. Utils.formatRate(snapshot.bestIncome or 0)
	eventChip.Visible = snapshot.eventMult > 1
	rebirthProgress.Text = "Earned " .. Utils.formatMoney(snapshot.totalEarned) .. " / " .. Utils.formatMoney(snapshot.rebirthCost) .. " to rebirth"
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
