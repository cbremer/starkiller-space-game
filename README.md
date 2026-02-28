# Starkiller Space Game (Godot 4 Prototype)

Current prototype is a keyboard-first, Scramble-style horizontal shooter slice with stage segments, split weapon roles, and fuel pressure.

## Run

1. Open this folder in **Godot 4.6.1+**.
2. Press Play (`F5`) to run `scenes/Main.tscn`.
3. Press `Enter` to start a run.

## Automated Tests

Run the headless test suite:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/run_tests.gd
```

Current coverage includes both unit checks and scenario flows for `GameState`:
- start/pause behavior
- fuel drain -> death -> respawn
- full lifecycle through game over
- pause freeze and resume behavior

## Controls (default)

- Move: Arrow keys
- Fire (air targets): `Z`
- Drop bomb (ground targets): `X`
- Start run: `Enter`
- Pause toggle: `Esc`
- Manual refuel helper (prototype): `R`

## Current Features

- Core run-state flow (`GameState`): start, pause, death, respawn.
- Horizontal flight feel with ship facing right.
- Distinct weapon behavior:
  - Laser shots travel right and destroy air targets.
  - Bombs are gravity-dropped payloads and destroy ground targets.
- Enemy pressure loop with randomized spawn pacing/speeds.
- Fuel system:
  - passive fuel drain,
  - refuel zone + `R` helper,
  - collectible fuel tanks spawned by stage segment rules.
- Stage progression shell:
  - distance-based segment transitions,
  - segment-specific spawn parameters,
  - HUD stage/segment visibility.

## Notes

- Visuals and effects are intentionally placeholder-focused.
- Current target is mechanics validation and tuning, not art/audio fidelity.

## Documentation

Project documentation now follows a project-scoped docs convention:

- Docs index: `docs/README.md`
- Project docs entrypoint: `docs/project-starkiller-prototype/README.md`
- Canonical spec: `docs/project-starkiller-prototype/2026-02-28-spec-starkiller-prototype-v1.md`
- Canonical tasks: `docs/project-starkiller-prototype/2026-02-28-tasks-session-01-05-roadmap.md`
