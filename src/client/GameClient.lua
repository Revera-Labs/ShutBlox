-- GameClient.lua — Shut the Blox
-- Runs as a LocalScript in StarterPlayerScripts
-- Handles: UI rendering, input, communicating with server

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local RE_RollDice   = Remotes:WaitForChild("RollDice")
local RE_SelectTile = Remotes:WaitForChild("SelectTile")
local RE_LockIn     = Remotes:WaitForChild("LockIn")
local RE_StateUpdate = Remotes:WaitForChild("StateUpdate")
local RE_GameOver   = Remotes:WaitForChild("GameOver")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShutBloxGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ── UI ELEMENTS ──────────────────────────────────────────────

local function makeLabel(parent, name, text, size, pos, fontSize, color)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.Text = text
	lbl.Size = size
	lbl.Position = pos
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color or Color3.fromRGB(255, 240, 200)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = fontSize or 18
	lbl.Parent = parent
	return lbl
end

local function makeButton(parent, name, text, size, pos, bgColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Text = text
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(180, 120, 30)
	btn.TextColor3 = Color3.fromRGB(255, 240, 200)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	btn.Parent = parent
	return btn
end

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 420)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 5)
mainFrame.BorderSizePixel = 0
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame
mainFrame.Parent = screenGui

-- Title
makeLabel(mainFrame, "Title", "SHUT THE BLOX",
	UDim2.new(1, 0, 0, 36),
	UDim2.new(0, 0, 0, 10),
	24, Color3.fromRGB(212, 160, 40))

-- Score
local scoreLabel = makeLabel(mainFrame, "Score", "Score: 0",
	UDim2.new(0.5, 0, 0, 28),
	UDim2.new(0, 10, 0, 50), 18)

-- Roll display
local rollLabel = makeLabel(mainFrame, "Roll", "Roll: —",
	UDim2.new(0.5, 0, 0, 28),
	UDim2.new(0.5, 0, 0, 50), 18)

-- Tile grid (9 tiles per row, 2 rows)
local tileFrame = Instance.new("Frame")
tileFrame.Size = UDim2.new(0, 468, 0, 160)
tileFrame.Position = UDim2.new(0.5, -234, 0, 90)
tileFrame.BackgroundTransparency = 1
tileFrame.Parent = mainFrame

local tileButtons = {}  -- [row][col] = TextButton

local TILE_W, TILE_H, TILE_PAD = 46, 66, 6

for row = 1, 2 do
	tileButtons[row] = {}
	for col = 1, 9 do
		local x = (col - 1) * (TILE_W + TILE_PAD)
		local y = (row - 1) * (TILE_H + TILE_PAD)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, TILE_W, 0, TILE_H)
		btn.Position = UDim2.new(0, x, 0, y)
		btn.Text = tostring(col)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 20
		btn.TextColor3 = Color3.fromRGB(30, 15, 5)
		btn.BackgroundColor3 = Color3.fromRGB(235, 220, 175)
		btn.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn
		btn.Parent = tileFrame

		local r, cc = row, col  -- capture
		btn.MouseButton1Click:Connect(function()
			RE_SelectTile:FireServer(r, cc)
		end)

		tileButtons[row][col] = btn
	end
end

-- Action buttons
local rollBtn = makeButton(mainFrame, "RollBtn", "🎲 Roll Dice",
	UDim2.new(0, 160, 0, 44),
	UDim2.new(0.5, -80, 0, 265),
	Color3.fromRGB(160, 90, 20))

local lockBtn = makeButton(mainFrame, "LockBtn", "✓ Lock In",
	UDim2.new(0, 160, 0, 44),
	UDim2.new(0.5, -80, 0, 265),
	Color3.fromRGB(40, 130, 60))
lockBtn.Visible = false

-- Status label
local statusLabel = makeLabel(mainFrame, "Status", "Roll to start!",
	UDim2.new(1, -20, 0, 28),
	UDim2.new(0, 10, 0, 320), 16,
	Color3.fromRGB(180, 160, 120))

-- ── STATE RENDERING ──────────────────────────────────────────

local function renderBoard(board)
	for row = 1, 2 do
		for col = 1, 9 do
			local tile = board.rows[row] and board.rows[row][col]
			local btn  = tileButtons[row][col]
			if not tile or not tile.active then
				-- Flipped / removed
				btn.BackgroundColor3 = Color3.fromRGB(50, 30, 15)
				btn.TextColor3 = Color3.fromRGB(50, 30, 15)
				btn.Active = false
			elseif tile.locked then
				btn.BackgroundColor3 = Color3.fromRGB(70, 45, 20)
				btn.TextColor3 = Color3.fromRGB(100, 70, 40)
				btn.Text = "?"
				btn.Active = false
			elseif tile.selected then
				btn.BackgroundColor3 = Color3.fromRGB(212, 160, 40)
				btn.TextColor3 = Color3.fromRGB(30, 15, 5)
				btn.Text = tostring(tile.value)
				btn.Active = true
			else
				btn.BackgroundColor3 = Color3.fromRGB(235, 220, 175)
				btn.TextColor3 = Color3.fromRGB(30, 15, 5)
				btn.Text = tostring(tile.value)
				btn.Active = true
			end
		end
	end
end

RE_StateUpdate.OnClientEvent:Connect(function(state)
	if not state or not state.board then return end

	renderBoard(state.board)
	scoreLabel.Text = "Score: " .. (state.score or 0)

	if state.roll and state.roll > 0 then
		rollLabel.Text = "Roll: " .. state.roll
	else
		rollLabel.Text = "Roll: —"
	end

	if state.phase == "rolling" then
		rollBtn.Visible = true
		lockBtn.Visible = false
		statusLabel.Text = "Your turn — roll the dice!"
	elseif state.phase == "selecting" then
		rollBtn.Visible = false
		lockBtn.Visible = true
		statusLabel.Text = "Select tiles that add up to " .. (state.roll or "?")
	end
end)

RE_GameOver.OnClientEvent:Connect(function(data)
	rollBtn.Visible = false
	lockBtn.Visible = false

	local msg = "GAME OVER\n"
	if data.remaining == 0 then
		msg = "🎉 SHUT THE BOX! 🎉\n"
	end
	msg = msg .. "Score: " .. (data.formatted or data.score)
	if data.shutBonus and data.shutBonus > 0 then
		msg = msg .. "\n+500 Shut Bonus!"
	end
	statusLabel.Text = msg

	-- Restart button
	local restartBtn = makeButton(mainFrame, "RestartBtn", "▶ Play Again",
		UDim2.new(0, 160, 0, 44),
		UDim2.new(0.5, -80, 0, 265),
		Color3.fromRGB(80, 40, 160))
	restartBtn.MouseButton1Click:Connect(function()
		restartBtn:Destroy()
		RE_RollDice:FireServer()  -- server will re-init session on next roll attempt
	end)
end)

-- Button actions
rollBtn.MouseButton1Click:Connect(function()
	RE_RollDice:FireServer()
end)

lockBtn.MouseButton1Click:Connect(function()
	RE_LockIn:FireServer()
end)

print("[ShutBlox] GameClient loaded")
