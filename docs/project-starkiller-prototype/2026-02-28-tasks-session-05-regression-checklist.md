# Session 5 Regression Checklist

Date: 2026-02-28
Scope: Critical gameplay loops that must remain stable between tuning passes.

## Automated Smoke Script

Command (run from the repo root):

`mkdir -p /tmp/starkiller-smoke && godot --headless --path . --user-data-dir /tmp/starkiller-smoke --log-file /tmp/starkiller-smoke/godot.log --script res://scripts/smoke_test.gd`

Notes:
- If `godot` (or `godot4`) is not on your `PATH`, replace `godot` in the command with the full path to your Godot binary.
- Example macOS app bundle path: `/Applications/Godot.app/Contents/MacOS/Godot`
- Example Windows path: `"C:\Program Files\Godot\Godot.exe"`
- Example Linux path (if installed via package manager): `godot4` or `godot`

Covers:
- Required input actions exist in `InputMap`.
- `GameState` start/pause/death/respawn transitions.
- Enemy hit rules: laser vs air, bomb vs ground, bomb vs air.

## Manual Gameplay Checks

- Start run, pause, resume, and retry from pause menu.
- Verify ship can descend close to terrain without invisible clamp.
- Verify bombs detonate on terrain impact.
- Verify bombs kill both ground and flying enemies.
- Verify remapped controls still work after restarting the game.
