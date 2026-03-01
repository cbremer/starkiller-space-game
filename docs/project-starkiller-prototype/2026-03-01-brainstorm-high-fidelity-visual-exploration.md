# Brainstorm: High-Fidelity Visual Exploration (Planning)

## Intent

Capture the latest visual inspiration set and create testable concept assets so we can evaluate a higher-fidelity look-and-feel without disrupting current prototype gameplay iteration.

## What was archived

User-provided references were distilled into a style archive at:

- `assets/concept/high_fidelity/inspiration/README.md`

The archive captures recurring motifs:

- retro-futurist dusk palette (deep blues, cyan shadows, magenta/orange highlights)
- high scale contrast (small actors vs giant worlds)
- mixed rendering language (pixel/dither + painterly cityscape + cinematic matte lighting)

## Generated sample assets (planning)

A procedural concept pack was generated into:

- `assets/concept/high_fidelity/samples/`

Included sample categories:

- 6 background concept frames
- 1 sprite-sheet concept page (ships, enemies, fuel pickups, UI bars)
- 1 tileset atlas concept page
- JSON manifest for quick indexing

Generation script:

- `scripts/generate_high_fidelity_concept_svgs.py`

## Worktree setup for isolated art exploration

Created a dedicated worktree for high-fidelity experimentation:

- Path: `../starkiller-space-game-high-fidelity`
- Branch: `artlab/high-fidelity-concepts`

This allows art-direction and content experiments to run in parallel with core gameplay prototype work.

## Suggested next planning steps

1. Import sample backgrounds as temporary parallax layers in a sandbox scene and check readability.
2. Test sprite-sheet silhouettes at gameplay camera scale (enemy bullet clarity first).
3. Establish 2–3 approved palettes (combat, exploration, boss biome).
4. Define memory/performance budgets before committing to high-detail texture workflows.
