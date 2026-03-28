# Shut the Blox 🎲

A Roblox game by **Revera Labs** — the classic *Shut the Box* dice game, rebuilt for Roblox.

## Project Structure

```
src/
  shared/        ← Pure game logic (ReplicatedStorage/Shared)
    Board.lua    — Board state, tile logic, move validation
    Scoring.lua  — Points, combos, shut bonus
    Dice.lua     — Server-side RNG
  server/        ← ServerScriptService
    GameServer.lua — Authoritative game loop, RemoteEvent handlers
  client/        ← StarterPlayerScripts (LocalScript)
    GameClient.lua — UI rendering, input handling
```

## Roblox Studio Setup

1. Open Roblox Studio → New Baseplate
2. In **ReplicatedStorage**: create folder `Shared`, create folder `Remotes`
3. In `Remotes`, create 4 RemoteEvents:
   - `RollDice`
   - `SelectTile`
   - `LockIn`
   - `StateUpdate`
   - `GameOver`
4. Copy `src/shared/*.lua` → `ReplicatedStorage/Shared/` (as ModuleScripts)
5. Copy `src/server/GameServer.lua` → `ServerScriptService/` (as Script)
6. Copy `src/client/GameClient.lua` → `StarterPlayerScripts/` (as LocalScript)
7. Hit **Play** to test

## Monetization Plan (Phase 2)
- **Gamepasses**: Premium dice skins (steampunk, neon, etc.), table themes
- **Developer Products**: Hint system, extra rerolls
- **Premium Payouts**: Enabled by default via Roblox

## Roadmap
- [x] Core solo game loop
- [ ] Multiplayer lobby (2-4 players at a table)
- [ ] Leaderboards (DataStoreService)
- [ ] Cosmetics / gamepass system
- [ ] Steampunk visual theme
