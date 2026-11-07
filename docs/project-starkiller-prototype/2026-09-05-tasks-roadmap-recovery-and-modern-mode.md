# Roadmap recovery, cleanup, and modern mode

Date: 2026-09-05
Base: remote main `83e01e6` (includes performance/respawn PR #30).
Branch: `codex/modern-mode-roadmap`.

## Reconciliation

The supplied previous conversation describes a Session 11 roadmap, Nova Burst,
and anomaly mutators as committed. Those files/features were not found in the
current remote branches or the repository's 36 PR records. The original twelve
brainstormed items cannot be reconstructed faithfully from that summary.
This is a fresh, bounded roadmap based on the available source and request.

The original local `codex/codeaudit` checkout has six modified tracked files and
an existing worktree. It was left untouched. This branch starts from current
remote main in an isolated clone; no rebase, stash, or force push was needed.

## Delivered first slice

- [x] Establish a passing baseline: 12 original scenario/unit tests.
- [x] Nova Burst: remappable C, 100 charge, 260-pixel radius. Positive score
  awards charge at 0.1 per point; Nova kills award score without recharging.
  Start/retry resets charge; death preserves it; pause, death, title state,
  insufficient charge, and stage transitions block activation.
- [x] Readable Nova HUD with a ready state and control hint.
- [x] Retro remains the default. Title Menu > Graphics or pause > 5 switches
  presentation and saves the preference separately from key bindings.
- [x] Modern prototype: four-times-resolution generated actor art with bevels,
  distinct air silhouettes, shaded fuel/ordnance, a lit planet, parallax stars,
  haze, and terrain shading. Logical sprite dimensions and collision geometry
  remain the same. New spawns respect the selected mode.
- [x] Presentation isolated in its own controller/shaders; no gameplay RNG use.
- [x] Startup art uses imported resources so exports can resolve the textures.
- [x] Key-binding saves preserve unrelated settings sections.
- [x] Fix HUD status/fuel overlaps and give Nova its own label.
- [x] CI imports assets and runs unit, smoke, and real-scene integration checks.

## Next phases, in order

| Phase | Work | Gate before continuing |
| --- | --- | --- |
| 1: Playtest this slice | Full runs in both modes, remapping, pause/retry/death; tune Nova charge/radius from feedback | Retro still feels right; controls and silhouettes stay readable; no new crashes |
| 2: Code cleanup | Extract input/menu configuration, then combat resolution from main.gd into focused components, one behavior-preserving change at a time | Real-scene lifecycle/input tests pass after each extraction; no balance changes mixed into refactors |
| 3: Modern art polish | Biome-specific planet/environment art, higher-detail terrain surfaces, improved explosions and engine trails; evaluate subtle visual banking | Compare busy scenes on target hardware; retain frame budget and hitbox clarity; test actual export |
| 4: Optional anomalies | Explicit Classic / Anomaly run choice; seeded, mild fuel/spawn modifiers; name and effect visible before starting | Classic values remain exact; deterministic tests; human pacing approval |
| 5: Encounter depth | One telegraphed elite encounter using existing enemy roles before adding a boss or progression system | Full-run pacing remains stable; readable attacks; acceptable content/support cost |

Do not introduce true 3D physics or replace the retro renderer as part of this
experiment. The current modern mode is 2.5D presentation on the same 2D game,
not HDR output or a full 3D conversion. The title artwork and much of the
terrain/background geometry are still shared. A complete art replacement is a
later phase, not claimed complete here.

## Verification

- 13 unit/scenario checks pass (including Nova lifecycle/charge rules).
- Smoke checks pass.
- Real-scene integration passes: mode switch preserves gameplay/RNG/terrain,
  texture dimensions, new-spawn mode, exact retro restoration, Nova radius and
  transition guard, pause/remap menu isolation, Nova remap reload, unrelated settings preservation,
  and preference persistence.
- GPU-rendered comparison frames captured using Godot 4.6.1, OpenGL Compatibility
  on Apple M1 Max; default Metal Forward+ integration also passed; inspected and corrected the observed HUD overlap.
- `git diff --check` passes.

Outstanding: a human full-run feel test, low-end hardware frame-time profiling,
complete exported-build validation, and reconciliation of the original local
uncommitted edits with the now-merged performance changes. Automated checks do
not establish gameplay feel or a performance guarantee.

Follow-up completed: [switchable visuals cleanup and polish](2026-09-05-tasks-switchable-visuals-cleanup.md). This supersedes the initial runtime artwork prototype and adds pack validation.
