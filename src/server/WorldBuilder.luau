-- Brainrot Boulevard: builds the plaza's decoration at runtime — trees,
-- lamps, stalls, plot fences and pedestals, the sign, and the tsunami wave
-- that EventService sweeps across the map. The static ground, conveyor and
-- plot pads live in default.project.json; this adds the life on top.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

local function newPart(name, size, color, material, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function treeAt(parent, pos)
	local trunk = newPart("TreeTrunk", Vector3.new(1.2, 5, 1.2), Color3.fromRGB(120, 72, 20), Enum.Material.Wood)
	trunk.Position = pos + Vector3.new(0, 2.5, 0)
	trunk.CanCollide = true
	trunk.Parent = parent
	local leaves = newPart("TreeLeaves", Vector3.new(5, 4, 5), Color3.fromRGB(60, 180, 80), Enum.Material.SmoothPlastic)
	leaves.Shape = Enum.PartType.Ball
	leaves.Position = pos + Vector3.new(0, 6.5, 0)
	leaves.Parent = parent
end

local function lampAt(parent, pos)
	local pole = newPart("LampPole", Vector3.new(0.5, 7, 0.5), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	pole.Position = pos + Vector3.new(0, 3.5, 0)
	pole.Parent = parent
	local bulb = newPart("LampBulb", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
	bulb.Position = pos + Vector3.new(0, 7.4, 0)
	bulb.Parent = parent
end

local function stallAt(parent, pos, color)
	local counter = newPart("StallCounter", Vector3.new(8, 2.5, 4), color, Enum.Material.Wood)
	counter.Position = pos + Vector3.new(0, 1.25, 0)
	counter.CanCollide = true
	counter.Parent = parent
	local roof = newPart("StallRoof", Vector3.new(9, 0.6, 5), Color3.fromRGB(255, 255, 255))
	roof.Position = pos + Vector3.new(0, 6, 0)
	roof.Parent = parent
	local postA = newPart("StallPost", Vector3.new(0.5, 3.5, 0.5), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	postA.Position = pos + Vector3.new(-4, 4.2, -1.8)
	postA.Parent = parent
	local postB = newPart("StallPost", Vector3.new(0.5, 3.5, 0.5), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	postB.Position = pos + Vector3.new(4, 4.2, -1.8)
	postB.Parent = parent
end

-- Six pedestals per plot, two rows of three, where owned brainrots stand.
local PEDESTAL_OFFSETS = {
	Vector3.new(-7, 0, -4),
	Vector3.new(0, 0, -4),
	Vector3.new(7, 0, -4),
	Vector3.new(-7, 0, 4),
	Vector3.new(0, 0, 4),
	Vector3.new(7, 0, 4),
}

function WorldBuilder.build(workspace)
	local decor = Instance.new("Folder")
	decor.Name = "BoulevardDecor"
	decor.Parent = workspace

	-- Trees ringing the plaza.
	for _, x in ipairs({ -85, -45, 45, 85 }) do
		treeAt(decor, Vector3.new(x, 1, -70))
		treeAt(decor, Vector3.new(x, 1, 70))
	end
	-- Lamps along the conveyor.
	for _, x in ipairs({ -50, -25, 0, 25, 50 }) do
		lampAt(decor, Vector3.new(x, 1, -32))
	end
	-- Two market stalls flanking the spawn.
	stallAt(decor, Vector3.new(-30, 1, 42), Color3.fromRGB(255, 107, 107))
	stallAt(decor, Vector3.new(30, 1, 42), Color3.fromRGB(93, 173, 226))

	-- The boulevard sign over the conveyor's spawn gate.
	local signPost = newPart("SignPost", Vector3.new(1, 10, 1), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	signPost.Position = Vector3.new(-66, 6, -25)
	signPost.Parent = decor
	local signBoard = newPart("SignBoard", Vector3.new(1, 6, 16), Color3.fromRGB(255, 195, 0), Enum.Material.Wood)
	signBoard.Position = Vector3.new(-66, 11, -25)
	signBoard.Parent = decor
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Right
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "BRAINROT\nBOULEVARD"
	signText.TextColor3 = Color3.fromRGB(40, 40, 40)
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui

	-- Pedestals and low fences for every plot.
	for i, plotPos in ipairs(Config.PLOT_POSITIONS) do
		local plotColor = Config.PLOT_COLORS[i]
		for j, off in ipairs(PEDESTAL_OFFSETS) do
			local ped = newPart("Pedestal" .. j, Vector3.new(4, 1, 4), plotColor, Enum.Material.Neon)
			ped.Position = plotPos + off + Vector3.new(0, 0.5, 0)
			ped:SetAttribute("PlotIndex", i)
			ped:SetAttribute("PedestalIndex", j)
			ped.Parent = decor
		end
		-- A fence post at each plot corner so a base reads as a base.
		for _, corner in ipairs({
			Vector3.new(-11, 0, -8),
			Vector3.new(11, 0, -8),
			Vector3.new(-11, 0, 8),
			Vector3.new(11, 0, 8),
		}) do
			local post = newPart("FencePost", Vector3.new(0.8, 3, 0.8), plotColor, Enum.Material.Wood)
			post.Position = plotPos + corner + Vector3.new(0, 1.5, 0)
			post.Parent = decor
		end
	end

	-- The tsunami wave, parked off-map until EventService sweeps it.
	local wave = newPart("TsunamiWave", Vector3.new(6, 26, 190), Color3.fromRGB(40, 140, 255), Enum.Material.Glass)
	wave.Transparency = 0.35
	wave.Position = Vector3.new(-130, 13, 0)
	wave:SetAttribute("IsWave", true)
	wave.Parent = workspace
	WorldBuilder.Wave = wave

	-- v2.5: the pet park (east corner, by the spawn) and the quest board
	-- (west of the spawn pad) — the two new systems' homes in the world.
	WorldBuilder.buildPetPark(decor)
	WorldBuilder.buildQuestBoard(decor)

	-- v3: the Sky Plaza (12 plots now — 4 float at y=40, earning +25%),
	-- the raid pad south of the spawn, the trading post, and the coin
	-- rush ring around the fountain. Each new system gets a home.
	WorldBuilder.buildSkyPlaza(decor)
	WorldBuilder.buildRaidPad(decor)
	WorldBuilder.buildTradeStall(decor)
	WorldBuilder.buildMinigameRing(decor)

	-- Drifting clouds for the sky.
	for i, cloudPos in ipairs({
		Vector3.new(-60, 55, -50),
		Vector3.new(20, 60, -70),
		Vector3.new(70, 52, 40),
		Vector3.new(-30, 58, 60),
	}) do
		local cloud = newPart("Cloud" .. i, Vector3.new(24, 4, 12), Color3.fromRGB(255, 255, 255))
		cloud.Position = cloudPos
		cloud.Parent = decor
	end
end

-- v2.5: the pet park — a fenced corner east of the spawn where the six
-- pets live when they are not following a player. Three pet beds, two
-- food bowls, a fence, and a sign. The park's center is exposed as
-- WorldBuilder.PetParkCenter so PetsService and the client agree on it.
WorldBuilder.PetParkCenter = Vector3.new(88, 1, 30)

function WorldBuilder.buildPetPark(decor)
	local center = WorldBuilder.PetParkCenter
	-- The park pad, a soft green square in the east corner.
	local pad = newPart("PetParkPad", Vector3.new(16, 1, 16), Color3.fromRGB(120, 220, 130), Enum.Material.Grass)
	pad.Position = center
	pad.Parent = decor
	-- A low fence around three sides so the park reads as a park.
	for _, offset in ipairs({
		Vector3.new(-7.5, 0, 0),
		Vector3.new(7.5, 0, 0),
		Vector3.new(0, 0, -7.5),
		Vector3.new(0, 0, 7.5),
	}) do
		local fence = newPart("PetParkFence", Vector3.new(15, 2, 0.6), Color3.fromRGB(255, 255, 255), Enum.Material.Wood)
		if math.abs(offset.X) > 0 then
			fence.Size = Vector3.new(0.6, 2, 15)
		end
		fence.Position = center + offset + Vector3.new(0, 1, 0)
		fence.Parent = decor
	end
	-- Three pet beds: a cushion each, in pet colors.
	local bedColors = {
		Color3.fromRGB(220, 200, 140),
		Color3.fromRGB(255, 170, 120),
		Color3.fromRGB(255, 230, 80),
	}
	for i, bedColor in ipairs(bedColors) do
		local bed = newPart("PetBed" .. tostring(i), Vector3.new(3, 0.8, 3), bedColor, Enum.Material.SmoothPlastic)
		bed.Position = center + Vector3.new(-4 + (i - 1) * 4, 1.4, -4)
		bed.Parent = decor
	end
	-- Two food bowls by the fence, always full.
	for i, bowlX in ipairs({ -3, 3 }) do
		local bowl = newPart("PetBowl" .. tostring(i), Vector3.new(2, 1, 2), Color3.fromRGB(200, 60, 60), Enum.Material.Metal)
		bowl.Shape = Enum.PartType.Cylinder
		bowl.Position = center + Vector3.new(bowlX, 1.5, 5)
		bowl.Parent = decor
	end
	-- The sign: PET PARK, so nobody misses it.
	local signPost = newPart("PetParkSignPost", Vector3.new(0.8, 6, 0.8), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	signPost.Position = center + Vector3.new(-7, 3, -7)
	signPost.Parent = decor
	local signBoard = newPart("PetParkSign", Vector3.new(6, 3, 0.6), Color3.fromRGB(255, 195, 0), Enum.Material.Wood)
	signBoard.Position = center + Vector3.new(-7, 6.5, -7)
	signBoard.Parent = decor
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "PET PARK"
	signText.TextColor3 = Color3.fromRGB(40, 40, 40)
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui
end

-- v2.5: the quest board — a big wooden board west of the spawn pad with
-- the day's three quests on it, and the key that opens the quest panel.
-- The board is the world's face for QuestService; the panel (J) is the
-- HUD's face for the same three quests.
WorldBuilder.QuestBoardPosition = Vector3.new(-14, 1, 38)

function WorldBuilder.buildQuestBoard(decor)
	local pos = WorldBuilder.QuestBoardPosition
	local postA = newPart("QuestBoardPostA", Vector3.new(0.8, 7, 0.8), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	postA.Position = pos + Vector3.new(-4, 3.5, 0)
	postA.Parent = decor
	local postB = newPart("QuestBoardPostB", Vector3.new(0.8, 7, 0.8), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	postB.Position = pos + Vector3.new(4, 3.5, 0)
	postB.Parent = decor
	local board = newPart("QuestBoard", Vector3.new(10, 6, 0.6), Color3.fromRGB(200, 160, 90), Enum.Material.Wood)
	board.Position = pos + Vector3.new(0, 5, 0)
	board.Parent = decor
	local boardGui = Instance.new("SurfaceGui")
	boardGui.Face = Enum.NormalId.Front
	boardGui.Parent = board
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.3, 0)
	title.BackgroundTransparency = 1
	title.Text = "DAILY QUESTS"
	title.TextColor3 = Color3.fromRGB(60, 30, 10)
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.Parent = boardGui
	local hint = Instance.new("TextLabel")
	hint.Position = UDim2.new(0, 0, 0.3, 0)
	hint.Size = UDim2.new(1, 0, 0.7, 0)
	hint.BackgroundTransparency = 1
	hint.Text = "Earn, buy and steal\nfor cash rewards!\nPress J to open."
	hint.TextColor3 = Color3.fromRGB(60, 30, 10)
	hint.TextScaled = true
	hint.Font = Enum.Font.FredokaOne
	hint.Parent = boardGui
end

-- v3: the Sky Plaza — a floating district 40 studs up, holding plots
-- 9-12 (same north x/z as plots 1-4, earning +25%). A slab with four
-- corner pillars down to the ground, railings, star lamps, cloud
-- puffs, a return pad back down, and the sky plot pads themselves
-- (the static project file only pads plots 1-8; the sky pads are
-- built here, with their PlotIndex attributes, so the client's
-- on-plot raycast and the pedestal loop both see them).
WorldBuilder.SkyPlazaCenter = Vector3.new(0, 40, -58)
WorldBuilder.SkyLiftPosition = Config.SKY_LIFT_POSITION
WorldBuilder.SkyReturnPosition = Config.SKY_RETURN_POSITION
WorldBuilder.RaidPadPosition = Config.RAID_PAD_POSITION

function WorldBuilder.buildSkyPlaza(decor)
	local center = WorldBuilder.SkyPlazaCenter
	-- The slab: a pale cloud-white platform over the north plots.
	local slab = newPart("SkyPlazaSlab", Vector3.new(110, 1, 50), Color3.fromRGB(230, 240, 255), Enum.Material.SmoothPlastic)
	slab.Position = center + Vector3.new(0, -0.5, 0)
	slab.CanCollide = true
	slab.Parent = decor
	-- Four pillars hold the slab up, one at each corner.
	for _, corner in ipairs({
		Vector3.new(-52, 0, -22),
		Vector3.new(52, 0, -22),
		Vector3.new(-52, 0, 22),
		Vector3.new(52, 0, 22),
	}) do
		local pillar = newPart("SkyPillar", Vector3.new(2, 40, 2), Color3.fromRGB(200, 210, 230), Enum.Material.Metal)
		pillar.Position = center + corner + Vector3.new(0, -20, 0)
		pillar.CanCollide = true
		pillar.Parent = decor
	end
	-- Railings along the slab's south edge so nobody walks off the sky.
	for i = -5, 5 do
		local rail = newPart("SkyRail", Vector3.new(2, 2, 0.6), Color3.fromRGB(255, 195, 0), Enum.Material.Metal)
		rail.Position = center + Vector3.new(i * 10, 1, 24)
		rail.Parent = decor
	end
	-- The four sky plot pads, each with its PlotIndex attribute.
	for i = 9, 12 do
		local plotPos = Config.PLOT_POSITIONS[i]
		local pad = newPart("SkyPlot" .. tostring(i), Vector3.new(24, 1, 18), Config.PLOT_COLORS[i], Enum.Material.Slate)
		pad.Position = plotPos
		pad.CanCollide = true
		pad:SetAttribute("PlotIndex", i)
		pad.Parent = decor
	end
	-- Star lamps: neon posts that mark the plaza's corners at night.
	for _, offset in ipairs({
		Vector3.new(-50, 0, -20),
		Vector3.new(50, 0, -20),
		Vector3.new(-50, 0, 20),
		Vector3.new(50, 0, 20),
	}) do
		local post = newPart("SkyLampPost", Vector3.new(0.6, 5, 0.6), Color3.fromRGB(80, 80, 100), Enum.Material.Metal)
		post.Position = center + offset + Vector3.new(0, 2.5, 0)
		post.Parent = decor
		local star = newPart("SkyLampStar", Vector3.new(2, 2, 2), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		star.Position = center + offset + Vector3.new(0, 5.5, 0)
		star.Parent = decor
	end
	-- Cloud puffs drifting just under the slab's edge.
	for i, offset in ipairs({
		Vector3.new(-40, -4, 26),
		Vector3.new(0, -5, 27),
		Vector3.new(40, -4, 26),
	}) do
		local puff = newPart("SkyCloud" .. tostring(i), Vector3.new(14, 3, 7), Color3.fromRGB(255, 255, 255))
		puff.Position = center + offset
		puff.Parent = decor
	end
	-- The lift pad on the ground (step on it to ride up) and the
	-- return pad on the sky (step on it to ride back down). The
	-- client teleports the player between them; both are neon so
	-- nobody misses the ride.
	local lift = newPart("SkyLiftPad", Vector3.new(8, 1, 8), Color3.fromRGB(140, 220, 255), Enum.Material.Neon)
	lift.Position = WorldBuilder.SkyLiftPosition
	lift.CanCollide = true
	lift:SetAttribute("IsLiftPad", true)
	lift.Parent = decor
	local liftGui = Instance.new("SurfaceGui")
	liftGui.Face = Enum.NormalId.Top
	liftGui.Parent = lift
	local liftText = Instance.new("TextLabel")
	liftText.Size = UDim2.fromScale(1, 1)
	liftText.BackgroundTransparency = 1
	liftText.Text = "SKY LIFT"
	liftText.TextColor3 = Color3.fromRGB(20, 60, 90)
	liftText.TextScaled = true
	liftText.Font = Enum.Font.FredokaOne
	liftText.Parent = liftGui
	local ret = newPart("SkyReturnPad", Vector3.new(8, 1, 8), Color3.fromRGB(140, 220, 255), Enum.Material.Neon)
	ret.Position = WorldBuilder.SkyReturnPosition
	ret.CanCollide = true
	ret:SetAttribute("IsReturnPad", true)
	ret.Parent = decor
	local retGui = Instance.new("SurfaceGui")
	retGui.Face = Enum.NormalId.Top
	retGui.Parent = ret
	local retText = Instance.new("TextLabel")
	retText.Size = UDim2.fromScale(1, 1)
	retText.BackgroundTransparency = 1
	retText.Text = "DOWN"
	retText.TextColor3 = Color3.fromRGB(20, 60, 90)
	retText.TextScaled = true
	retText.Font = Enum.Font.FredokaOne
	retText.Parent = retGui
	-- The sign: SKY PLAZA, +25% income, so the climb sells itself.
	local signBoard = newPart("SkyPlazaSign", Vector3.new(14, 4, 0.6), Color3.fromRGB(255, 195, 0), Enum.Material.Wood)
	signBoard.Position = center + Vector3.new(0, 6, 24)
	signBoard.Parent = decor
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "SKY PLAZA  +25% INCOME"
	signText.TextColor3 = Color3.fromRGB(40, 40, 40)
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui
end

-- v3: the raid pad — a scorched red circle south of the spawn where
-- the hourly boss appears. A ring of warning posts and a sign mark
-- the arena; the boss model itself is spawned by RaidService.
function WorldBuilder.buildRaidPad(decor)
	local center = WorldBuilder.RaidPadPosition
	local pad = newPart("RaidPad", Vector3.new(24, 1, 24), Color3.fromRGB(200, 60, 60), Enum.Material.Slate)
	pad.Position = center
	pad.CanCollide = true
	pad:SetAttribute("IsRaidPad", true)
	pad.Parent = decor
	-- Eight warning posts ring the pad, so the arena reads as an arena.
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local post = newPart("RaidPost" .. tostring(i + 1), Vector3.new(1, 4, 1), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
		post.Position = center + Vector3.new(math.cos(angle) * 13, 2, math.sin(angle) * 13)
		post.Parent = decor
	end
	-- The sign: BOSS RAID, with the key that fights it.
	local signPost = newPart("RaidSignPost", Vector3.new(0.8, 6, 0.8), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	signPost.Position = center + Vector3.new(-12, 3, 0)
	signPost.Parent = decor
	local signBoard = newPart("RaidSign", Vector3.new(8, 3, 0.6), Color3.fromRGB(200, 60, 60), Enum.Material.Wood)
	signBoard.Position = center + Vector3.new(-12, 6.5, 0)
	signBoard.Parent = decor
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "BOSS RAID\nPress F to fight!"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui
end

-- v3: the trading post — a stall west of the spawn with a handshake
-- sign, the world's face for TradeService. The HUD trade panel (T)
-- is the other face; this one is where players meet to deal.
function WorldBuilder.buildTradeStall(decor)
	local pos = Vector3.new(-45, 1, 42)
	local counter = newPart("TradeCounter", Vector3.new(8, 2.5, 4), Color3.fromRGB(60, 200, 120), Enum.Material.Wood)
	counter.Position = pos + Vector3.new(0, 1.25, 0)
	counter.CanCollide = true
	counter.Parent = decor
	local roof = newPart("TradeRoof", Vector3.new(9, 0.6, 5), Color3.fromRGB(255, 255, 255))
	roof.Position = pos + Vector3.new(0, 6, 0)
	roof.Parent = decor
	local postA = newPart("TradePostA", Vector3.new(0.5, 3.5, 0.5), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	postA.Position = pos + Vector3.new(-4, 4.2, -1.8)
	postA.Parent = decor
	local postB = newPart("TradePostB", Vector3.new(0.5, 3.5, 0.5), Color3.fromRGB(90, 60, 30), Enum.Material.Wood)
	postB.Position = pos + Vector3.new(4, 4.2, -1.8)
	postB.Parent = decor
	local signBoard = newPart("TradeSign", Vector3.new(8, 3, 0.6), Color3.fromRGB(60, 200, 120), Enum.Material.Wood)
	signBoard.Position = pos + Vector3.new(0, 7.5, 0)
	signBoard.Parent = decor
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "TRADING POST\nPress T to trade!"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.Parent = signGui
end

-- v3: the minigame ring — eight small gold markers around the
-- fountain, the coin rush's arena. Coins spawn on this ring; the
-- markers show players where to look when the rush starts.
function WorldBuilder.buildMinigameRing(decor)
	local center = Config.MINIGAME_RING_CENTER
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local marker = newPart("CoinRingMarker" .. tostring(i + 1), Vector3.new(1.5, 0.5, 1.5), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		marker.Position = center + Vector3.new(math.cos(angle) * Config.MINIGAME_RING_RADIUS, 0.5, math.sin(angle) * Config.MINIGAME_RING_RADIUS)
		marker.Parent = decor
	end
end

function WorldBuilder.pedestalPosition(plotIndex, pedestalIndex)
	local plotPos = Config.PLOT_POSITIONS[plotIndex]
	local off = PEDESTAL_OFFSETS[pedestalIndex]
	return plotPos + off + Vector3.new(0, 2.5, 0)
end

return WorldBuilder
