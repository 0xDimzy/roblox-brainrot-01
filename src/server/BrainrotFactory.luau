-- Brainrot Boulevard: builds the 3D brainrot characters out of parts, and
-- the slap tool every player spawns with. No uploaded assets: body, head,
-- eyes and a name billboard, tinted by the character and its mutation.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Utils = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Utils"))

local BrainrotFactory = {}

local function part(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- A chunky meme creature: body, head, eyes, feet, arms, and a floating
-- billboard with its name, rarity and $/s. PrimaryPart is the body.
function BrainrotFactory.createBrainrot(def, mutationIndex)
	local mutation = BrainrotData.mutationOf(mutationIndex)
	local bodyColor = def.color
	if mutation.tint then
		bodyColor = mutation.tint
	end

	local model = Instance.new("Model")
	model.Name = BrainrotData.displayName(def, mutationIndex)

	local body = part("Body", Vector3.new(2.4, 2, 1.6), bodyColor)
	body.Material = Enum.Material.Neon
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	local head = part("Head", Vector3.new(1.9, 1.6, 1.6), bodyColor)
	head.Position = Vector3.new(0, 1.8, 0)
	head.Parent = model

	local eyeColor = Color3.fromRGB(20, 20, 20)
	local eyeL = part("EyeL", Vector3.new(0.35, 0.5, 0.2), eyeColor)
	eyeL.Position = Vector3.new(-0.45, 1.9, 0.85)
	eyeL.Parent = model
	local eyeR = part("EyeR", Vector3.new(0.35, 0.5, 0.2), eyeColor)
	eyeR.Position = Vector3.new(0.45, 1.9, 0.85)
	eyeR.Parent = model

	local footL = part("FootL", Vector3.new(0.7, 0.5, 1), Color3.fromRGB(40, 40, 40))
	footL.Position = Vector3.new(-0.6, -1.2, 0)
	footL.Parent = model
	local footR = part("FootR", Vector3.new(0.7, 0.5, 1), Color3.fromRGB(40, 40, 40))
	footR.Position = Vector3.new(0.6, -1.2, 0)
	footR.Parent = model

	local armL = part("ArmL", Vector3.new(0.5, 1.4, 0.5), bodyColor)
	armL.Position = Vector3.new(-1.45, 0.2, 0)
	armL.Parent = model
	local armR = part("ArmR", Vector3.new(0.5, 1.4, 0.5), bodyColor)
	armR.Position = Vector3.new(1.45, 0.2, 0)
	armR.Parent = model

	-- Weld everything to the body so the creature moves as one.
	for _, child in ipairs(model:GetChildren()) do
		if child ~= body and child:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = child
			weld.Parent = body
		end
	end

	-- Billboard: name, rarity, $/s, readable from across the plaza.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 64)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local rarity = BrainrotData.rarityOf(def)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = Utils.shorten(model.Name, 22)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.new(0, 0, 0.45, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Utils.formatRate(BrainrotData.incomeOf(def, mutationIndex, 1))
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.FredokaOne
	rateLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Position = UDim2.new(0, 0, 0.75, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.25, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = rarity.name:upper()
	rarityLabel.TextColor3 = rarity.color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.FredokaOne
	rarityLabel.Parent = billboard

	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("MutationIndex", mutationIndex)
	model:SetAttribute("BaseRate", def.rate)
	model:SetAttribute("Owner", "")
	return model
end

-- The slap hand: a Tool that knocks a carried brainrot out of a thief.
function BrainrotFactory.createSlapTool()
	local tool = Instance.new("Tool")
	tool.Name = "Slap Hand"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = part("Handle", Vector3.new(1, 0.4, 1.6), Color3.fromRGB(255, 200, 150))
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool

	local fingers = part("Fingers", Vector3.new(1, 0.3, 0.6), Color3.fromRGB(255, 200, 150))
	fingers.Position = Vector3.new(0, 0, 1)
	fingers.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = fingers
	weld.Parent = handle

	tool:SetAttribute("IsSlapTool", true)
	return tool
end

-- A golden crown welded to the head: the visible mark of a rebirth.
function BrainrotFactory.giveCrown(character)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local crown = part("RebirthCrown", Vector3.new(1.4, 0.5, 1.4), Color3.fromRGB(255, 215, 0))
	crown.Material = Enum.Material.Neon
	crown.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = crown
	weld.Parent = head
	crown.Position = head.Position + Vector3.new(0, 0.9, 0)
end

-- v2.5: build a pet companion model from a Config.PETS definition. Pets
-- are half the size of a brainrot, with the same chunky recipe — body,
-- head, eyes, ears and a tail — plus a floating name billboard, so the
-- follower reads as a smaller sibling of the cast. The server spawns
-- these for the pet park display; the client builds its own copy for the
-- follower that trails the player (see Game.client.luau).
function BrainrotFactory.createPetModel(petDef)
	local model = Instance.new("Model")
	model.Name = petDef.name

	local body = part("Body", Vector3.new(1.2, 1, 0.8), petDef.color)
	body.Material = Enum.Material.Neon
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body

	local head = part("Head", Vector3.new(0.95, 0.8, 0.8), petDef.color)
	head.Position = Vector3.new(0, 0.9, 0)
	head.Parent = model

	local eyeColor = Color3.fromRGB(20, 20, 20)
	local eyeL = part("EyeL", Vector3.new(0.18, 0.25, 0.1), eyeColor)
	eyeL.Position = Vector3.new(-0.22, 0.95, 0.42)
	eyeL.Parent = model
	local eyeR = part("EyeR", Vector3.new(0.18, 0.25, 0.1), eyeColor)
	eyeR.Position = Vector3.new(0.22, 0.95, 0.42)
	eyeR.Parent = model

	local earL = part("EarL", Vector3.new(0.25, 0.4, 0.25), petDef.color)
	earL.Position = Vector3.new(-0.35, 1.4, 0)
	earL.Parent = model
	local earR = part("EarR", Vector3.new(0.25, 0.4, 0.25), petDef.color)
	earR.Position = Vector3.new(0.35, 1.4, 0)
	earR.Parent = model

	local tail = part("Tail", Vector3.new(0.25, 0.25, 0.7), petDef.color)
	tail.Position = Vector3.new(0, 0.1, -0.7)
	tail.Parent = model

	-- Weld everything to the body so the pet moves as one.
	for _, child in ipairs(model:GetChildren()) do
		if child ~= body and child:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = child
			weld.Parent = body
		end
	end

	-- Billboard: the pet's name and its income bonus, readable at a glance.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PetLabel"
	billboard.Size = UDim2.fromOffset(140, 36)
	billboard.StudsOffset = Vector3.new(0, 1.9, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = Utils.shorten(model.Name, 18)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = billboard

	local bonusLabel = Instance.new("TextLabel")
	bonusLabel.Position = UDim2.new(0, 0, 0.6, 0)
	bonusLabel.Size = UDim2.new(1, 0, 0.4, 0)
	bonusLabel.BackgroundTransparency = 1
	bonusLabel.Text = "+" .. tostring(math.floor(petDef.bonus * 100 + 0.5)) .. "% income"
	bonusLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	bonusLabel.TextStrokeTransparency = 0
	bonusLabel.TextScaled = true
	bonusLabel.Font = Enum.Font.FredokaOne
	bonusLabel.Parent = billboard

	model:SetAttribute("PetId", petDef.id)
	return model
end

return BrainrotFactory
