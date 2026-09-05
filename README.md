# Starkiller Space Game (Godot 4 Prototype)

Current prototype is a keyboard-first, Scramble-style horizontal shooter slice with stage segments, split weapon roles, and fuel pressure.
A standalone promotional landing page now lives at `web/index.html`.

## Run

1. Open this folder in **Godot 4.6.1+**.
2. Press Play (`F5`) to run `scenes/Main.tscn`.
3. Press `Enter` to start a run.
4. Default presentation uses a 1920x1080 gameplay viewport and window and starts in windowed mode (`F11` toggles fullscreen).
5. From startup `SETTINGS`, you can change graphics (Retro / Modern), change window mode, or remap controls before starting the run.

## Nova and presentation

`C` activates Nova when the HUD reads **NOVA READY** (remappable in Controls). Score charges it; the burst destroys nearby enemies within 260 pixels. Nova kills do not recharge it.

Retro is the default. Open **Settings** on the title screen, or press **Esc** during play and choose **Settings** (5). The graphics button inside Settings switches between Retro and Modern and remembers your selection. Returning from Settings keeps the run paused until you resume.

Choose **Quit Game** on the title or pause screen to exit. It is also selectable with Up/Down + Enter on the title, or **6** while paused.

Modern is a 2.5D art presentation with imported high-resolution actors, a ringed planet, atmospheric depth, shaded terrain, ship banking, and richer weapon effects. Gameplay and collision sizes are shared.

The latest [cleanup and validation notes](docs/project-starkiller-prototype/2026-09-05-tasks-switchable-visuals-cleanup.md) document module boundaries and exported-pack checks.

## Automated Tests

Import assets once after a fresh clone (`godot --headless --editor --path . --import --quit`), then run the headless test suite:

```bash
mkdir -p /tmp/starkiller-tests && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/starkiller-tests/godot.log --script res://tests/run_tests.gd
```

Also run `godot --headless --path . --script res://scripts/smoke_test.gd` and `godot --headless --path . --script res://tests/presentation_integration.gd`.

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

`mkdir -p /tmp/starkiller-smoke && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/starkiller-smoke/godot.log --script res://scripts/smoke_test.gd`

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
- Latest tasks file: [Roadmap recovery and modern mode](docs/project-starkiller-prototype/2026-09-05-tasks-roadmap-recovery-and-modern-mode.md)
- Historical roadmap archive: `docs/project-starkiller-prototype/2026-02-28-tasks-session-01-05-roadmap.md`
