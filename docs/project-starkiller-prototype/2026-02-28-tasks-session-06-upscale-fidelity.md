# Session 6 Tasks - Upscale + Fidelity

Date: 2026-02-28
Source: Session 5 outcomes + current prototype presentation gaps

## Status

- Session 6 baseline pass completed.
- Remaining human follow-up decisions (style direction validation and startup fullscreen/windowed preference) are tracked in:
  - `docs/project-starkiller-prototype/2026-03-01-tasks-session-07-regression-hardening.md`

## Goal

Make the game read as a larger, clearer desktop experience and reduce prototype-level lo-fi presentation.

## Problem Statement

Current build feels small and placeholder-heavy because:
- Display/window sizing and stretch behavior are not yet tuned for larger desktop play.
- Most gameplay actors are still simple debug-style vector shapes.
- Visual effects and audio layers are minimal.
- HUD and menu typography/layout are functional but not presentation-grade.

## Scope (Session 6)

1. `AI Agent` - Upscale baseline display and rendering strategy
- Add explicit desktop defaults in `project.godot`:
  - base size (target `1920x1080`),
  - stretch mode/aspect policy for consistent scaling,
  - fullscreen/windowed startup preference (decision from playtest).
- Ensure gameplay bounds and spawn logic still behave correctly at larger viewport sizes.

2. `AI Agent` - Increase readability of HUD/menus at larger resolutions
- Convert hard-coded panel offsets to scalable anchors/containers where needed.
- Add font sizing and spacing pass for HUD, pause menu, and remap panel.
- Validate legibility at both windowed and fullscreen.

3. `AI Agent` - Replace core placeholder visuals
- Swap ship, enemy, fuel tank, bomb, and projectile debug shapes for sprite-based placeholders.
- Add layered terrain/background art pass that keeps gameplay readability.
- Preserve collision fairness while upgrading visuals.

4. `AI Agent` - Add presentation feedback pass (VFX + audio)
- Add basic SFX set: fire, bomb drop, impact, enemy destruction, fuel pickup, death.
- Add lightweight VFX: impact flash, explosion particles, short screen shake on major hits.
- Tune effect intensity so combat feedback is clear without visual noise.

5. `Human` - Art direction and readability review
- Validate overall look: less lo-fi, still arcade-readable.
- Decide style direction (clean vector arcade vs textured retro).
- Record asset and polish preferences for Session 7 follow-up.

6. `AI Agent` - Update docs
- Update `SPEC.md`, `README.md`, and roadmap status with final decisions and defaults.

## Acceptance Criteria

- Game is comfortably playable on desktop at a larger presentation scale.
- UI remains readable in fullscreen and windowed mode.
- Core actors are no longer dominated by debug-shape visuals.
- Audio and hit feedback clearly communicate combat events.
- Docs reflect finalized upscale/fidelity decisions.

## Less-Lo-Fi Checklist (Execution Order)

- [x] Set display defaults (window override + stretch policy, fullscreen preference still pending).
- [x] Rework UI anchors/sizing for scalable layouts (initial pass).
- [x] Introduce sprite placeholders for all core actors.
- [x] Add effects/audio for fire, bomb, impacts, and destruction.
- [x] Run readability pass and adjust contrast/color hierarchy (initial pass).
- [x] Update docs with final fidelity direction.
