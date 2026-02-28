# Starkiller Space Game (Godot 4 Prototype)

Session 1 delivers a runnable Godot 4 vertical slice focused on controls, game-state flow, HUD visibility, and a fuel-pressure loop.

## Run

1. Open this folder in **Godot 4.2+**.
2. Press Play (`F5`) to run `scenes/Main.tscn`.

## Controls (default)

- Move: Arrow keys
- Fire: `Z`
- Bomb: `X`
- Start run: `Enter`
- Pause toggle: `Esc`
- Manual refuel (prototype helper): `R`

## Implemented in Session 1

- Godot project scaffold (`project.godot`, main scene, scripts, placeholder icon).
- Input map setup for all required actions.
- `GameState` model with start/pause/death/respawn transitions.
- Controllable player ship placeholder bounded to a play area.
- Live HUD showing score/lives/fuel/stage/paused/alive-dead status.
- Fuel drain loop with zero-fuel death and respawn path.
- Refuel validation via an on-screen refuel zone and the `R` helper key.

## Notes

- This is intentionally placeholder-heavy for rapid iteration.
- Next session should add enemies, collisions, and fire/bomb interaction rules.
