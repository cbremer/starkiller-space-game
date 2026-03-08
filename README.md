# Starkiller Space Game (Godot 4 Prototype)

Current prototype is a keyboard-first, Scramble-style horizontal shooter slice with stage segments, split weapon roles, and fuel pressure.
A standalone promotional landing page now lives at `web/index.html`.

## Run

1. Open this folder in **Godot 4.6.1+**.
2. Press Play (`F5`) to run `scenes/Main.tscn`.
3. Press `Enter` to start a run.
4. Default presentation uses a 1280x720 gameplay viewport upscaled to a 1920x1080 window and starts in windowed mode (`F11` toggles fullscreen).
5. From the startup `MENU`, you can change window mode or remap controls before starting the run.

## Automated Tests

Run the headless test suite:

```bash
mkdir -p /tmp/starkiller-tests && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --user-data-dir /tmp/starkiller-tests --log-file /tmp/starkiller-tests/godot.log --script res://tests/run_tests.gd
```

Current coverage includes both unit checks and scenario flows for `GameState`:
- start/pause behavior
- fuel drain -> death -> respawn
- full lifecycle through game over
- pause freeze and resume behavior

## Gameplay Names

- Hero ship: `Starkiller`
- Enemy ships: `Raider`, `Cutter`, `Binder`, `Interceptor`
- Ground units: `Walker`, `Crawler`, `Turret` (the trench cannon unit)
- Weapons: `Laser Bolt`, `Bomb Payload`, `Bomb Blast`
- Pickup: `Fuel Tank`

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
- Agreed gameplay roster:
  - hero ship: `Starkiller`
  - air enemies: `Raider`, `Cutter`, `Binder`, `Interceptor`
  - ground enemies: `Walker`, `Crawler`, `Turret` (trench cannon)
- Pause menu with instant retry and quick QoL shortcuts.
- Horizontal flight feel with ship facing right.
- Distinct weapon behavior:
  - `Laser Bolt` shots travel right and destroy air targets.
  - `Bomb Payload` drops are gravity-based and destroy ground targets.
- Enemy pressure loop with randomized spawn pacing/speeds.
- Fuel system:
  - passive fuel drain,
  - refuel zone + `R` helper,
  - collectible fuel tanks spawned by stage segment rules.
- Stage progression shell:
  - distance-based segment transitions,
  - segment-specific spawn parameters loaded from resource data (`assets/data/stage_segments.tres`),
  - HUD stage/segment visibility.
- Prototype input remapping panel for core actions (`move_*`, `fire`, `bomb`, `start`, `pause`) with local persistence.
- Startup menu includes pre-run control remapping and display mode access.
- `Bomb Payload` drops can damage both ground and air enemies (direct hit and `Bomb Blast` radius on terrain impact).
Press `Esc` to open the pause menu—resume, retry, toggle window mode, or open the remap panel; this is the editable menu you can modify while playing.

## Smoke Test

Run automated Session 5 smoke checks:

`mkdir -p /tmp/starkiller-smoke && /Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/chrisbremer/code/starkiller-space-game --user-data-dir /tmp/starkiller-smoke --log-file /tmp/starkiller-smoke/godot.log --script res://scripts/smoke_test.gd`

## Importing Images

1. Add `png` or `svg` files under `assets/` (or any project folder).
2. Open the project in Godot; the editor auto-imports new files.
3. Select the image in the FileSystem dock to view Import settings.
4. Adjust settings if needed, then click `Reimport`.

Defaults for new textures are set in `project.godot` under `[importer_defaults]`. Existing images need a manual `Reimport` to pick up changes.

## Promotional Site

Open `web/index.html` in a browser for a lightweight promo/landing page inspired by the project's retro-futurist art direction.

The page links directly to the repository and a downloadable zip of the current `main` branch.

## Notes

- Core visuals are still placeholder-driven, but Session 6 added baseline sprite/VFX/SFX readability improvements.
- Session 7 regression-hardening closeout is complete; Session 8 resource work is wrapped and Session 9 now leads manual validation and terrain polish.
- Fuel drains more slowly now (5.0 units/sec) so runs feel more manageable without manual refuel.

## Copilot / AI helpers

- No Copilot-specific configuration file is required. Use the existing project context in this README and `CLAUDE.md` for guidance.

## Documentation

Project documentation now follows a project-scoped docs convention:

- Docs index: `docs/README.md`
- Project docs entrypoint: `docs/project-starkiller-prototype/README.md`
- Canonical spec: `docs/project-starkiller-prototype/2026-02-28-spec-starkiller-prototype-v1.md`
- Latest tasks file: `docs/project-starkiller-prototype/2026-03-02-tasks-session-09-terrain-drive.md` (active Session 9 tracker; manual validation + terrain polish)
- Historical roadmap archive: `docs/project-starkiller-prototype/2026-02-28-tasks-session-01-05-roadmap.md`
