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

## Session Notes (2026-02-28)

### Implemented (Session 1 vertical slice)
- Godot 4 project scaffold with startup scene (`scenes/Main.tscn`).
- Required keyboard input actions with defaults: arrows, `Z`, `X`, `Enter`, `Esc`.
- Additional prototype-only `refuel` action on `R` for mechanic validation.
- `GameState` shell with runtime fields and transitions for start, pause, death, and timed respawn.
- Controllable placeholder player ship with bounded movement.
- HUD + debug text for state visibility and simultaneous-input readout.
- Fuel pressure loop with drain-over-time, refuel behavior, and death on zero fuel.

### Confirmed behavior in this slice
- Multi-input combinations are visible through on-screen pressed-action debug text.
- Fire and bomb are distinct actions with separate score effects and HUD action readout.
- Fuel can be replenished by entering the green refuel zone or holding `R`.
- On fuel depletion, player dies and respawns after cooldown while lives remain.

### Open assumptions for next sessions
- Current stage flow is fixed to stage `1` placeholder.
- Collision and target interaction rules are not yet implemented.
- Art/audio are placeholders and not fidelity targets yet.
