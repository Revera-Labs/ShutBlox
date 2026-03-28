-- Dice.lua (Shared) — Shut the Blox
-- Server-authoritative rolling. Client never rolls.

local Dice = {}

function Dice.roll(sides)
	return math.random(1, sides or 6)
end

function Dice.roll2d6()
	local d1 = Dice.roll(6)
	local d2 = Dice.roll(6)
	return d1, d2, d1 + d2
end

return Dice
