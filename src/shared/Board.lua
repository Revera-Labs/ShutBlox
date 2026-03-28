-- Board.lua (Shared) — Shut the Blox
-- Ported from Cognoga. LÖVE2D rendering stripped. Pure logic only.

local Board = {}

local TILES_PER_ROW = 9  -- classic Shut the Box uses 1-9

local function makeTile(value, rowIndex, colIndex)
	return {
		value    = value,
		active   = true,
		selected = false,
		row      = rowIndex,
		col      = colIndex,
		locked   = (rowIndex == 2),
	}
end

function Board.generateBoard()
	local board = { rows = { [1] = {}, [2] = {} } }
	for col = 1, TILES_PER_ROW do
		board.rows[1][col] = makeTile(col, 1, col)
		board.rows[2][col] = makeTile(col, 2, col)
	end
	return board
end

function Board.isCleared(board)
	for _, row in ipairs(board.rows) do
		for _, tile in ipairs(row) do
			if tile.active then return false end
		end
	end
	return true
end

function Board.clearSelection(board)
	for _, row in ipairs(board.rows) do
		for _, tile in ipairs(row) do
			tile.selected = false
		end
	end
end

function Board.getSelectedSum(board)
	local sum = 0
	for _, row in ipairs(board.rows) do
		for _, tile in ipairs(row) do
			if tile.active and tile.selected and not tile.locked then
				sum = sum + tile.value
			end
		end
	end
	return sum
end

local function unlockBackTiles(board, removed)
	for _, t in ipairs(removed) do
		if t.row == 1 then
			local bt = board.rows[2][t.col]
			if bt and bt.active then bt.locked = false end
		end
	end
end

function Board.applySelection(board, targetSum)
	local selected, sum = {}, 0
	for _, row in ipairs(board.rows) do
		for _, tile in ipairs(row) do
			if tile.active and tile.selected and not tile.locked then
				selected[#selected+1] = tile
				sum = sum + tile.value
			end
		end
	end
	if #selected == 0 or sum ~= targetSum then return false, 0 end
	for _, tile in ipairs(selected) do
		tile.active = false
		tile.selected = false
	end
	unlockBackTiles(board, selected)
	return true, #selected
end

function Board.hasValidMove(board, roll)
	-- Check if any combination of active unlocked tiles sums to roll
	local tiles = {}
	for _, row in ipairs(board.rows) do
		for _, tile in ipairs(row) do
			if tile.active and not tile.locked then
				tiles[#tiles+1] = tile.value
			end
		end
	end
	-- Subset sum check
	local n = #tiles
	for mask = 1, (2^n) - 1 do
		local s = 0
		for i = 1, n do
			if math.floor(mask / 2^(i-1)) % 2 == 1 then
				s = s + tiles[i]
			end
		end
		if s == roll then return true end
	end
	return false
end

function Board.getRemainingSum(board)
	local sum = 0
	for _, row in ipairs(board.rows) do
		for _, tile in ipairs(row) do
			if tile.active then sum = sum + tile.value end
		end
	end
	return sum
end

return Board
