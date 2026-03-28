-- GameServer.lua — Shut the Blox
-- Runs in ServerScriptService. Authoritative game state.
-- Handles: session creation, dice rolling, move validation, scoring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Board   = require(ReplicatedStorage.Shared.Board)
local Scoring = require(ReplicatedStorage.Shared.Scoring)
local Dice    = require(ReplicatedStorage.Shared.Dice)

-- RemoteEvents (create these in ReplicatedStorage.Remotes)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RE_RollDice      = Remotes:WaitForChild("RollDice")
local RE_SelectTile    = Remotes:WaitForChild("SelectTile")
local RE_LockIn        = Remotes:WaitForChild("LockIn")
local RE_StateUpdate   = Remotes:WaitForChild("StateUpdate")
local RE_GameOver      = Remotes:WaitForChild("GameOver")

-- Active sessions: { [player] = { board, score, roll, phase } }
local sessions = {}

local function newSession(player)
	sessions[player] = {
		board = Board.generateBoard(),
		score = 0,
		roll  = 0,
		phase = "rolling",  -- "rolling" | "selecting" | "gameover"
	}
	RE_StateUpdate:FireClient(player, sessions[player])
	print("[ShutBlox] New session for", player.Name)
end

local function endGame(player)
	local s = sessions[player]
	if not s then return end
	s.phase = "gameover"
	local remaining = Board.getRemainingSum(s.board)
	local shutBonus = Scoring.shutBonus(remaining)
	s.score = s.score + shutBonus
	RE_GameOver:FireClient(player, {
		score      = s.score,
		remaining  = remaining,
		shutBonus  = shutBonus,
		formatted  = Scoring.formatScore(s.score),
	})
	sessions[player] = nil
end

-- ROLL DICE
RE_RollDice.OnServerEvent:Connect(function(player)
	local s = sessions[player]
	if not s or s.phase ~= "rolling" then return end

	local d1, d2, total = Dice.roll2d6()
	s.roll  = total
	s.phase = "selecting"
	Board.clearSelection(s.board)

	-- Check if any valid move exists
	if not Board.hasValidMove(s.board, total) then
		endGame(player)
		return
	end

	RE_StateUpdate:FireClient(player, {
		board = s.board,
		score = s.score,
		roll  = s.roll,
		phase = s.phase,
		dice  = { d1, d2 },
	})
end)

-- SELECT / DESELECT TILE
RE_SelectTile.OnServerEvent:Connect(function(player, row, col)
	local s = sessions[player]
	if not s or s.phase ~= "selecting" then return end

	local tile = s.board.rows[row] and s.board.rows[row][col]
	if not tile or not tile.active or tile.locked then return end

	tile.selected = not tile.selected

	RE_StateUpdate:FireClient(player, {
		board = s.board,
		score = s.score,
		roll  = s.roll,
		phase = s.phase,
	})
end)

-- LOCK IN SELECTION
RE_LockIn.OnServerEvent:Connect(function(player)
	local s = sessions[player]
	if not s or s.phase ~= "selecting" then return end

	local selectedSum = Board.getSelectedSum(s.board)
	if selectedSum ~= s.roll then
		-- Invalid selection — just clear and let them retry
		Board.clearSelection(s.board)
		RE_StateUpdate:FireClient(player, s)
		return
	end

	local ok, count = Board.applySelection(s.board, s.roll)
	if ok then
		local points = Scoring.tilePoints(count)
		s.score = s.score + points
	end

	if Board.isCleared(s.board) then
		endGame(player)
		return
	end

	s.phase = "rolling"
	RE_StateUpdate:FireClient(player, {
		board = s.board,
		score = s.score,
		roll  = 0,
		phase = s.phase,
	})
end)

-- SESSION LIFECYCLE
Players.PlayerAdded:Connect(function(player)
	newSession(player)
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

-- Handle players already in game when script loads
for _, player in ipairs(Players:GetPlayers()) do
	newSession(player)
end

print("[ShutBlox] GameServer loaded")
