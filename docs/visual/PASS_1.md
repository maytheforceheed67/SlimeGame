# Visual overhaul, Pass 1: toon material and outlines

Pass 1 of [docs/VISUAL_STYLE.md](../VISUAL_STYLE.md): the shared toon
material, ink lines with smoothed normals, the key light, re-thresholded
shadows and blob shadows, applied to everything on screen. Models, the cave's
shape, animation, effects, camera and UI are untouched; they belong to
passes 2 to 8.

Screenshots: [pass_1/](pass_1/). Compare with [pass_0/](pass_0/).

## 1. Your three decisions, applied

| Decision | What changed |
|---|---|
| Renderer: Compatibility | `project.godot` now uses `gl_compatibility`. What I check in screenshots is what the game shows |
| Wisdom cards: keep both, word the second as the step up | The second card's face reads "Deepens Sage into Great Sage (alone: Extra skill: Sage)". The Voice says "Sage deepens into Great Sage" when both are chosen and "Extra skill: Sage" when it is chosen alone, which is what it then grants. The data validator now refuses two cards that would show the same result |
| Slime face on by default | `slime.face_enabled` is `true` in the visual config. The face itself is built in Pass 2 |

## 2. What was built

| The document asks for | In this project |
|---|---|
| `makeToon(options)`, one factory | The **Toon** autoload (`scripts/visual/toon.gd`). No other script makes a material; none is left on a standard material |
| Shade tint, band threshold and softness, optional mid band, rim, hard highlight, emissive, flash | All present as options or config values. `biasMask` is not built yet: no mesh needs it until the models of passes 2 to 5 |
| Character light that ignores scene lights (S8) | `toon_character.gdshader`: unshaded, lit from a fixed direction relative to the camera |
| Softer world shading from the key light (S9) | `toon_world.gdshader`: softer band, cast shadow folded into the band before the threshold, the palette's "light cap" on upward faces, a soft pool of colour near lamps |
| Hull outline, constant in pixels, smoothed normals, distance cap, small-object fade, colour by rule, vertex-colour width | `outline.gdshader` as the toon material's next pass; `MeshKit` bakes one averaged normal per position into `CUSTOM0` |
| One shadow-casting key light, re-thresholded | A `DirectionalLight3D` made by the level and set by `WorldLook`; two shadow splits; edge re-thresholded at 0.45 to 0.55 |
| Blob shadows in one draw | `BlobShadows`: one `MultiMesh` for the slime, creatures, remains and pickups; fades and grows with height |
| Applied to everything on screen | Slime, Veldora, the seal, five creatures and their Mimicry forms, herbs, ore, motes, crystals, rock, lake, projectiles, attack telegraphs, the missing-asset marker |
| `toonify(root)` for loaded files | `Toon.dress_model`, run by the asset manager when a manifest entry has `"toonify": true`; `outline_px` and `cast_shadow` are honoured for files and stand-ins alike |

New files:

```
scripts/visual/
  toon.gd                  Toon autoload: the material factory
  mesh_kit.gd              shared unit shapes, smoothed normals, mesh baking
  blob_shadows.gd          one disc under every actor
  shaders/
    toon_character.gdshader
    toon_world.gdshader
    outline.gdshader
    veil.gdshader          see-through two-tone surface: seal, lake, telegraphs
    blob_shadow.gdshader
```

The cave scene no longer carries materials. `tools/build_sealed_cave.py`
writes a `look` tag on each piece and the level turns tags into toon materials
from the palette. I checked the regenerated scene against the old one: the
same 216 nodes, kinds, transforms and 53 collision shapes.

Models that never move their parts (Veldora, herbs, ore) are baked into one
mesh per material, shared by every copy.

## 3. What the Compatibility renderer does, and how it is handled

I tested each of these in a small scene before relying on it.

