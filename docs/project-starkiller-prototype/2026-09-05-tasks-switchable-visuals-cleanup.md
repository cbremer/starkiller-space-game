# Switchable visuals: cleanup and modern polish

## Delivered

- Added an always-visible top-right graphics button on title, gameplay, pause,
  and game-over screens. Its label shows the look you can switch to. Mouse
  clicks use the existing saved preference; keyboard focus stays with gameplay.

- Extracted key definitions, validation, and InputMap helpers from main into
  `scripts/input_profile.gd`; menu/persistence coordination stays in main.
- Replaced runtime SVG generation with eleven imported SVG actor assets and a
  small `modern_textures.gd` mapping. Original sprite scale/filter/texture are
  restored exactly, with no accumulated scale changes across switches.
- Modern environment processing sleeps in retro mode; shader values update only
  when distance, sector, or viewport changes. Aspect ratio is viewport-derived.
- Unified graphics-change notifications so HUD and menus always match the mode.
- F8 toggles looks from title or during play without pausing or resetting a run.
  It is remappable in Controls; remap capture is protected from the shortcut.
  Title Graphics and pause 5 remain available; preference persists.
- Modern terrain/ceiling use a shared shaded-surface painter on the original
  ridge coordinates. Modern hills use polygons instead of pixel columns.
- Added planet rings, stronger engine/laser glow, visual-only ship banking,
  antialiased burst rings, and spark trails. Retro rendering branches retained.
- Stop pooled audio when the game scene exits; tests allow mixer release before
  shutdown, eliminating the observed leaked-playback warning.

## Verification

13 original/Nova scenario checks and smoke checks pass. Integration covers live
F8 toggling, repeated mode changes, all eleven actor bounds/restoration, every
biome's terrain/ceiling collision, fresh-scene preference reload, remap
persistence, pause/remap isolation, Nova lifecycle/range, and unaffected RNG.

Rendered on Metal Forward+ and OpenGL Compatibility; comparison frames inspected.
A validation PCK export also runs the integration suite independently of the
source checkout. This verifies resource packaging, not a signed desktop installer.

Reproduce pack validation with Godot 4.6.1:

```sh
godot --headless --path . --export-pack 'Validation Pack' /tmp/starkiller-validation.pck
godot --headless --main-pack /tmp/starkiller-validation.pck --script res://tests/presentation_integration.gd
```

## Remaining scope

Modern is a playable 2.5D presentation, not a true 3D engine conversion. Collision,
movement, progression, and combat balance are shared. Human full-run feel checks,
low-end hardware profiling, and signed desktop distribution remain separate.
The prior roadmap's optional anomalies and new encounters remain deferred.
