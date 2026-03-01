#!/usr/bin/env python3
"""Generate high-fidelity planning SVG samples for Starkiller concept testing."""

from pathlib import Path
import json
import random

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets" / "concept" / "high_fidelity"
SAMPLES = BASE / "samples"
INSPIRATION = BASE / "inspiration"


def _write(path: Path, content: str) -> None:
    path.write_text(content)


def generate_samples() -> None:
    SAMPLES.mkdir(parents=True, exist_ok=True)
    INSPIRATION.mkdir(parents=True, exist_ok=True)

    for index, theme in enumerate(
        [
            "nebula_horizon",
            "planet_sunrise",
            "moon_outpost",
            "futurist_harbor",
            "retro_landscape",
            "orbital_desert",
        ],
        start=1,
    ):
        stars = "\n".join(
            [
                (
                    f'<circle cx="{random.randint(0, 1024)}" '
                    f'cy="{random.randint(0, 420)}" '
                    f'r="{random.choice([1, 1, 2])}" fill="#23b6ff" '
                    f'opacity="{random.uniform(0.4, 1):.2f}" />'
                )
                for _ in range(220)
            ]
        )
        mountains = " ".join(
            [f"{x},{random.randint(540, 760)}" for x in range(0, 1025, 64)]
        )
        sun_x = random.randint(260, 760)
        sun_y = random.randint(200, 420)
        sun_r = random.randint(120, 220)

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#070b19"/>
      <stop offset="55%" stop-color="#1c2f6f"/>
      <stop offset="100%" stop-color="#ff3f9e"/>
    </linearGradient>
    <linearGradient id="sun" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#ffd65a"/>
      <stop offset="100%" stop-color="#ff8a2a"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" fill="url(#sky)"/>
  {stars}
  <circle cx="{sun_x}" cy="{sun_y}" r="{sun_r}" fill="url(#sun)" opacity="0.95"/>
  <polygon points="0,1024 {mountains} 1024,1024" fill="#091325"/>
  <text x="24" y="998" fill="#66ffd1" font-size="24" font-family="monospace">concept_bg_{index:02d}_{theme}</text>
</svg>'''
        _write(SAMPLES / f"concept_bg_{index:02d}_{theme}.svg", svg)

    ship_shapes = []
    for i in range(6):
        ox = 30 + i * 160
        ship_shapes.append(
            f'<polygon points="{ox},140 {ox+78},110 {ox+132},140 {ox+34},178" fill="#d8ecff" stroke="#23b6ff" stroke-width="3"/>'
        )
        ship_shapes.append(
            f'<polygon points="{ox+35},141 {ox+68},125 {ox+88},141 {ox+58},158" fill="#ff3f9e" opacity="0.8"/>'
        )

    enemy_shapes = []
    for i in range(8):
        ox = 30 + i * 120
        enemy_shapes.append(
            f'<ellipse cx="{ox+45}" cy="355" rx="38" ry="24" fill="#6b78a5" stroke="#ff8a2a" stroke-width="3"/>'
        )
        enemy_shapes.append(
            f'<rect x="{ox+28}" y="374" width="34" height="20" fill="#ff8a2a"/>'
        )

    pickups = []
    for i in range(10):
        ox = 20 + i * 96
        pickups.append(
            f'<rect x="{ox}" y="540" width="52" height="52" fill="#1b2748" stroke="#66ffd1" stroke-width="3"/>'
        )
        pickups.append(
            f'<text x="{ox+19}" y="573" fill="#66ffd1" font-size="26" font-family="monospace">F</text>'
        )

    ui = []
    for i in range(4):
        ox = 32 + i * 246
        ui += [
            f'<rect x="{ox}" y="760" width="220" height="90" rx="14" fill="#141d36" stroke="#23b6ff" stroke-width="4"/>',
            f'<rect x="{ox+16}" y="806" width="188" height="14" fill="#2f416e"/>',
            f'<rect x="{ox+16}" y="806" width="{random.randint(110, 188)}" height="14" fill="#ff3f9e"/>',
        ]

    sprite_sheet = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" fill="#05070f"/>
  {''.join(ship_shapes)}
  {''.join(enemy_shapes)}
  {''.join(pickups)}
  {''.join(ui)}
  <text x="24" y="1000" fill="#66ffd1" font-size="24" font-family="monospace">sample_sprite_sheet_concepts</text>
</svg>'''
    _write(SAMPLES / "sample_sprite_sheet_concepts.svg", sprite_sheet)

    colors = ["#13203a", "#192b4d", "#223764", "#2e4a7f"]
    tiles = []
    for ty in range(0, 512, 64):
        for tx in range(0, 1024, 64):
            c = random.choice(colors)
            tiles.append(
                f'<rect x="{tx}" y="{ty}" width="64" height="64" fill="{c}"/>'
            )
            if random.random() < 0.5:
                tiles.append(
                    f'<line x1="{tx}" y1="{ty+32}" x2="{tx+64}" y2="{ty+32}" stroke="#23b6ff" stroke-opacity="0.35"/>'
                )
            if random.random() < 0.4:
                tiles.append(
                    f'<rect x="{tx+8}" y="{ty+8}" width="48" height="48" fill="none" stroke="#66ffd1" stroke-opacity="0.45" stroke-width="2"/>'
                )

    tileset = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="512" viewBox="0 0 1024 512">
  <rect width="1024" height="512" fill="#05070f"/>
  {''.join(tiles)}
</svg>'''
    _write(SAMPLES / "sample_tileset_atlas_concepts.svg", tileset)

    manifest = {
        "version": "0.1-planning",
        "generated_assets": [p.name for p in sorted(SAMPLES.glob("*.svg"))],
        "notes": "Procedural concept SVG assets for style testing. Planning-only placeholders.",
    }
    _write(SAMPLES / "manifest.json", json.dumps(manifest, indent=2))

    _write(
        INSPIRATION / "README.md",
        """# Inspiration Archive (Session 2026-03-01)

These references summarize the user-provided inspiration board and single-image examples captured in chat.

## Core motifs observed
- **Retro-futurist color cadence:** deep navy + cyan shadows, with magenta/orange highlights and hot suns.
- **Scale contrast:** tiny human/ship silhouettes versus giant skylines, moons, and ringed atmospheres.
- **Mixed rendering language:** pixel/CRT scanline scenes plus painterly cityscapes and cinematic matte-lighting.
- **World archetypes for Starkiller:** moon outposts, waterline megacities, alien gardens, dusk canyons, and neon deserts.

## Reference set
1. **Moodboard grid (25 frames):** sunset horizons, city silhouettes, scanline nebula skies, and dramatic planetary dawns.
2. **Painterly harbor megacity:** bright monumental structures beside reflective water and a giant moon backdrop.
3. **Dot-dither mountain vista:** oversized rainbow sun above alpine silhouettes and a dark star field.
4. **Terraced alien garden:** geometric stepped architecture with volumetric clouds and warm sun bloom.
5. **Moon-base cinematic frame:** pink-violet terrain, vertical spires, and an orbiting capital ship profile.

## Use guidance
- Treat this as **style direction**, not literal one-to-one targets.
- Keep gameplay readability above surface detail: projectiles, hazards, and pickups must remain high-contrast.
- Prefer layered parallax backgrounds to preserve the vast-scale feeling from references while keeping performance stable.
""",
    )


if __name__ == "__main__":
    generate_samples()
    print("Generated high-fidelity concept SVG samples.")