| Finding | Consequence |
|---|---|
| A shadow-casting light is drawn as a second pass and added on top of the first after colour encoding | A colour split across the two passes does not add up to the palette colour. The world shader writes tone, rim, highlight, flash and fog all in the key light's pass, and the engine's fog is switched off for it and applied by hand from two global shader values that `WorldLook` keeps in step with the Environment |
| Bloom only sees the first pass | Glow is the one thing the world shader leaves in the first pass |
| Light cull masks do nothing to a directional light | Characters cannot be given a separate light by layer. The character shader takes its light direction as a value instead, which also makes it one draw instead of two |
| With bloom on, colours are stored scaled down | A multiplying blend darkens everything it touches. Blob shadows are blended over the ground in the palette's rock shade instead |
| A next-pass outline is also drawn into the shadow map | The outline does not write depth, which keeps it out; a render priority draws it after see-through surfaces |
| There is no FXAA | `renderer.antialiasing: "fxaa"` means 2x multisampling here |

## 4. Acceptance

| Done when | Result |
|---|---|
| Every object is two-tone with a tinted shade | Yes. See `pass_1/02_slime_closeup.png` and `06_combat_hit.png`. A test walks the running game and fails if any mesh is not on one of the five shaders |
| Outline width holds near and far | Yes. `pass_1/outline_distance.png` lines up six slimes. The target is 1.67 px at 720p (2.5 px at 1080p). Measured across the left edge: 1.4, 1.6, 1.6 and 1.7 px at 6, 12, 18 and 26 m, then 0.7 px at 38 m, where the line is meant to thin and fade (beyond 25 m, and under 12 px tall) |
| No split hulls | Yes. Boxes and cones keep a closed line at their corners (the lizard, the crystals, the ore). A test checks that the three faces at a cube's corner carry the same smoothed normal |
| No shadow speckle | Yes, after two fixes found in screenshots: flat floors no longer cast (they speckled the foot of each wall), and eyes, plates and limbs thinner than 12 cm no longer cast (their shadows broke into dashes) |

## 5. Regression

All ten headless suites pass: **410 checks, 0 failed** (373 before this
pass; the new ones cover the toon materials, outlines, key light, blob
shadows and the card wording). The checklist of section 1 of the style
document maps to the suites as in the Pass 0 report.

Bindings, damage, timings, colliders and interaction positions are
unchanged. Two things outside the picture changed: the wisdom card wording
(your decision 2), and the test runner now fails a test scene that does not
finish within ten minutes instead of hanging.

## 6. Frame statistics

Both columns use the same seed, so the same creatures and pickups are in
view (`BOOKMARK_SEED` in `tests/capture.gd`). "Before" is the previous
commit rendered with that seed; the Pass 0 report used random seeds.

| Bookmark | Draw calls before | after | Primitives before | after |
|---|---|---|---|---|
| Spawn view | 273 | 434 | 74,464 | 99,782 |
| Slime close-up | 210 | 313 | 82,460 | 84,210 |
| Veldora chamber wide | 74 | 67 | 57,666 | 52,558 |
| Veldora dialogue | 67 | 61 | 57,796 | 52,100 |
| Lake | 113 | 182 | 15,530 | 22,470 |
| Combat hit | 271 | 453 | 58,246 | 99,494 |
| Status sheet | 295 | 457 | 60,528 | 97,896 |
| Last thoughts | 298 | 460 | 62,288 | 99,666 |

Draw calls are up by about 60% where the hall is in view, and over the
medium budget of 200. The cost is inherent to the look: each rock piece is
drawn once more for the key light, each lined part once more for its line,
and each shadow caster once more per shadow split. My first version drew 856
in the spawn view; the unshaded character shader, keeping lines out of the
shadow map, baking static models and trimming casters brought that to 434.
Veldora's chamber is already cheaper than before.

What remains is separate pieces: 53 rock boxes and creatures built from
10 to 30 parts each. Pass 3 merges and instances the cave, Pass 5 rebuilds
the monsters as single meshes, and Pass 9 drops lines and shadows with
distance. Triangles stay far under budget.

**Frame time is not reported**, as in Pass 0: there is no GPU here and the
software rasteriser's 90 to 150 ms per frame says nothing about your machine.

## 7. Assumptions I made

