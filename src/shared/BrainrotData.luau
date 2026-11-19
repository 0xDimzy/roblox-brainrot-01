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
	-- v7: Eternal and OG sit above Transcendent — the top of the ladder.
	{ name = "Eternal", color = Color3.fromRGB(255, 105, 255), weight = 1, costMult = 300 },
	{ name = "OG", color = Color3.fromRGB(255, 255, 255), weight = 1, costMult = 600 },
}

BrainrotData.MUTATIONS = {
	{ name = "", mult = 1, chance = 74 },
	{ name = "Golden", mult = 2, chance = 12, tint = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", mult = 5, chance = 5, tint = Color3.fromRGB(185, 242, 255) },
	{ name = "Rainbow", mult = 10, chance = 2, tint = Color3.fromRGB(255, 105, 180) },
	-- v7: Void, Cosmic and Glitch sit above Rainbow — rarer still, richer still.
	{ name = "Void", mult = 7, chance = 4, tint = Color3.fromRGB(40, 0, 80) },
	{ name = "Cosmic", mult = 15, chance = 2, tint = Color3.fromRGB(120, 80, 255) },
	{ name = "Glitch", mult = 25, chance = 1, tint = Color3.fromRGB(0, 255, 120) },
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
	-- v3 cast: 15 more characters, 37 -> 52, across every rarity,
	-- including two new Transcendents at the very top of the ladder.
	{ id = "sir-soggy", name = "Sir Soggy", rarity = 1, rate = 5, color = Color3.fromRGB(120, 160, 200), joke = "Left in the rain. Still billing." },
	{ id = "mayo-marge", name = "Mayo Marge", rarity = 1, rate = 12, color = Color3.fromRGB(250, 250, 230), joke = "Spreads the wealth. Literally." },
	{ id = "duke-dumpster", name = "Duke Dumpster", rarity = 1, rate = 14, color = Color3.fromRGB(90, 120, 90), joke = "One man's trash. His treasure." },
	{ id = "professor-pickle-jar", name = "Professor Pickle Jar", rarity = 2, rate = 24, color = Color3.fromRGB(110, 190, 70), joke = "Brined for knowledge." },
	{ id = "lady-lamp", name = "Lady Lamp", rarity = 2, rate = 32, color = Color3.fromRGB(255, 240, 150), joke = "Lights the way. Charges rent." },
	{ id = "captain-croissant", name = "Captain Croissant", rarity = 2, rate = 34, color = Color3.fromRGB(230, 190, 110), joke = "Flaky. Fearless. French." },
	{ id = "baroness-bubblewrap", name = "Baroness Bubblewrap", rarity = 3, rate = 100, color = Color3.fromRGB(180, 220, 255), joke = "Pops under pressure. Pays anyway." },
	{ id = "doctor-donut", name = "Doctor Donut", rarity = 3, rate = 140, color = Color3.fromRGB(255, 170, 200), joke = "Sprinkles. Scalpel. Same thing." },
	{ id = "general-gravy-boat", name = "General Gravy Boat", rarity = 3, rate = 160, color = Color3.fromRGB(170, 120, 60), joke = "Sails the Sunday roast." },
	{ id = "queen-quinoa", name = "Queen Quinoa", rarity = 4, rate = 360, color = Color3.fromRGB(220, 200, 160), joke = "A superfood. A super landlord." },
	{ id = "lord-lawn-flamingo", name = "Lord Lawn Flamingo", rarity = 4, rate = 450, color = Color3.fromRGB(255, 120, 180), joke = "One leg in. All the way rich." },
	{ id = "madame-midnight-snack", name = "Madame Midnight Snack", rarity = 5, rate = 1300, color = Color3.fromRGB(80, 60, 120), joke = "Strikes at 2am. Tips well." },
	{ id = "the-intern", name = "The Intern", rarity = 6, rate = 4200, color = Color3.fromRGB(200, 200, 220), joke = "Unpaid. Unstoppable. Unbothered." },
	{ id = "supreme-ohio-overlord", name = "Supreme Ohio Overlord", rarity = 7, rate = 15000, color = Color3.fromRGB(255, 215, 0), joke = "Ohio's final form. It has a crown." },
	{ id = "mega-ohio-boss", name = "Mega Ohio Final Boss", rarity = 7, rate = 18000, color = Color3.fromRGB(255, 60, 60), joke = "The raid boss. The whole raid." },
	-- v6 cast: 12 more characters, 52 -> 64, across every rarity,
	-- including a new Secret who only shows up at the Daily Shrine.
	{ id = "baron-butter", name = "Baron Butter", rarity = 1, rate = 18, color = Color3.fromRGB(255, 220, 90), joke = "Melts under pressure. Still rich." },
	{ id = "captain-ketchup", name = "Captain Ketchup", rarity = 1, rate = 18, color = Color3.fromRGB(220, 40, 40), joke = "Squeezes every last cent." },
	{ id = "lady-latte", name = "Lady Latte", rarity = 2, rate = 38, color = Color3.fromRGB(200, 150, 100), joke = "Foams at the mouth. Pays in beans." },
	{ id = "duke-donut-hole", name = "Duke Donut Hole", rarity = 2, rate = 44, color = Color3.fromRGB(230, 170, 130), joke = "The hole is the whole point." },
	{ id = "professor-pancake", name = "Professor Pancake", rarity = 3, rate = 170, color = Color3.fromRGB(240, 200, 120), joke = "Flips the market. Stacks the cash." },
	{ id = "madame-mustard", name = "Madame Mustard", rarity = 3, rate = 195, color = Color3.fromRGB(240, 200, 40), joke = "Cuts through the noise. And the bill." },
	{ id = "sultan-syrup", name = "Sultan of Syrup", rarity = 4, rate = 480, color = Color3.fromRGB(180, 110, 40), joke = "Sticky fingers. Sticky profits." },
	{ id = "queen-quiche", name = "Queen Quiche", rarity = 4, rate = 540, color = Color3.fromRGB(255, 210, 140), joke = "Bakes the books. Eats the evidence." },
	{ id = "doctor-dumpling", name = "Doctor Dumpling", rarity = 5, rate = 1500, color = Color3.fromRGB(255, 190, 160), joke = "Steamed. Stuffed. Solvent." },
	{ id = "the-cereal-killer", name = "The Cereal Killer", rarity = 6, rate = 6000, color = Color3.fromRGB(255, 80, 80), joke = "Part of a balanced breakfast." },
	{ id = "grand-emperor-ohio", name = "Grand Emperor of Ohio", rarity = 7, rate = 24000, color = Color3.fromRGB(255, 215, 0), joke = "Ohio kneels. The rent does not." },
	{ id = "shrine-keeper-sam", name = "Shrine Keeper Sam", rarity = 6, rate = 8000, color = Color3.fromRGB(120, 255, 200), joke = "Guards the shrine. Counts your streak." },
	-- v7 cast: 12 more characters, 64 -> 76, across every rarity,
	-- including the first Eternal and the first OG at the top.
	{ id = "pancake-pam", name = "Pancake Pam", rarity = 1, rate = 16, color = Color3.fromRGB(240, 180, 90), joke = "Flips for tips. Tips for flips." },
	{ id = "noodle-ned", name = "Noodle Ned", rarity = 1, rate = 19, color = Color3.fromRGB(250, 220, 120), joke = "Al dente since 2019." },
	{ id = "boogie-baron", name = "Boogie Baron", rarity = 2, rate = 40, color = Color3.fromRGB(255, 100, 200), joke = "Dances into your wallet." },
	{ id = "captain-crouton", name = "Captain Crouton", rarity = 2, rate = 46, color = Color3.fromRGB(210, 160, 90), joke = "Crunchy. Crunchy and paid." },
	{ id = "madame-mozzarella", name = "Madame Mozzarella", rarity = 3, rate = 175, color = Color3.fromRGB(255, 240, 200), joke = "Stretches the truth. And the cheese." },
	{ id = "general-gnocchi", name = "General Gnocchi", rarity = 3, rate = 200, color = Color3.fromRGB(230, 210, 160), joke = "Small. Dense. Commands the bowl." },
	{ id = "empress-eggplant", name = "Empress Eggplant", rarity = 4, rate = 560, color = Color3.fromRGB(160, 60, 180), joke = "Purple reign. Purple profits." },
	{ id = "lord-latte-art", name = "Lord Latte Art", rarity = 4, rate = 620, color = Color3.fromRGB(190, 140, 90), joke = "Foams a heart. Bills a fortune." },
	{ id = "cosmic-carl", name = "Cosmic Carl", rarity = 5, rate = 1600, color = Color3.fromRGB(120, 80, 255), joke = "Orbits the boulevard. Collects rent." },
	{ id = "the-mod", name = "The Mod", rarity = 6, rate = 7000, color = Color3.fromRGB(80, 255, 210), joke = "Bans poverty. Pins your base." },
	{ id = "eternal-ohio", name = "Eternal Ohio", rarity = 8, rate = 30000, color = Color3.fromRGB(255, 105, 255), joke = "Ohio, but forever." },
	{ id = "the-original-brainrot", name = "The Original Brainrot", rarity = 9, rate = 45000, color = Color3.fromRGB(255, 255, 255), joke = "The first. The last. The OG." },
}

-- v2.5: how many characters are in the cast (37 after the v2.5 additions).
-- v3: 52 after the v3 additions — 15 new faces, two of them Transcendent.
-- v6: 64 after the v6 additions — 12 new faces, one of them a shrine keeper.
-- v7: 76 after the v7 additions — 12 new faces, one Eternal, one OG.
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

-- v7: a random character of one exact rarity — the Fuse Machine's roll
-- for the brainrot one tier above the three that went in.
function BrainrotData.rollDefOfRarity(rarityIndex)
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
