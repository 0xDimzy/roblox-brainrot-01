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

function WorldBuilder.pedestalPosition(plotIndex, pedestalIndex)
	local plotPos = Config.PLOT_POSITIONS[plotIndex]
	local off = PEDESTAL_OFFSETS[pedestalIndex]
	return plotPos + off + Vector3.new(0, 2.5, 0)
end

return WorldBuilder
