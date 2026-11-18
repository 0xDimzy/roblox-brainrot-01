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

return Utils
