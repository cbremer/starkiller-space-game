# Session 7 Tasks - Regression Hardening

Date: 2026-03-01
Source: Post-Session 6 baseline + unresolved human-validation items from Sessions 3-6.

## Goal

Stabilize the current prototype for repeatable playtesting and close documentation/tracking gaps.

## Scope (Session 7)

1. `Human` - Complete validation backlog from earlier sessions
- Run progression pacing review (Session 3 carry-over).
- Run usability review for pause/menu/remap flow (Session 4 carry-over).
- Run focused bug bash and rank issues by severity/impact (Session 5 carry-over).

2. `AI Agent` - Close top-priority defects from validation
- Address high-impact defects found in Session 7 validation.
- Keep fixes scoped to regression hardening (no major feature expansion).

3. `Human + AI Agent` - Lock presentation defaults
- Decide startup preference: fullscreen vs windowed.
- Apply decision in `project.godot` and reflect it in docs.

4. `AI Agent` - Keep regression checks green
- Run automated tests (`tests/run_tests.gd`) and smoke checks (`scripts/smoke_test.gd`).
- Fix regressions introduced during Session 7 fixes.

5. `AI Agent` - Keep docs synchronized
- Maintain this file as the active session tracker.
- Keep spec, README, and docs timeline aligned with validated behavior and decisions.

## Acceptance Criteria

- Validation backlog items are completed or explicitly deferred with rationale.
- Startup display preference decision is recorded and applied.
- Automated tests and smoke checks pass after Session 7 fixes.
- Project docs consistently identify Session 7 as the active tracker.

## Execution Checklist (Live)

Last updated: 2026-03-01
Branch: `main`

- [ ] Human playtest progression pacing and difficulty spikes.
- [ ] Human validate pause/menu/remap usability and preference decisions.
- [ ] Human run focused bug bash and prioritize top issues.
- [ ] Set startup fullscreen/windowed default from validation decision.
- [x] Automated smoke checks pass (`scripts/smoke_test.gd`).
- [x] Automated unit/scenario tests pass (`tests/run_tests.gd`).
- [ ] Apply and verify top-priority regression fixes from Session 7 bug bash.
- [ ] Update spec + READMEs + timeline after validation decisions.
