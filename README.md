# Starkiller Space Game (Godot 4 Prototype)

Current prototype is a keyboard-first, Scramble-style horizontal shooter slice with stage segments, split weapon roles, and fuel pressure.

## Run

1. Open this folder in **Godot 4.6.1+**.
2. Press Play (`F5`) to run `scenes/Main.tscn`.
3. Press `Enter` to start a run.
4. Default presentation now uses a 1280x720 gameplay viewport upscaled to a 1920x1080 window.

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
- Toggle fullscreen/windowed: `F11`
- Manual refuel helper (prototype): `R`
- Pause menu shortcuts (while paused): `1` resume, `2` retry run, `3` window mode toggle, `4` remap panel

## Current Features

- Core run-state flow (`GameState`): start, pause, death, respawn.
- Pause menu with instant retry and quick QoL shortcuts.
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
- Prototype input remapping panel for core actions (`move_*`, `fire`, `bomb`, `start`, `pause`) with local persistence.
- Bombs can damage both ground and air enemies (direct hit and blast radius on terrain impact).

## Smoke Test

Run automated Session 5 smoke checks:

`mkdir -p /tmp/starkiller-smoke && /Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/chrisbremer/code/starkiller-space-game --user-data-dir /tmp/starkiller-smoke --log-file /tmp/starkiller-smoke/godot.log --script res://scripts/smoke_test.gd`

## Notes

- Visuals and effects are intentionally placeholder-focused.
- Current target is mechanics validation and tuning, not art/audio fidelity.

## Copilot / AI helpers

- No Copilot-specific configuration file is required. Use the existing project context in this README and `CLAUDE.md` for guidance.

## Documentation

Project documentation now follows a project-scoped docs convention:

- Docs index: `docs/README.md`
- Project docs entrypoint: `docs/project-starkiller-prototype/README.md`
- Canonical spec: `docs/project-starkiller-prototype/2026-02-28-spec-starkiller-prototype-v1.md`
- Canonical tasks: `docs/project-starkiller-prototype/2026-02-28-tasks-session-01-05-roadmap.md`
