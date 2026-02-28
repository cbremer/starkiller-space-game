# Scramble Desktop App Discovery Plan (macOS, Keyboard, Godot)

## Summary
Build a research-first foundation for a Scramble-inspired desktop app by creating a raw-but-structured notebook at `brainstorm.md`.
The notebook will capture verified history, style references, gameplay dynamics, keyboard control behavior, and a media index (links only), then convert that into implementation-ready hypotheses for a Godot desktop build.

## Scope
1. Deep research on original Scramble (history, presentation, mechanics, controls).
2. Media gathering for analysis (screenshots and recordings as URLs, not downloaded files).
3. Raw idea capture and system hypotheses inside one evolving notebook.
4. Initial implementation contract for a future arcade-faithful + QoL build.

## Deliverable Structure (`brainstorm.md`)
1. `Goal + Constraints`
2. `History Timeline`
3. `Visual Style Notes`
4. `Audio Style Notes`
5. `Mechanics Matrix`
6. `Controls + Input Behavior`
7. `Screenshots Index (URLs)`
8. `Recordings Index (URLs + timestamps)`
9. `Raw Idea Pile`
10. `Open Questions + Risk Log`
11. `Prototype Hypotheses (Godot)`

Entry template for all research notes:
- `Source`
- `Claim/Observation`
- `Evidence`
- `Confidence (High/Med/Low)`
- `Idea Trigger`

## Research Execution Plan

### Phase 1: Seed Source Pack
Collect and log at least 12 high-signal sources, starting with:
- [Wikipedia: Scramble](https://en.wikipedia.org/wiki/Scramble_(video_game))
- [CBR history article](https://www.cbr.com/konami-scramble-helped-save-video-game-industry/)
- [Arcade Museum: Scramble](https://www.arcade-museum.com/Videogame/scramble)
- [Arcade flyer PDF 1](https://www.arcade-museum.com/images-game/35/scramble-16873150.pdf)
- [Arcade flyer PDF 2](https://www.arcade-museum.com/images-game/35/scramble-16873168.pdf)
- [MAMEWorld operator manual thread](https://mameworld.info/ubbthreads/showflat.php?Cat=&Number=349080&page=0&view=expanded&sb=5&o=&vc=1)
- [Manual extraction page](https://www.manuals.plus/m/f8ffae0bc2dc6f32b6f1ad4f85de2f6fda0f8eff3004dc5ea910f1cfca677d95)
- [MobyGames: Scramble](https://www.mobygames.com/game/4910/scramble/)
- [GamesDatabase: Scramble](https://www.gamesdatabase.org/game/arcade/scramble)
- [GameFAQs video index](https://gamefaqs.gamespot.com/arcade/569617-scramble/videos)
- [YouTube playlist reference](https://www.youtube.com/playlist?list=PLNJCXVOcGKXKug5MMjR2R2YQBQck8lWma)
- [Stage maps / cheat context](https://gamefools.com/pcgamecheats/scramble.html)

### Phase 2: History + Style Extraction
1. Build a dated timeline: release, regional publishing, known ports/clones, legal moments, legacy.
2. Capture style signals: HUD language, terrain silhouette logic, enemy readability, color usage, pacing rhythm.
3. Extract visual motifs from flyers/cabinet/screenshot sets and label which are "must-keep" vs "optional homage".

### Phase 3: Gameplay Dynamics Reverse-Spec
1. Define the core loop with explicit state transitions: spawn, flight, fuel pressure, scoring, death, respawn, stage advance.
2. Build a mechanics matrix with rule-level entries:
- movement behavior
- fire vs bomb usage split
- terrain and enemy collision rules
- fuel depletion and refuel trigger behavior
- scoring events and multipliers
- stage segment progression and looping
3. For each rule, attach at least one source and one confidence tag.

### Phase 4: Input + Desktop Control Plan
1. Lock keyboard defaults:
- `Arrow Keys` movement
- `Z` fire
- `X` bomb
- `Enter` start
- `Esc` pause
2. Define QoL options (optional toggles):
- remapping
- pause + instant retry
- windowed/fullscreen
3. Document simultaneous input expectations (movement + fire + bomb combos).

### Phase 5: Media Index Targets
1. Log at least 20 screenshot URLs with source labels.
2. Log at least 10 recording URLs and at least 3 timestamps each for mechanic evidence.
3. Keep media links-only; no local asset downloads in this phase.

## Planned Public Interfaces / Types (for implementation phase)
1. `InputAction` enum: `MOVE_UP`, `MOVE_DOWN`, `MOVE_LEFT`, `MOVE_RIGHT`, `FIRE`, `BOMB`, `START`, `PAUSE`.
2. `GameState` model: `score`, `lives`, `fuel`, `stage_id`, `distance`, `is_alive`, `is_paused`.
3. `StageSegment` schema: `segment_type`, `length`, `terrain_profile`, `spawn_table`, `fuel_tank_density`.
4. `RuleSpec` record: `rule_id`, `description`, `source_links`, `confidence`, `test_case_ids`.
5. `EvidenceLink` record: `url`, `source_type`, `timestamp_or_frame`, `note`.

## Test Cases and Acceptance Scenarios

### Research Quality Checks
1. Every non-trivial mechanics claim has citation coverage:
- either one primary source (manual/flyer/operator doc), or
- two independent secondary sources.
2. Conflicting claims are preserved, not discarded, and marked with confidence levels.
3. `brainstorm.md` contains no uncited "final rule" statements.

### Gameplay Spec Checks
1. Fuel behavior is testable from the notes (drain rate logic + replenishment trigger conditions).
2. Weapon split is testable (air-target vs ground-target handling and limitations).
3. Collision and death conditions are testable for terrain, enemy contact, and projectile impact.
4. Stage progression/loop behavior is testable from collected evidence.

### Input/UX Checks
1. Keyboard mapping supports simultaneous movement + action keys.
2. Start/pause/retry flow is fully described for desktop play.
3. Remapping is flagged as optional QoL, not required for first playable build.

## Assumptions and Defaults (Locked)
1. Fidelity target: `Arcade-faithful + QoL`.
2. Stack target: `Godot 4 + GDScript`.
3. Asset policy: `Reference-only` for original Scramble media.
4. Brainstorm format: `Structured raw notebook`.
5. Media handling: `Links-only index` during research phase.
6. Platform focus: macOS desktop on Apple Silicon hardware (performance constraints are not a blocker in phase 1).
