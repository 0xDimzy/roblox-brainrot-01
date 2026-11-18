-- Brainrot Boulevard: small shared helpers (money formatting, colors).

local Utils = {}

-- $1,234 -> "$1,234"; $1,250,000 -> "$1.25M"; $12,500 -> "$12.5K".
function Utils.formatMoney(n)
	n = math.floor(n + 0.5)
	if n >= 1000000 then
		return string.format("$%.2fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("$%.1fK", n / 1000)
	elseif n >= 1000 then
		local s = tostring(n)
		return "$" .. s:sub(1, #s - 3) .. "," .. s:sub(#s - 2)
	else
		return "$" .. tostring(n)
	end
end

function Utils.formatRate(n)
	if n >= 100 then
		return Utils.formatMoney(n) .. "/s"
	end
	return string.format("$%.0f/s", n)
end

-- Shorten a long name for a billboard label.
function Utils.shorten(name, maxLen)
	if #name <= maxLen then
		return name
	end
	return name:sub(1, maxLen - 1) .. "…"
end

-- v2.5: clamp a number into [lo, hi].
function Utils.clamp(n, lo, hi)
	if n < lo then
		return lo
	end
	if n > hi then
		return hi
	end
	return n
end

-- v2.5: round to the nearest whole number.
function Utils.round(n)
	return math.floor(n + 0.5)
end

-- v2.5: pick a random element of a non-empty list.
function Utils.pickRandom(list)
	return list[math.random(1, #list)]
end

-- v2.5: weighted pick over an array of tables with a numeric weight
-- field (default "weight"). Used by EventService to roll the next event
-- from Config.EVENT_WEIGHTS: a weight-3 event fires 3x as often as a
-- weight-1 one. Returns the first entry when the weights sum to zero.
function Utils.weightedPick(entries, weightField)
	weightField = weightField or "weight"
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry[weightField] or 0
	end
	if total <= 0 then
		return entries[1]
	end
	local pick = math.random() * total
	for _, entry in ipairs(entries) do
		pick -= entry[weightField] or 0
		if pick <= 0 then
			return entry
		end
	end
	return entries[#entries]
end

-- v2.5: progress as a 0..1 fraction, clamped. QuestService feeds the HUD
-- progress bars with this; a target of 0 or less counts as complete.
function Utils.progress(current, target)
	if target <= 0 then
		return 1
	end
	return Utils.clamp(current / target, 0, 1)
end

return Utils
