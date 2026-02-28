# TASKS

Date: 2026-02-27
Source: `SPEC.md` + current repo state

## Project Stage Assessment

Current progression stage:
- Environment setup (primary)
- Minimal change (secondary)

Why this is the right stage:
- The repo currently has planning docs only (`SPEC.md`, `BRAINSTORM.md`) and no Godot project files yet.
- Highest value now is to unblock the build/run loop and prove technical assumptions (Godot 4 desktop input + core state flow).

Single-session scope target:
- Deliver one runnable vertical slice that proves the dev loop and core control/state architecture.
- Avoid full gameplay implementation in this first coding session.

## Session 1 (Next AI Coding Session): Foundation Vertical Slice

Goal:
- Stand up a playable skeleton that demonstrates keyboard controls, game state flow, and HUD updates.

### Tasks (ordered, actionable)

1. `AI Agent` - Initialize Godot 4 project scaffold
- Create project structure (`project.godot`, `scenes/`, `scripts/`, `ui/`, `assets/placeholders/`).
- Add a main scene and set it as startup scene.
- Done when project opens and runs without errors.

2. `AI Agent` - Implement input map defaults from spec
- Add actions: `move_up`, `move_down`, `move_left`, `move_right`, `fire`, `bomb`, `start`, `pause`.
- Map keys: arrows, `Z`, `X`, `Enter`, `Esc`.
- Ensure simultaneous key presses are supported by logic (movement + fire/bomb).
- Done when an on-screen debug readout confirms multi-input combinations.

3. `AI Agent` - Build minimal state model and game loop shell
- Create `GameState` script with: `score`, `lives`, `fuel`, `stage_id`, `is_alive`, `is_paused`.
- Implement state transitions for: start run, pause/unpause, death, respawn cooldown.
- Done when state changes can be triggered and observed in UI.

4. `AI Agent` - Add controllable player ship placeholder
- Implement keyboard movement inside bounded play area.
- Wire `fire` and `bomb` as separate actions (projectile visuals can be placeholders).
- Done when controls are responsive and distinct actions are visible in logs/UI.

5. `AI Agent` - Add first-pass HUD
- Display score, lives, fuel, stage, paused state, alive/dead state.
- Update values live from `GameState`.
- Done when HUD reflects real-time state changes.

6. `AI Agent` - Add simple fuel pressure prototype
- Implement fuel drain over time.
- Add temporary refuel trigger zone or key for validation (placeholder mechanic).
- Trigger death when fuel reaches zero.
- Done when fuel loop is testable end-to-end.

7. `Human` - Run playtest and tune defaults
- Verify feel of movement speed, fuel drain rate, and respawn timing.
- Confirm key mapping is comfortable on your keyboard.
- Record tuning decisions in notes.

8. `AI Agent` - Add session notes directly to spec docs
- Update `SPEC.md` based on what we've implemented.

9. `AI Agent` - Update project docs
- Update documentation (`README.md`, etc.) based on what we've implemented.

### Session 1 acceptance criteria
- Project boots in Godot and runs on macOS.
- Required default keys function as specified.
- HUD and game-state transitions are visible and coherent.
- Fuel pressure loop works (drain -> zero -> death/respawn path).
- Spec and docs are updated to match implementation.

## Multi-Session Follow-up Plan

## Session 2: Core Combat + Collision Rules

Goal:
- Make core moment-to-moment gameplay credible.

Tasks:
1. `AI Agent` - Add enemy and terrain collision handling (ship, projectile, bomb).
2. `AI Agent` - Split air vs ground target interactions for fire vs bomb behavior.
3. `AI Agent` - Add scoring events for core actions.
4. `Human` - Validate collisions feel fair; list mismatches vs reference behavior.
5. `AI Agent` - Update `SPEC.md` and docs.

## Session 3: Stage Flow + Progression

Goal:
- Prove the run can progress through stage segments.

Tasks:
1. `AI Agent` - Introduce `StageSegment` data structure and segment loader.
2. `AI Agent` - Implement scrolling progression and stage transition conditions.
3. `AI Agent` - Add fuel tank spawn/refuel behavior tied to segment rules.
4. `Human` - Playtest progression pacing and difficulty spikes.
5. `AI Agent` - Update `SPEC.md` and docs.

## Session 4: QoL + Usability

Goal:
- Add prototype-level quality-of-life features promised in spec.

Tasks:
1. `AI Agent` - Add pause menu with instant retry.
2. `AI Agent` - Add windowed/fullscreen toggle.
3. `AI Agent` - Add basic input remapping UI (prototype grade).
4. `Human` - Validate usability and provide preference decisions.
5. `AI Agent` - Update `SPEC.md` and docs.

## Session 5: Prototype Hardening

Goal:
- Stabilize for repeatable playtesting.

Tasks:
1. `AI Agent` - Remove known technical debt from earlier sessions.
2. `AI Agent` - Add lightweight regression checklist/test script for critical loops.
3. `Human` - Run a focused bug bash and prioritize issues.
4. `AI Agent` - Fix top-priority defects within session budget.
5. `AI Agent` - Update `SPEC.md` and docs.

## Working agreements for each session

- Keep each session focused on one vertical slice.
- End every session with runnable state and updated docs.
- Track assumptions vs confirmed behavior explicitly in `SPEC.md`.
