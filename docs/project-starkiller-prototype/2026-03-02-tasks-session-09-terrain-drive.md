# Session 9 Tasks - Terrain Drive + Validation Follow-up

Date: 2026-03-02
Source: Session 8 handoff + manual validation backlog.

## Goal

Drive terrain/geometry polish and document the manual validation findings that Session 8 deferred.

## Scope (Session 9)

1. `Human` - Complete deferred manual validation
- Playtest progression pacing + difficulty spikes.
- Validate pause menu/remap workflow on macOS windowed/fullscreen.
- Run a focused bug bash and capture any new issues that surfaced after the stage-segment resource switch.

2. `AI Agent` - Terrain/segment alignment
- Introduce stage-specific terrain bands or data-driven terrain offsets so the resource-driven segment data controls both spawns and collision bounds.
- Ensure terrain heights remain readable after stage data changes (include bounding box/clearance checks if necessary).

3. `AI Agent` - Stabilize menu/terrain interactions
- Add guardrails so entering/removing the pause menu or remap panel does not trigger unintended stage transitions or timers.
- Confirm `Esc`/pause stays responsive after stage progress metrics update from the new data.

4. `AI Agent` - Keep docs/tests aligned
- Keep this file as the active Session 9 tracker.
- Update README/spec if any manual validation notes or terrain decisions become permanent.
- Re-run automated tests/smoke checks if any code changes land from manual validation findings.

## Acceptance Criteria

- Manual validation backlog is completed or explicitly deferred with notes in this doc.
- Terrain/segment visuals remain readable and grounded in the new resource data.
- Pause/remap menu stays stable during stage transitions.
- Documentation names this file as the active tracker.

## Execution Checklist (Live)

Last updated: 2026-03-01
Branch: `codex/session9-terrain-redux`

- [ ] Human playtest progression pacing and difficulty spikes.
- [ ] Human validate pause/menu/remap usability and preference decisions.
- [ ] Human run focused bug bash and prioritize top issues.
- [ ] Apply top-priority fixes from Session 9 manual validation.
- [ ] Introduce stage-specific terrain/logic tied to the resource data.
- [ ] Harden pause/remap menu stability during stage updates.
- [ ] Update README/spec/timeline with Session 9 findings.
- [ ] Rerun automated tests + smoke checks if code changes land.
