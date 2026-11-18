-- Brainrot Boulevard: the cast. Every character is original to this game,
-- absurd on purpose, on a ladder of rarities with a mutation roll on top.
-- cost is what a conveyor brainrot sells for; rate is its $/second.

local BrainrotData = {}

BrainrotData.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(180, 180, 180), weight = 55, costMult = 1 },
	{ name = "Rare", color = Color3.fromRGB(93, 173, 226), weight = 25, costMult = 2.5 },
	{ name = "Epic", color = Color3.fromRGB(175, 122, 197), weight = 12, costMult = 6 },
	{ name = "Legendary", color = Color3.fromRGB(255, 195, 0), weight = 5, costMult = 14 },
	{ name = "Mythic", color = Color3.fromRGB(255, 87, 51), weight = 3, costMult = 32 },
	{ name = "Secret", color = Color3.fromRGB(0, 255, 200), weight = 2, costMult = 70 },
	-- v2: Transcendent sits above Secret — rarer than a rainbow, richer than Ohio.
	{ name = "Transcendent", color = Color3.fromRGB(255, 215, 0), weight = 1, costMult = 150 },
}

BrainrotData.MUTATIONS = {
	{ name = "", mult = 1, chance = 82 },
	{ name = "Golden", mult = 2, chance = 12, tint = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", mult = 5, chance = 5, tint = Color3.fromRGB(185, 242, 255) },
	{ name = "Rainbow", mult = 10, chance = 1, tint = Color3.fromRGB(255, 105, 180) },
}

-- id, name, rarity index, $/s, body color, one-line joke shown in the shop.
BrainrotData.CAST = {
	{ id = "toaster-tim", name = "Toaster Tim", rarity = 1, rate = 4, color = Color3.fromRGB(200, 120, 60), joke = "Burns toast. Earns cash." },
	{ id = "pickle-pete", name = "Pickle Pete", rarity = 1, rate = 6, color = Color3.fromRGB(120, 200, 80), joke = "Dill with it." },
	{ id = "sock-goblin", name = "Sock Goblin", rarity = 1, rate = 9, color = Color3.fromRGB(140, 140, 200), joke = "Stole your left sock." },
	{ id = "chairman-meow", name = "Chairman Meow", rarity = 2, rate = 15, color = Color3.fromRGB(255, 170, 60), joke = "Runs the treat economy." },
	{ id = "dj-llama", name = "DJ Llama Drama", rarity = 2, rate = 22, color = Color3.fromRGB(220, 120, 220), joke = "Drops beats, not hints." },
	{ id = "sir-barksalot", name = "Sir Barksalot", rarity = 2, rate = 30, color = Color3.fromRGB(160, 110, 60), joke = "Knighted for barking." },
	{ id = "prof-nugget", name = "Professor Nugget", rarity = 3, rate = 50, color = Color3.fromRGB(255, 220, 130), joke = "PhD in dipping sauce." },
	{ id = "madame-zucchini", name = "Madame Zucchini", rarity = 3, rate = 75, color = Color3.fromRGB(90, 200, 90), joke = "Sees your future. It is soup." },
	{ id = "count-crumb", name = "Count Crumb", rarity = 3, rate = 110, color = Color3.fromRGB(120, 80, 40), joke = "Lives in your couch." },
	{ id = "queen-blobfish", name = "Queen Blobfish", rarity = 4, rate = 180, color = Color3.fromRGB(255, 150, 180), joke = "Royalty. Very droopy." },
	{ id = "lord-spaghetti", name = "Lord Spaghetti", rarity = 4, rate = 260, color = Color3.fromRGB(255, 230, 150), joke = "Al dente and dangerous." },
	{ id = "grand-noodle", name = "The Grand Noodle", rarity = 4, rate = 380, color = Color3.fromRGB(240, 200, 90), joke = "Do not slurp the Grand Noodle." },
	{ id = "elon-muskrat", name = "Elon Muskrat", rarity = 5, rate = 600, color = Color3.fromRGB(100, 160, 255), joke = "Going to Mars. By river." },
	{ id = "greg-shrek", name = "Shrek's Cousin Greg", rarity = 5, rate = 900, color = Color3.fromRGB(90, 190, 90), joke = "Also has layers." },
	{ id = "baby-gronk", name = "Baby Gronk 2.0", rarity = 5, rate = 1400, color = Color3.fromRGB(255, 120, 120), joke = "Rizzed up the whole boulevard." },
	{ id = "skibidi-overlord", name = "Skibidi Overlord", rarity = 6, rate = 2500, color = Color3.fromRGB(60, 220, 200), joke = "He flushed the old meta." },
	{ id = "ohio-boss", name = "Ohio Final Boss", rarity = 6, rate = 5000, color = Color3.fromRGB(200, 60, 220), joke = "Only in Ohio. Only final." },
	-- v2 cast: 10 more characters, 17 -> 27, with a new Transcendent tier.
	{ id = "waffle-wally", name = "Waffle Wally", rarity = 1, rate = 7, color = Color3.fromRGB(220, 170, 90), joke = "Syrup-powered since birth." },
	{ id = "banana-barry", name = "Banana Barry", rarity = 1, rate = 11, color = Color3.fromRGB(255, 235, 80), joke = "Peels out. Literally." },
	{ id = "milkman-mike", name = "Milkman Mike", rarity = 1, rate = 13, color = Color3.fromRGB(240, 240, 240), joke = "Delivers. Never explains." },
	{ id = "disco-dave", name = "Disco Dave", rarity = 2, rate = 18, color = Color3.fromRGB(255, 120, 200), joke = "Stayin' alive, stayin' paid." },
	{ id = "grandma-glitch", name = "Grandma Glitch", rarity = 2, rate = 26, color = Color3.fromRGB(180, 140, 255), joke = "Bakes cookies. Hacks time." },
	{ id = "sir-reginald-frog", name = "Sir Reginald Frog", rarity = 3, rate = 90, color = Color3.fromRGB(80, 200, 140), joke = "Ribbits in four languages." },
	{ id = "queen-queso", name = "Queen Queso", rarity = 4, rate = 320, color = Color3.fromRGB(255, 200, 40), joke = "Melts hearts. Taxes nachos." },
	{ id = "doctor-doomscroll", name = "Doctor Doomscroll", rarity = 5, rate = 1100, color = Color3.fromRGB(140, 80, 220), joke = "One more video. Just one more." },
	{ id = "tax-man", name = "The Tax Man", rarity = 6, rate = 3500, color = Color3.fromRGB(60, 60, 60), joke = "He always collects." },
	{ id = "ceo-of-ohio", name = "CEO of Ohio", rarity = 7, rate = 9000, color = Color3.fromRGB(255, 215, 0), joke = "Owns Ohio. All of it." },
	-- v2.5 cast: 10 more characters, 27 -> 37, across every rarity.
	{ id = "captain-couch", name = "Captain Couch", rarity = 1, rate = 8, color = Color3.fromRGB(150, 100, 60), joke = "Sits. Earns. Never leaves." },
	{ id = "bubble-brian", name = "Bubble Brian", rarity = 1, rate = 10, color = Color3.fromRGB(140, 200, 255), joke = "Pops. Reforms. Profits." },
	{ id = "grandpa-gravy", name = "Grandpa Gravy", rarity = 2, rate = 20, color = Color3.fromRGB(190, 150, 90), joke = "Ladles out the lore." },
	{ id = "mc-microwave", name = "MC Microwave", rarity = 2, rate = 28, color = Color3.fromRGB(200, 200, 200), joke = "Beep beep. Bars." },
	{ id = "baron-bagel", name = "Baron Von Bagel", rarity = 3, rate = 95, color = Color3.fromRGB(230, 180, 110), joke = "Holes in his plans. None in his bagel." },
	{ id = "lady-lawnmower", name = "Lady Lawnmower", rarity = 3, rate = 130, color = Color3.fromRGB(90, 180, 90), joke = "Cuts grass. Cuts checks." },
	{ id = "sultan-seltzer", name = "Sultan of Seltzer", rarity = 4, rate = 340, color = Color3.fromRGB(150, 220, 255), joke = "Fizzy. Fabulous. Filthy rich." },
	{ id = "madame-meme", name = "Madame Meme", rarity = 4, rate = 420, color = Color3.fromRGB(255, 120, 220), joke = "She saw the format first." },
	{ id = "void-vic", name = "Void Vic", rarity = 5, rate = 1200, color = Color3.fromRGB(40, 40, 60), joke = "Stares back. Pays forward." },
	{ id = "the-algorithm", name = "The Algorithm", rarity = 7, rate = 12000, color = Color3.fromRGB(255, 215, 0), joke = "It knows what you earn next." },
}

-- v2.5: how many characters are in the cast (37 after the v2.5 additions).
function BrainrotData.count()
	return #BrainrotData.CAST
end

function BrainrotData.getById(id)
	for _, def in ipairs(BrainrotData.CAST) do
		if def.id == id then
			return def
		end
	end
	return nil
end

function BrainrotData.rarityOf(def)
	return BrainrotData.RARITIES[def.rarity]
end

function BrainrotData.costOf(def)
	return math.floor(def.rate * 12 * BrainrotData.rarityOf(def).costMult + 0.5)
end

-- Weighted roll: pick a rarity first, then a random character of it.
function BrainrotData.rollDef()
	local total = 0
	for _, r in ipairs(BrainrotData.RARITIES) do
		total += r.weight
	end
	local pick = math.random(1, total)
	local rarityIndex = 1
	for i, r in ipairs(BrainrotData.RARITIES) do
		pick -= r.weight
		if pick <= 0 then
			rarityIndex = i
			break
		end
	end
	local pool = {}
	for _, def in ipairs(BrainrotData.CAST) do
		if def.rarity == rarityIndex then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

function BrainrotData.rollMutation()
	local pick = math.random(1, 100)
	local acc = 0
	for i, m in ipairs(BrainrotData.MUTATIONS) do
		acc += m.chance
		if pick <= acc then
			return i
		end
	end
	return 1
end

function BrainrotData.mutationOf(index)
	return BrainrotData.MUTATIONS[index]
end

-- $/s of one brainrot after mutation and rebirth multipliers.
function BrainrotData.incomeOf(def, mutationIndex, rebirthMult)
	local m = BrainrotData.MUTATIONS[mutationIndex] or BrainrotData.MUTATIONS[1]
	return def.rate * m.mult * rebirthMult
end

function BrainrotData.displayName(def, mutationIndex)
	local m = BrainrotData.MUTATIONS[mutationIndex] or BrainrotData.MUTATIONS[1]
	if m.name == "" then
		return def.name
	end
	return m.name .. " " .. def.name
end

return BrainrotData