- Characters, creatures and pickups cast shadows but do not receive them
  (rule S8, and the document allows hero meshes to stop receiving).
- Walls, the ceiling and flat floors do not cast; a key light underground is
  a stylistic choice and solid rock would shade everything. Raised ledges cast.
- The slime is opaque and banded for now (the document's low-tier slime). Its
  core is built but hidden inside until Pass 2 makes the body translucent.
- Mimicry forms are opaque too, still tinted toward the slime's colour.
- Glow energies are 1.0 to 1.6, not the document's 2 to 6. With linear tone
  mapping a brighter glow clips to white and loses its hue.
- The rim is lit from one side as a back light and only on rounded forms. A
  full-circle rim read as a second outline, and on a flat face it switched
  the whole face on as the camera tilted.
- Pickups take their colours from the palette (herb and ore groups) rather
  than from `items.json`; the small lamp on each pickup follows.
- `lights.fill_*` (ambient) no longer reaches anything: toon surfaces ignore
  ambient light, and the shade tint does that job.
- The lamp on the slime and the lamps at crystals and pickups remain and now
  show as soft pools of colour on the rock. The pool of two to four shared
  lamps the document describes is part of Pass 3.

## 8. Known and left for later passes

- Veldora, the black spider and the tempest serpent sit at or below the 20%
  value floor of rule S7, because their colours are near-black in the palette
  and in `creatures.json`. Passes 4 and 5.
- Every model is still built from simple shapes. They now have the toon
  material, a line and a blob shadow; real stand-ins are passes 2, 4 and 5.
- The lake is a flat two-tone surface, and the cave is still boxes. Pass 3.
- Cast shadow edges show small steps at a distance (two splits over 36 m at
  2048). `lights.shadow_splits`, `shadow_distance` and `shadow_map_size`
  trade that against cost.
- A loaded model with a skeleton or blend shapes keeps its own normals for
  the line, so hard edges on such a model would split. Not exercised yet:
  the only model file in the project is the static test rock.
- The shaders have only been run on the Compatibility renderer.

## 9. Tunables

`data/visual_config.json` went from 132 to 185 settings, all in the F4 panel.

Added:
- `lights`: `key_pitch`, `key_yaw`, `shadow_enabled`, `shadow_distance`,
  `shadow_splits`, `shadow_filter`, `shadow_map_size`, `shadow_bias`,
  `shadow_normal_bias`, `shadow_min_part_size`, `shadow_edge_low`,
  `shadow_edge_high`
- `toon`: `character_band2`, `character_band2_threshold`,
  `character_light_x/y/z`, `rim_light_x/y/z`, `environment_band2`,
  `environment_band2_threshold`, `environment_cap_threshold`,
  `environment_lamp_tint`, `environment_lamp_threshold`
- `outline`: `enabled`, `scale`, `reference_height`, `hue_shift`,
  `saturation_boost`, `min_value`
- `blob_shadow`: `enabled`, `tint`, `opacity`, `softness`, `radius_factor`,
  `grow_with_height`, `fade_height`
- `slime`: `face_enabled`, `highlight`
- `seal`: `face_alpha`, `edge_alpha`, `edge_start`, `energy`
- `water`: `near_alpha`, `far_alpha`, `edge_start`
- `props`: `pickup_glow`, `crystal_glow`, `mote_glow`, `eye_glow`,
  `accent_glow`, `projectile_glow`, `telegraph_alpha`, `telegraph_edge_alpha`

Removed: `outline.slime_px` and `outline.large_px`. Each asset's line width
is `outline_px` in its manifest entry, as in the document's schema;
`outline.scale` multiplies them all.

Changed: `toon.environment_rim_strength` 0.1 to 0.0 (a rim on a flat floor
drew a ring around the camera).

Now read for the first time: the `toon` and `outline` sections and the cave,
slime, veldora, seal, herb and ore palettes.

## 10. Next

Pass 2 is the slime (section 5): droplet shape, jelly layers, visible core,
face, spring squash and stretch, and its eleven states. I am stopping here
and waiting, as the working rules ask.
