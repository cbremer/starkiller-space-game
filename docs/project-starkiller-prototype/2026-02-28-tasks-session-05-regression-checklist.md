# Session 5 Regression Checklist

Date: 2026-02-28
Scope: Critical gameplay loops that must remain stable between tuning passes.

## Automated Smoke Script

Command:

`mkdir -p /tmp/starkiller-smoke && /Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/chrisbremer/code/starkiller-space-game --user-data-dir /tmp/starkiller-smoke --log-file /tmp/starkiller-smoke/godot.log --script res://scripts/smoke_test.gd`

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
