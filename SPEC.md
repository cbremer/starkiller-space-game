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
