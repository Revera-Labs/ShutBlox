-- Scoring.lua (Shared) — Shut the Blox
-- Ported from Cognoga scoring system

local Scoring = {}

function Scoring.tilePoints(tilesRemoved)
	local base = 10
	local combo = 1.0
	if tilesRemoved == 2 then combo = 1.15
	elseif tilesRemoved == 3 then combo = 1.35
	elseif tilesRemoved >= 4 then combo = 1.60
	end
	return math.floor(base * tilesRemoved * combo)
end

function Scoring.shutBonus(remainingSum)
	-- Full shut = 500 bonus. Partial shut scales down.
	if remainingSum == 0 then
		return 500
	end
	return 0
end

function Scoring.formatScore(n)
	local s = tostring(math.floor(n))
	local result = ""
	local count = 0
	for i = #s, 1, -1 do
		count = count + 1
		result = s:sub(i, i) .. result
		if count % 3 == 0 and i > 1 then
			result = "," .. result
		end
	end
	return result
end

return Scoring
