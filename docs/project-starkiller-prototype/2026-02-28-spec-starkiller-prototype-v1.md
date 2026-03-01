# Current Spec

## App Purpose
- This app is for retro arcade players and Scramble fans who want a faithful desktop experience.
- It lets them have fun playing a Scramble-inspired side-scrolling shooter with modern desktop quality-of-life options.

## Current Fidelity
- The current fidelity is a `prototype`.
- Product direction is `Arcade-faithful + QoL`: preserve core classic behavior and add optional convenience features.

## Form Factor
- The app is a `desktop app` for `macOS` (Apple Silicon first).
- Input is keyboard-first.

## Most Important Features
- Core game loop with clear states: spawn, flight, fuel pressure, scoring, death/respawn, and stage progression.
- Keyboard controls with simultaneous input support using Arrow Keys movement, `Z` fire, `X` bomb, `Enter` start, and `Esc` pause.
- HUD and run-state visibility for score, lives, fuel, stage progress, paused state, and alive/dead state.
- Optional QoL settings: remapping, instant retry, and windowed/fullscreen toggles.
- Rule-driven gameplay behavior that is evidence-backed for fuel logic, weapon split, collision/death, and progression.

## Key Technology Choices
### Language, Framework, and Cloud
- Preferred language: `GDScript`
- Preferred framework/engine: `Godot 4`
- Preferred cloud provider: none required for current scope

### Packages and Libraries Researched
- Godot built-in systems for input mapping, scenes, collision/physics, audio, and UI.
- No external package dependency is required for the first playable prototype.

### Cloud Services Researched
- Database: none
- Application hosting: none
- Other services: none

## Scope Boundaries
- Single-player only.
- Local/offline play only.
- Keyboard control only in initial implementation.
- Original Scramble media is reference-only for research; shipped assets must be original or properly licensed.

## Spec Readiness Criteria
- Requirements are specific enough for an AI coding agent to decompose into phased implementation tasks.
- Core mechanics and control behavior are explicit and testable without additional product clarification.

## Session Notes (2026-03-01)

### Implemented (Sessions 1-6)
- Godot project scaffold with startup scene (`scenes/Main.tscn`) and Godot 4.6.1 compatibility fixes.
- Required keyboard input actions with defaults: arrows, `Z`, `X`, `Enter`, `Esc`.
- Prototype `refuel` action on `R` retained for quick fuel-loop validation.
- `GameState` model with start, pause, death, respawn, and stage tracking.
- Horizontal flight orientation (ship faces right, combat flows left-to-right).
- Split weapon roles:
  - `Z` laser for air targets.
  - `X` gravity-drop bombs for ground targets.
- Combat loop:
  - air and ground target spawning,
  - collision and score events,
  - ship damage on air-target contact.
- Fuel pressure loop:
  - passive drain,
  - refuel zone/manual refuel helper,
  - moving fuel tanks that restore fuel when collected.
- Stage progression shell:
  - segment data model in `main.gd`,
  - distance-based segment advancement,
  - per-segment spawn tuning and fuel-tank cadence.
- QoL usability layer:
  - pause menu overlay with instant retry shortcut,
  - fullscreen/windowed toggle on `F11` (plus pause-menu shortcut),
  - prototype input remap panel for core gameplay actions,
  - local persistence for remapped controls (`user://settings.cfg`).
- Session 5 hardening:
  - smoke-test script for input/state/combat rules (`scripts/smoke_test.gd`),
  - bomb interactions expanded so bombs can damage both air and ground targets.
- Session 6 baseline fidelity pass:
  - 1280x720 gameplay viewport upscaled to 1920x1080 window defaults,
  - scalable HUD/pause/remap layout pass,
  - sprite-based placeholders for core actors,
  - foundational VFX/SFX feedback (impact flash, explosion particles, procedural cues, screen shake).

### Confirmed behavior in current prototype
- Multi-input combinations are visible through on-screen pressed-action debug text.
- Fire and bomb are mechanically and visually distinct.
- Bombing flow matches drop-style behavior (forward travel plus gravity fall) rather than radial blast.
- Stage indicator and segment name update as the run advances through segment distances.
- Pause menu controls work during active runs (`1` resume, `2` retry, `3` window mode, `4` remap panel).
- Input remapping can rebind and reset core actions at runtime.
- Remapped controls persist across restarts.
- Bombs can damage flying enemies via direct contact and terrain-impact blast radius.
- Headless checks currently pass:
  - `tests/run_tests.gd` (8 passed, 0 failed),
  - `scripts/smoke_test.gd` (pass).

### Open assumptions and active gaps (Session 7)
- Terrain geometry and terrain collision are still placeholder-driven.
- Stage segments are data-driven but currently script-local (not externalized resources yet).
- Art direction baseline is established, but production-quality asset pipeline decisions are not finalized.
- Human validation backlog remains for pacing, usability preferences, and focused bug-bash triage.
- Startup default preference (fullscreen vs windowed) still needs final decision from playtesting.

### Active next phase (Session 7)
- Complete validation backlog and prioritize issues.
- Apply top-priority regression fixes within Session 7 scope.
- Lock startup window mode default and reflect it in config/docs.
- Keep spec + README + task trackers synchronized.
