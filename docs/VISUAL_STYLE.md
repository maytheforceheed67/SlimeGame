# Ink the slime: your anime-look overhaul prompt

This is one copy-paste-ready prompt that tells the AI assistant already building your game how to turn the current placeholder build into a cel-shaded, outlined, punchy anime action game in the general style of titles such as One Piece Bounty Rush, covering every model, the cave, shading, effects, animation, camera, interface and free online assets. To use it, copy everything inside the block below into your assistant, change the single `ENGINE` line if you are not on Three.js, and let it start with Pass 0 only. It is written for a personal, non-commercial fan project: it asks for original designs in an anime style and for free assets used within their licences, never for copied characters, art, fonts or sounds.

````markdown
# Visual overhaul prompt: make my slime roguelike look like a cel-shaded anime action game

ENGINE: [Three.js/WebGL - change if different]

## 1. Your role, scope and working rules

You are the technical artist and graphics programmer on my existing, playable game: a 3D slime roguelike fan game set in the world of "That Time I Got Reincarnated as a Slime". Your job is a complete visual overhaul of what is currently a prototype: a flat dark cave room, a plain blue sphere for the slime, a dragon made of boxes, tiny plain UI text.

Scope
- IN: renderer setup, materials, outlines, lighting, post-processing, every model, the cave environment, effects, game feel, animation, camera, UI styling, audio feedback, performance tiers.
- OUT: new skills, enemies, stats, progression, balance or story text. No new gameplay. The only logic changes allowed are the two bug fixes in 14.4.

Regression checklist (run after every pass; all of it must behave exactly as now):
- Move (WASD), hop (Space), tackle (LMB), skill (RMB), next skill (Q), devour / Predator (F), speak (E), scan (R), form change / Mimicry (Z), potion (H), status sheet (Tab).
- Voice of the World announcements; Veldora dialogue with numbered choices.
- Death -> "Last thoughts" wish cards -> "Be born" -> rebirth.
- Key bindings, damage, timings, collider sizes and interaction positions change only with my approval.

Working rules
1. Inspect first. Tell me the engine and version, whether the project uses a bundler or a single HTML file with CDN imports, how the UI is drawn, where models are created and how time is stepped. Adapt to what exists; do not swap frameworks or add a build step without asking.
2. Separate presentation from logic. Visuals read game state; logic never reads visual state (a shaken camera, a squashed mesh). Colliders and hitboxes stay fixed while meshes deform.
3. Work in the passes of section 17, one at a time. After each: run the regression checklist, capture the screenshot bookmarks (spawn view, slime close-up, Veldora chamber wide, Veldora dialogue, lake, a combat hit, Last thoughts, status sheet), report draw calls, triangles and frame time, list new tunables, then stop and wait.
4. Verify versions yourself. Version numbers here were checked in November 2026 and may be stale. Run `npm view <package> version` (or check the CDN) for every library, check each add-on's supported range of the core library, then pin exact versions. API names, shader chunk names and constants below come from general practice; confirm each against the version you pin.
5. One tunable config. Every colour, width, threshold, duration and tier switch lives in `src/visual/visualConfig.js`, editable live from a debug panel on an unused key (for example F3). No magic numbers elsewhere.
6. Data-driven assets. Every model, texture, font and sound is a manifest entry (section 4), never a hard-coded path.
7. Every number in this prompt is a starting value to tune by eye unless the line is marked RULE.
8. Never leave a bare box, sphere or cone visible; missing assets get a good-looking procedural stand-in (4.6).
9. Accessibility switches from day one: screen shake 0-100%, reduce flashes, hit-stop scale 0-100%, short skill animations.
10. Originality and licences (RULE). Make original designs. Never use, trace, rip or imitate specific characters, logos, models, textures, fonts, UI art or sounds from One Piece Bounty Rush, the Tensura anime or games, or any other commercial title; the reference is the general cel-shaded anime-game look only. Use free assets strictly within their licences and record each in `CREDITS.md`. This is a personal, non-commercial fan project.
11. Where something is underspecified, pick the simplest option that obeys the style bible, state the assumption in one line, and continue.

## 2. Style bible

### 2.1 What "anime game look" means here

The target is the general look of cel-shaded anime action games: flat-colour characters with ink lines, softer painted-feeling backdrops, oversized saturated effects and numbers, and a loud colour-coded lettering layer. Treat One Piece Bounty Rush as a mood reference, not a blueprint: do not try to match any specific shader, screen or asset from it.

### 2.2 Rules (all RULE)

| # | Rule |
|---|---|
| S1 | Hard two-tone shading. A surface is lit or shaded with a crisp edge (an optional narrow third band is allowed). Never a smooth gradient falloff on characters. |
| S2 | Shadows are a colour, not darkness. Shade colour = base colour shifted toward blue-violet, saturation equal or higher, value down 25-45%. Never multiply toward grey or black. |
| S3 | Ink lines. Every character, creature, pickup and hero prop has a silhouette outline whose colour is a darker, more saturated shade of the surface under it (not pure black), with near-constant width on screen. |
| S4 | Flat clean colour. Characters use flat colours, vertex colours or a tiny palette atlas. No normal maps, roughness or metalness maps, photo textures, procedural grain or environment reflections on characters. |
| S5 | Designed highlights. Specular is a hard-edged shape placed on purpose; rim light is a separate third term used to lift characters off the background. |
| S6 | Bright, clean, saturated. Noise, murk and grain are defects. |
| S7 | Dark in hue, not dark in value. The cave reads as deep blue, violet and teal at mid values. Fog fades to a coloured, lighter value, never to black. Nothing the player must read sits below about 20% value. |
| S8 | Characters carry their own light. Each character is shaded by a fixed, flattering light direction that ignores scene lights, so it stays near full brightness everywhere. |
| S9 | The world is softer than the characters. Environment shading uses softer band edges, lower contrast, large simple shapes and two or three flat tones; characters stay crisp and lined. |
| S10 | Silhouette first. Every asset must be identifiable as a solid black shape at gameplay distance; exaggerate the features that identify it (horns, wings, legs, tail). |
| S11 | Effects are drawn shapes: hard-edged, two or three flat colours plus a hot white core, fast in, short hold, fast erode. |
| S12 | Motion is posed: anticipation, held key poses, overshoot, squash and stretch; effects and attack poses run on stepped time. |
| S13 | The UI is loud and colour-coded: heavy outlined slanted lettering, skewed panels, one saturated accent per context. |
| S14 | Readability beats spectacle. Dramatic cameras and full-screen effects are reserved for skills and finishers; the central 40% of the screen stays clear in normal play. |

### 2.3 Do-not list

- Physically based gloss on characters (standard or physical materials with an environment map); physically based transmission on the slime during gameplay.
- Grey or black shadows; smooth Lambert gradients.
- Default ACES filmic tone mapping; heavy low-threshold bloom that washes out flat colour and lines.
- Thin, missing, pure-black or non-distance-compensated outlines; lines on every interior crease.
- Noisy realistic textures or normal maps on characters.
- Dense muddy fog, ambient-occlusion grain, film grain, chromatic aberration, motion blur.
- Many coloured dynamic lights that change a character's palette; a cave lit only by dim point lights.
- Floaty linear tweens with no holds; soft additive blobs or realistic smoke as hit effects.
- Thin, grey, translucent "app-style" UI; small plain text.

### 2.4 Palette (my design suggestions; all tunable, all in `visualConfig`)

| Group | Role | Hex |
|---|---|---|
| Sealed Cave | Fog and background | #2A2466 |
| | Rock lit / rock shade / top "light cap" | #5A5FA8 / #2E2A66 / #7F8BD6 |
| | Deep crevice (darkest allowed) | #1A1640 |
| | Moss and teal accent | #2FA39B |
| | Lake shallow / deep / foam | #4FE3E0 / #16357A / #E6FFFF |
| Magic ore and crystals | Core / mid / dark facet | #E8FFFF / #5FE8FF / #1F7FD1 |
| | Violet variant light / dark; rare gold ore | #B28CFF / #6B3FD9; #FFD86B |
| | Magicule motes | #9FF3FF, #C9B6FF |
| Hipokute herb | Leaf / shade / glowing tip | #3FD38A / #1E8F6E / #C8FFD9 |
| Slime (default) | Body / shade / rim / core / outline / highlight | #4FB8FF / #2B5FD9 / #BFEFFF / #8FE0FF / #16307A / #FFFFFF |
| Veldora | Scales / shade / belly plates | #2B2F4A / #171932 / #6C6FA3 |
| | Horns and claws / horn shade | #F2C14E / #B9792B |
| | Eyes / storm accent / wing membrane / outline | #FFD84A / #8FE8FF / #4A3F7A / #0D0F24 |
| Seal | Glyph lines / barrier tint / pulse | #FFE28A / #6F5BFF / #FFFFFF |
| UI | Panel (88% opacity) / panel edge / text / text stroke | #101426 / #7FE3FF / #FFFFFF / #0B0D1A |
| | Player accent / ready and crit / danger | #3FD0FF / #FFC531 / #FF3B5C |
| | Health / health ghost / magicules / stamina | #FF4D5E / #FFD0D6 / #3FB6FF / #FFC531 |
| | Voice of the World text / window | #CFF6FF / #0E1B2E |
| Element ramps (core / mid / rim) | Devour | #FFFFFF / #45C8FF / #2B2FA8 |
| | Water | #FFFFFF / #46E0E0 / #173A8A |
| | Lightning | #FFFFFF / #7FEAFF / #2440C8 |
| | Fire | #FFF6C2 / #FF8A2A / #C2203A |
| | Poison | #D8FFB0 / #8A4FD6 / #1B1030 |

The slime's colour is a player choice: derive its shade, rim, core and outline from one `slimeColor` by rule (shade = hue about 20 degrees toward indigo, value -35%; outline = base x 0.4, more saturated), so any colour, including a later silver-and-gold form, works without new art.

## 3. Rendering pipeline

### 3.1 Renderer and colour management

- Stay on `WebGLRenderer` with GLSL materials and the pmndrs `postprocessing` library. Do not mix in the WebGPU/TSL stack: it cannot run `ShaderMaterial`, `onBeforeCompile` or `EffectComposer`, and its API is still changing.
- Newest versions I could verify: core r186 (September 2026), `postprocessing` 6.39.4. Verify and pin (rule 4).
- With the composer active: `powerPreference: 'high-performance'`; renderer `antialias`, `stencil` and `depth` off; sRGB output; renderer tone mapping off (it happens in the composer); half-float composer buffers on desktop tiers.
- Pixel ratio cap: 2 on desktop, 1.5 on phones.
- Colour textures are tagged sRGB; data textures (ramps, masks, noise) stay untagged. Keep lit base colours at or below about 0.85 linear so only emissive surfaces bloom.
- Pre-compile shaders while loading; vary materials by uniform, not by define.

### 3.2 Shared toon material

One factory, `makeToon(options)`, used by every non-VRM mesh. Stopgap inside Pass 1 only: `MeshToonMaterial` with a 2-3 texel gradient map (nearest filtering, no mipmaps) and a cool hemisphere light. Target: a custom toon shader, as a patch on a built-in material (keeps skinning, morphs, fog, shadows, instancing) or a full `ShaderMaterial`.

| Parameter | Meaning | Characters | Environment |
|---|---|---|---|
| `baseColor` / `map` | Flat colour, vertex colour or palette atlas | per asset | per asset |
| `shadeTint` | Multiplied onto base in the shade band | (0.55, 0.50, 0.75) | (0.65, 0.62, 0.82) |
| `bandThreshold` | Lit/shade split on the half-Lambert term | 0.45 | 0.45 |
| `band2Threshold` | Optional mid band | 0.75, off by default | off |
| `bandSoftness` | Edge width | about one pixel | 0.05-0.15 |
| `lightDir` | Shading light | per character, camera-relative, high and to one side | scene key light |
| `rimStart / rimSoft / rimStrength` | Thresholded fresnel rim | 0.65 / 0.02 / 0.5 | 0-0.2 strength |
| `rimColor` | Area accent | cool cyan in the cave | same |
| `specGloss / specMask` | Hard-edged highlight, masked per material | 64 / off by default | off |
| `emissive` | Glow, in HDR | 2-6 on eyes and cores | 2-4 on crystals |
| `biasMask` | Vertex-colour channel forcing an area lit or shaded | under chins and wings | crevices |
| `flash` | 0-1 mix to a flash colour (hit feedback) | yes | no |

Fold the cast-shadow term into the band coordinate before thresholding, so cast shadows take the same shade colour as form shadows. Cache material instances by (colour, map).

### 3.3 Outlines

| Target | Technique and starting values |
|---|---|
| Characters, creatures, pickups, hero props | Inverted hull: a second draw of the mesh, back faces only, vertices pushed along smoothed normals in clip space and scaled by clip `w` so width is constant in pixels; shares the skeleton; drawn after the base mesh. 2.0 px at 1080p (1.5-2.5), times pixel ratio; slime 2.5; large dragon masses 3.0, small details 1.5 |
| Line colour | Per material: base x 0.4, hue nudged toward blue, saturation up. Never #000000 |
| Far objects | Stop the line growing beyond about 25 m; fade it out when the object is under about 12 px tall |
| Hard-edged meshes | At load, bake one averaged normal per unique vertex position into an extra attribute and extrude along it; otherwise the hull splits at every hard edge |
| Local control | A vertex-colour channel multiplies width; 0 erases the line (mouths, teeth, creases) |
| Terrain, walls, big rocks | No hull. High tier only: an optional depth-plus-normal edge pass that multiplies scene colour by about 0.35 at edges, fades with distance, and runs before bloom and anti-aliasing |
| Interaction highlight (scan target, devourable, lock-on) | A selection-outline effect with a soft accent-coloured glow: feedback, not the ink line |
| VRM characters | Keep their material's built-in outline; never outline twice |

The stock `OutlineEffect` add-on is allowed for a first look in Pass 1 only (WebGL only, default thickness 0.003, replaces the render call, cannot use smoothed normals). Replace it with the custom hull before the pass ends.

### 3.4 Lights and shadows

- One shadow-casting directional key light, even underground (a stylistic choice), plus a cool blue-violet hemisphere fill at 0.4-0.6.
- Crystals and ore are emissive surfaces plus bloom plus a baked vertex-colour tint on nearby rock, with a pool of 2-4 non-shadowing point lights reassigned to the nearest clusters. No point-light shadows.
- Shadow map: hardware-filtered PCF, re-thresholded (`smoothstep(0.45, 0.55, shadow)`) for a crisp toon edge. 1024 on medium, 2048 on high. Orthographic frustum of 15-25 m half-extent that follows the player and snaps to texel steps. `normalBias` 0.02-0.05, `bias` -0.0002 to -0.001. Shadow constants have changed between releases; verify.
- Blob shadows: a soft disc under every actor, tinted dark blue-violet, growing and fading with height; one instanced draw. They replace the shadow map on the low tier and sell the slime's hop height on all tiers.
- Hero meshes that speckle may stop receiving shadows; they still cast.

### 3.5 Post-processing stack and order

One merged effect pass:
1. Optional environment edge lines (high tier).
2. Bloom: mipmap blur, luminance threshold 1.0, smoothing 0.1, intensity 0.8, radius 0.7. Only HDR emissive exceeds 1.0, so this is selective bloom with no extra pass.
3. Tone mapping: Khronos Neutral (alternative: AgX plus 10-20% saturation). Not ACES, which shifts hues, raises contrast and darkens, breaking hand-picked flat colours.
4. Colour grade: a LUT, or hue/saturation plus brightness/contrast, authored against tone-mapped screenshots.
5. Vignette: offset 0.35, darkness 0.45.
6. Anti-aliasing: SMAA medium (FXAA on low; 4x composer multisampling on high).

Fog: exponential, density 0.015-0.04, in the fog colour of 2.4 with the scene background set to match; custom shaders must include fog; add a height term so it pools near the floor.

### 3.6 If the ENGINE line is not Three.js (untested one-line equivalents)

| | Unity URP | Godot 4 |
|---|---|---|
| Toon material | Custom-lighting Shader Graph or HLSL (main light, N.L, smoothstep or ramp, shadow folded in), or the Unity Toon Shader package | `StandardMaterial3D` with toon diffuse and specular, or a spatial shader with a custom `light()` |
| Outline | Render Objects renderer feature with front-face culling; smoothed normals in a spare channel | `next_pass` shader with `cull_front, unshaded` extruding in `vertex()` |
| Post | Volume: Bloom threshold about 1, Tonemapping Neutral, Color Adjustments or LUT, Vignette | WorldEnvironment: glow threshold about 1, linear or AgX tonemap (version-dependent), adjustments LUT, fog |

## 4. Asset pipeline

### 4.1 Folder layout

```
assets_raw/<pack>/                 untouched downloads
public/assets/models/<category>/   optimised .glb files
public/assets/textures/{ramps,vfx,ui}/
public/assets/fonts/<family>/      .woff2 + OFL.txt
public/assets/audio/{sfx,ui,ambience}/
src/visual/    visualConfig, toonMaterial, outline, post, quality
src/assets/    manifest.json, AssetManager, toonify, procedural/
src/vfx/  src/ui/  src/camera/
tools/         convert.mjs, inspect.mjs
ASSETS_TODO.md   CREDITS.md
```

### 4.2 Manifest schema (one entry per logical asset)

```json
"rock_cave_a": {
  "file": "assets/models/env/rock_cave_a.glb",
  "source": "Quaternius Stylized Nature MegaKit (free tier)",
  "url": "https://quaternius.com/packs/stylizednaturemegakit.html",
  "license": "CC0-1.0", "attribution": null,
  "category": "env", "targetHeight": 1.2,
  "toonify": true, "outlinePx": 0, "castShadow": true,
  "paletteRemap": "cave_rock", "clips": {},
  "placeholder": { "builder": "rockLump", "seed": 3 }
}
```

Real file and clip names are unknown until the files exist: `tools/inspect.mjs` prints node and animation names, and the manifest is filled from that output, never guessed.

### 4.3 Loader, conversion and consistency

- One configured glTF loader with Meshopt decoding (add Draco or KTX2 only if a file needs it). `AssetManager.load(id)` returns a clone (skeleton-aware for skinned models); on a missing or broken file it logs one warning and returns the stand-in.
- GLB is the runtime format. Convert FBX or OBJ once with Blender (headless) or FBX2glTF, then optimise with the glTF-Transform command line (Meshopt, WebP, textures at 1024 or below; confirm flags with `--help`). Packs that ship `.gltf` plus `.bin` must keep the pair together or be repacked.
- Vendor every file into the project; never hot-link a third-party server at runtime.
- `toonify(root)` runs on every non-VRM model so mismatched packs look like one game: keep the source colour and base-colour map; drop metalness, roughness and normal maps; assign the shared toon material; keep alpha test (about 0.5) and double-sided rendering for foliage; use vertex colours only when present; smooth normals on faceted models except deliberately hard-edged props; optionally remap colours to the project palette.
- `fitHeight(object, targetHeight)`: scale to the manifest height and drop the base to y = 0. Units are metres; the slime is about 0.6 m tall.

### 4.4 Free packs to use (check the licence line on each page when downloading)

| Use | Pack and where | Licence | Formats and notes |
|---|---|---|---|
| Grass, bushes, plants, rocks, trees | Quaternius Stylized Nature MegaKit - quaternius.com/packs/stylizednaturemegakit.html | CC0 | FBX, OBJ, glTF. 116 models (40 trees, 35 plants, 27 rocks, grass, bushes), most in the free tier. Its wind shaders are engine-only: re-create sway in a vertex shader |
| Grass, rocks, trees | KayKit Forest Nature Pack - kaylousberg.itch.io/kaykit-forest | CC0 | FBX, glTF, OBJ. 100+ free models, including grass meant for custom shaders |
| Cave and dungeon pieces | KayKit Dungeon Remastered - kaylousberg.itch.io/kaykit-dungeon-remastered | CC0 | FBX, glTF (+ .bin), OBJ. 200+ free pieces |
| Filler nature props | Kenney Nature Kit - kenney.nl/assets/nature-kit | CC0 | 330 assets |
| Generic monsters (bat candidate) | Quaternius LowPoly Animated Monsters - quaternius.itch.io/lowpoly-animated-monsters | CC0 | OBJ, FBX, Blend only: convert. Creature list not confirmed |
| Lizard-type beasts | Quaternius Animated LowPoly Dinosaurs - quaternius.itch.io | CC0 (confirm on the page) | Contents not confirmed |
| Humanoid bodies, outfits, animations | Quaternius Universal Base Characters, Modular Character Outfits - Fantasy, Universal Animation Library - quaternius.com/packs/universalanimationlibrary.html | CC0 | glTF; 120+ clips on one shared rig |
| Chibi humanoids, undead | KayKit Adventurers, KayKit Skeletons - kaylousberg.itch.io | CC0 | FBX, glTF; rigged and animated |
| Anime-style humans | VRoid sample avatars - opengameart.org/content/vroid-studio-cc0-models | CC0 | 11 models, VRM 0.x |
| One-off models | Poly Pizza (poly.pizza); Sketchfab (free account) | Per model: mostly CC-BY, some CC0 | GLB or glTF; credit required for CC-BY |
| Effect textures | Kenney Particle Pack - kenney.nl/assets/particle-pack | CC0 | 80 images at 512 px |
| UI sounds | Kenney Interface Sounds - kenney.nl/assets/interface-sounds | CC0 | 100 files |
| Fonts | Google Fonts families named in 14.1 | SIL Open Font License | Self-host .woff2 with each OFL.txt |

No free pack was confirmed for a crystal cave, stalactites, a rigged dragon, a spider, a centipede or a snake. Build those in code (sections 6, 7, 9).

### 4.5 If you cannot download binary files yourself

Do not pretend, and do not block:
1. Write `ASSETS_TODO.md`: a numbered checklist giving, for each pack, its name, page address, "free tier", which archive to download, and the folder to unzip into (`assets_raw/<pack>/`).
2. Give me the one command to run afterwards (`node tools/convert.mjs`) and ask me to paste the resulting file tree so you can fill in real file and clip names.
3. Until then the game runs on stand-ins, one warning per missing asset.
4. Author everything non-binary yourself: ramps, palette and noise textures generated in code, procedural geometry, shaders, SVG icons.

### 4.6 Stand-in quality (RULE)

A stand-in is a real model built in code: lathe profiles (horns, droplets, stalagmites), tubes along curves (necks, tails, snakes), extruded shapes (wing membranes, fins, leaves), merged and smoothed primitives, all with the toon material, an outline and a blob shadow.

### 4.7 Licence rules (RULE)

- Prefer CC0; CC-BY with credit. Ask before using anything non-commercial, no-derivatives, share-alike or GPL.
- Nothing extracted from commercial games or shows, whatever an upload page claims.
- `CREDITS.md` is generated from the manifest; save a copy of the licence page for every non-CC0 asset; ship each font's OFL.txt.
- Mixamo animation is free with an Adobe ID and allowed in games, but its raw files must not be redistributed: bake clips into our own GLB files.
- AI-generated models: free-tier Meshy or Tripo output is CC BY 4.0 and needs a credit. Prompts describe original designs and never name an existing character. Discard the baked texture; apply the toon material.
- VRoid Hub models only when that model's own conditions allow redistribution; self-made VRoid exports and the CC0 samples are the safe route.

## 5. The slime (player)

Fully procedural: no downloaded model, no skeleton.

Shape: a slightly flattened droplet about 0.6 m tall, wider at the base with a small flat contact patch, 2-4k triangles, smooth normals. It must never read as a plain sphere.

Toon-jelly material (layers, cheapest first)
1. Body shell: two hard fresnel bands from a deeper, more saturated centre colour to a lighter edge colour, so it reads thick in the middle and thin at the rim; ordinary two-band lighting on top at low contrast (shade tint about 0.8).
2. Back-light band: a thresholded wrap term adds a soft-coloured glow band when the key light is behind the body.
3. Highlights: one large hard-edged gel highlight and one small dot, fixed relative to the character light so they look painted and never swim.
4. Inner core: a smaller, lighter, emissive nucleus visible inside, lagging behind movement on a spring. Either a separate mesh drawn first with the body at 0.75-0.85 opacity and a fixed draw order (core, body, outline), or faked inside the body shader to avoid sorting problems. Choose the one that stays artefact-free next to water and particles.
5. Banded translucency: if the body is translucent, quantise alpha into two steps (about 0.55 centre, 0.95 edge).
6. High tier only: fake refraction by sampling a half-resolution copy of the opaque scene, offset by the view-space normal x 0.02-0.05, mixed in at 20-40%.
7. Opaque back-face hull outline, 2.5 px.
- Face: two simple unlit eye decals that squash with the body, blink every 3-6 s and widen on hit. Put this behind a config switch; I may prefer a faceless slime.
- A just-devoured item stays visible as a dark silhouette inside the core for about a second.

Animation: spring-driven squash and stretch in the vertex shader, volume-preserving (`sy = 1 + s`, `sx = sz = 1 / sqrt(sy)`), base kept planted, normals corrected, and a matching depth material so the shadow follows. Springs at 4-5 Hz with a damping ratio of 0.35-0.45 so the body visibly overshoots two or three times.

| State | Motion | Extras |
|---|---|---|
| Idle | Breathing at 0.5-0.8 Hz, +/-3%; a "plop" settle every 6-10 s; tilts toward the nearest interactable | Blink |
| Move (WASD) | Hop-slide loop at 2-2.5 hops per second: squash -0.2 for 80 ms, stretch +0.2 in the air; lean 10-15 degrees into acceleration; the top lags behind | Small dust on direction reversal |
| Hop (Space) | Anticipation squash, stretch to 1.2-1.35 on the way up, squash to 0.65-0.75 on landing, settle in 0.3-0.5 s | Landing dust ring; blob shadow shrinks with height |
| Tackle (LMB) | Held flatten (4-8 frames), then stretch along velocity to 1.6-1.8x for about 100 ms (this is the smear), snap squash on contact | Trail, hit spark, speed lines, dust |
| Skill (RMB) | Quick crouch and pop; core flashes in the skill's element colour | Effect from 11.8 |
| Devour (F) | Flatten and widen (s = -0.4) for 120 ms, lunge with a veil mesh that envelops the target, target pulled to the core over 150-200 ms while dissolving, then a big "gulp" jiggle (+0.3) | Vortex from 11.7 |
| Scan (R) | Small upward perk; a thin ring pulses outward | Readout from 14.3 |
| Potion (H) | Bounce; core tints green briefly | Rising green ring and sparkles |
| Hurt | Jiggle impulse along the hit direction, brief flatten, eyes widen | White flash, red vignette |
| Death | Large squash, tension lost into a puddle over 0.6 s, core dims and fades, colour desaturates | Leads into the Last thoughts sequence |
| Form change (Z) | Collapse to a ball, hard-edged dissolve sweep with a cyan-white core flash, mesh swap on a 1-2 frame white-out, new form pops in at 1.15 -> 1.0 | Ring pulse; total about 0.5 s and never longer than the current input lock |

Acceptance: recognisable as a slime in pure silhouette in every state; highlights do not swim; no sorting artefacts; collider unchanged; all eleven states visibly distinct.

## 6. Veldora and the seal

Veldora is the Storm Dragon sealed in this cave. Design him as an ORIGINAL large storm dragon; do not reproduce the anime's or any game's model. No free rigged dragon pack was found, so build him procedurally by default, and let the manifest swap in a generic dragon GLB later if I supply one (a CC0 or CC-BY model, or an AI-generated model from an original concept, with the toon material applied).

Keep his position, the dialogue trigger and the seal's footprint exactly where they are now. Scale: his head sits 10-14 m above the floor; the slime is 0.6 m.

| Part | Build | Look |
|---|---|---|
| Spine, neck, tail | A curve with a radius profile swept into a tube (12-16 radial segments), driven by control points or a bone chain | Long S-curved neck, broad chest, tail curled around a rock; a row of fin-like dorsal blades |
| Head | Wedge-shaped skull from merged, smoothed shapes; brow ridges; separate hinged jaw; cone teeth with outline width 0 | Angular, swept-back, reads as "dragon" in silhouette from the chamber entrance |
| Horns | Lathe profiles: two large swept-back horns plus two to four smaller ones, with a jagged, lightning-like silhouette | Amber-gold with a banded shade |
| Eyes | Emissive slit eyes in HDR with an unlit glow; lids that blink | Visible from the far side of the chamber |
| Wings | Three-bone arm with an extruded membrane between finger spars, folded like a mantle at rest | Membrane slightly lighter and more violet, scalloped edge |
| Limbs | Forelegs resting with three or four lathe claws; hind legs folded | Claws match the horns |
| Scales | No noise texture. Large two-tone scallop or chevron rows as vertex colour or a tiny tiling two-tone mask; belly plates as real geometry bands | Clean, graphic |
| Storm accents | Faint emissive seams between plates; an occasional lightning crawl along the horns and spine | Storm accent colour |

Shading: shared toon material, cool shade tint, strong cyan rim (strength about 0.7) from the crystals so the dark body separates from the dark cave; deep navy outline, 3 px on large masses.

Animation
- Idle: slow breathing through the chest (about +/-4% on a 4-second cycle), neck sway from layered sines, sprung tail tip, an occasional wing shrug, blink every 4-8 s, glowing breath puffs.
- Head tracking: head and neck aim at the slime through a damped spring with angle limits; the eyes lead the head.
- Talk: his lines are thought-speech ("in thought"), so no lip flapping. Instead: eye glow pulses with the text reveal, a seam glow in the throat and chest, concentric thought-ripple rings from the forehead, and one stepped key pose per line (nod, tilt, lean in, rear back to laugh). While choices are on screen he holds an attentive pose.

The seal (replaces the plain translucent dome)
- A fresnel-banded barrier shell with two hard bands, nearly clear when viewed face-on so it never hides him.
- A slow band of original geometric glyphs scrolling around it (hard-edged, made from thresholded noise and simple shapes; do not copy runes from the show).
- A floor sigil ring as a glowing decal; motes rising along the wall; lightning from his aura crawling across the inside.
- A ripple ring where the slime touches or tackles it, and a pulse when dialogue starts.
- If the build has the "swallow Veldora with his seal" moment, play the devour vortex at chamber scale with the shell eroding in hard-edged pieces.

Acceptance: readable as a dragon in silhouette; no visible primitive seams or box shapes; head tracks the slime; eyes visible at 40 m; the seal is clearly a magical barrier and does not obscure his face; dialogue behaves exactly as before.

## 7. The five cave monsters

Original designs matching these descriptors. Apply the toon material, outline, blob shadow, hit flash and telegraphs to all of them. If the build does not yet contain a given monster, prepare its model and manifest entry but do not add its gameplay.

| Monster | Silhouette and palette | Build | Animation set | Telegraph |
|---|---|---|---|---|
| Tempest serpent (jet-black giant snake with thorned scales) | Thick S-curve body 8-12 m long, wedge head, rows of thorn spikes; near-black indigo #1C1B33, violet shade, toxic green accents #9BFF6A | Tube along a curve that follows the head's path history, plus a sine offset; instanced cone thorns | Slither, coiled idle, rear up, strike lunge, breath, recoil, death uncoil | Rears and holds; throat glows green before breath; cone decal |
| Giant centipede | Long segmented arc, many legs, antennae, wide mandibles; maroon #8A2F3B with amber legs #FFB347 | 14-20 instanced segments following the head path; leg pairs on phase-offset sines | Scuttle, rear, bite, breath, hurt ripple down the body, curl on death | Front third lifts, mandibles spread, yellow glint |
| Black spider | Low wide body, eight long arched legs, a cluster of glowing eyes; black-violet #221A3A, magenta eyes #FF4FA3, white thread | Two ellipsoid masses plus eight legs with two-bone IK stepping to targets | Creep, skitter, pounce, thread shot, flinch (legs splay), death curl (legs fold in) | Crouch and raise the abdomen; eye flash; line decal for thread |
| Giant bat | Wide wingspan, large ears, small body; dusty purple #5B4A8A, membrane #8E6BD1 | A flying creature from the monster pack if one fits; otherwise three-bone wings with extruded membranes | Hanging idle, stepped flap hover, swoop, screech, bite, hurt tumble, spiral fall | Wings pull back and hold; mouth glow; ring preview for the screech |
| Armoured lizard | Stocky quadruped, overlapping back plates, club tail; teal-grey #3E7C86, steel-blue plates #9CC7D9, cream belly | A dinosaur-pack quadruped through `toonify` if one fits; otherwise a procedural quadruped with plates as geometry | Walk, sniff idle, charge, tail swipe, curl guard, hurt, death roll | Paw scrape and lowered head before a charge; line decal |

Shared rules
- Attacks are three or four key poses played on stepped time; locomotion stays smooth.
- Telegraph in three layers, all inside each attack's existing windup: an exaggerated held pose, a glint at the eyes or mouth 150-250 ms before the hit (white or yellow for avoidable, red for heavy), and a ground decal (circle, cone or line) that fills during the windup and pulses in the last 150 ms. If an attack has no windup, do not add one; tell me, and I will decide.
- Hurt: flash, vibration during hit stop, a reel pose. Death: pose, then a hard-edged dissolve into magicule motes.
- A staggered, devourable monster gets a pulsing accent outline and an "F Devour" prompt.

Acceptance: each monster identifiable by silhouette at 20 m; each attack readable before it lands; stats and behaviour unchanged.

## 8. Humanoids and followers (later regions; decide the route now)

Pick one route per character class and do not mix them carelessly:
- Route A, anime-proper humans: author in VRoid Studio, export `.vrm`, load with `@pixiv/three-vrm` (MIT, version 3.x; confirm the exact version). It brings its own toon material, built-in outline and spring-bone hair. Update order each frame: animation mixer, then the VRM update. Never run `toonify` on VRM models; instead match their outline width and palette to the rest of the game.
- Route B, low-poly stylised humans: the CC0 base characters, outfits and shared animation library from 4.4 (no retargeting needed), passed through `toonify`. Goblins, ogres and lizardmen are recoloured, rescaled variants with extra parts (a tail mesh on the hips bone).
- Recommendation: Route B for followers and crowds (it matches the creature packs), Route A for a few hero humans. Ask me before building either.

Animation sources: the CC0 animation library first; Mixamo under the conditions in 4.7 (bipeds only), retargeted to VRM with the three-vrm example helper or the MIT `vrm-mixamo-retarget` package and baked at build time. One animation mixer per character, 0.15-0.25 s cross-fades, one-shot clamped clips for attacks and deaths. For faces: spherical head normals and the per-character light are enough; skip authored face-shadow maps.

## 9. Sealed Cave environment

Turn the flat room into a real cavern. Keep spawn points, interaction positions and walkable routes; use simple invisible colliders under the new art.

| Element | Build | Rules |
|---|---|---|
| Layout | An entry gallery where the slime wakes, a narrowing tunnel, then a reveal into Veldora's chamber; two or three side tunnels; one underground lake | The tunnel hides the chamber until the last moment |
| Floor | Displaced, subdivided mesh with gentle height variation, coloured by height and slope in two or three flat tones | Walkable slope limits respected |
| Walls and ceiling | Displaced shell and large rock pieces from the nature packs, merged or instanced; soft-edged toon bands; a lighter "cap" colour on up-facing surfaces | No hull outline; baked crevice darkening in vertex colour, tinted, not grey |
| Stalactites, stalagmites | Procedural lathe cones with irregular profiles, instanced | Cluster in threes and fives; frame views, never block paths |
| Crystal clusters | Flat-shaded 5-8 sided prisms with points, instanced with per-instance colour and seed; two-tone facets, thresholded fresnel rim, pulsing HDR emissive (2-4) | Each cluster tints nearby rock and may borrow one pooled point light |
| Magic-ore veins | Emissive seams and nodules set into walls, with a slow travelling pulse | Lead the eye toward the chamber |
| Hipokute herb patches | Low rosettes with softly glowing tips, from recoloured pack plants or procedural leaves, with wind sway and player push | Grow near water and crystals |
| Grass and moss | Pack grass cards or blades through the instanced grass system of section 10, at low density; teal moss on rock tops | Base colour matches the ground it grows from |
| Underground lake | Stylised water: depth-based colour from shallow to deep (optionally in three bands), hard-edged noisy shoreline foam, thresholded surface lines, gentle waves, glowing shallows that bloom | Low tier: baked shoreline mask instead of scene depth |
| Magicule particles | A few hundred GPU-animated motes drifting upward, denser near Veldora | Hard-edged, HDR-tinted |
| Light shafts | Additive cone or quad meshes from ceiling openings with a vertical gradient, soft edges and slow dust noise | Mesh-based, because screen-space shafts vanish when the source is off screen |
| Fog | Coloured exponential fog plus a floor-hugging height term | Doubles as the draw-distance limit |

Scatter rules: seeded and deterministic; place in clusters of 3, 5 or 7 with one large, some medium, some small; random yaw, scale 0.7-1.4, aligned to slope; a density mask keeps routes, the dialogue spot and combat areas clear; nothing within 1.5 m of an interaction point; instance everything repeated.

Hero landmarks (each recognisable from a distance): Veldora's chamber, the lake, a crystal grove, an ore wall, a herb terrace, one large light shaft.

Framing the dragon's chamber: the largest crystal cluster or light shaft sits behind him so he is rim-lit and reads as a silhouette first; the floor sigil leads the eye; the chamber is the brightest and most saturated place in the cave; a camera trigger at the entrance widens the view (section 13) and shows the area banner.

If the build has the sightless opening before Mana Perception, keep it and restyle it (outline-and-pulse view, ripple reveal); do not add it if absent.

Acceptance: no flat wall or flat floor visible from any bookmark; the route to Veldora is readable without UI; nothing important is darker than the crevice colour; frame budget met (section 16).

## 10. Jura Forest look (forward-looking, do not build yet)

So the style scales to the open world:
- Grass: clumps or blades in one instanced mesh per terrain chunk; colour blends from a base that equals the terrain colour to a lighter tip, with noise-driven patches; wind sway in the vertex shader; grass bends away from the player; chunk culling, distance levels of detail, and a far cull hidden by fog.
- Trees and bushes: pack models through `toonify`, alpha-cut leaf cards, vertex-shader wind.
- Sky: a gradient dome with two or three colour stops, a sun disc, a few large painted-looking cloud shapes. No photographic sky.
- Water: the lake shader, with brighter shallows.
- Distance: near detail, mid-distance fog, far haze. Add slight texture richness to large terrain so flat colour does not look empty across open ground.
- Daylight palette: bright, saturated, high-key; characters keep their own light.

## 11. VFX and game feel

### 11.1 Time architecture

Keep `realDt`, a global time scale and a per-entity time scale. Stops and slow motion are timed modifiers; the effective scale is the minimum of the active ones, so overlaps are safe and nothing is restored by hand. Entities animate and move on their own scaled time; UI, particles, camera shake and audio run on real time, so sparks fly while bodies are frozen. Fire feedback only after a hit is actually accepted.

### 11.2 Hit stop (milliseconds of real time, scaled by the accessibility setting)

| Hit class | Hit stop | Victim shake | Camera trauma | Extra |
|---|---|---|---|---|
| Light or multi-hit tick | 30-50 | 0.03 m | +0.10 | 60 ms flash |
| Medium (tackle) | 60-90 | 0.05 m | +0.20 | 80 ms flash, small zoom punch |
| Heavy or charged | 100-150 | 0.08 m | +0.35 | 100 ms flash, field of view -3 degrees |
| Finisher or elite kill | 180-250, then 0.2x slow motion for 250-400 ms | 0.10 m | +0.60 | Impact frame, radial lines |
| Player takes damage | 60-100 | - | +0.30 | Red vignette 200 ms |
| Devour | 150-200 | Target squashes toward the slime | +0.25 | Radial pulse |

Freeze the attacker and each victim, not the world; a global freeze is for finishers only. Multi-target hits apply the single longest stop once, and total stop is capped at about 300 ms per second. During the stop the victim's mesh (never its collider) vibrates side to side, tapering off, scaled to look the same at any camera distance.

### 11.3 Screen shake

Trauma model: trauma runs 0 to 1; shake = trauma squared; trauma decays about 0.5 per second; each event adds the table amount; offsets come from smooth noise sampled at 20-25 Hz. Maximums: 1.5 degrees yaw and pitch, 2.5 degrees roll, 0.15 m position, plus a short sprung kick of 0.1-0.25 m along the hit direction. Apply shake to a child node of the camera rig after follow logic and remove it before the next update. Obey the shake slider.

### 11.4 Order of events on a hit (same frame)

Validate -> damage -> hit stop -> flash -> spark at the contact point -> shake -> knockback (when the stop ends) -> damage number -> sound. Knockback uses the game's existing values; if there are none, add a visual lean and reel only.

### 11.5 How every effect is built

- Simple meshes (strips, rings, open cylinders, cones, spheres, quads) with unlit shaders and depth write off; additive for energy, alpha-tested for dust.
- One erosion shader covers most effects: a shape mask times scrolling greyscale noise, cut by a hard alpha threshold that rises over the effect's life so the shape burns away; two further thresholds give the mid colour and the hot white core.
- Stepped time: quantise the effect clock to about 12 steps per second for noise and flipbook frames; position and scale still move every frame.
- Flipbooks: greyscale, tinted at runtime, usually 4x4 frames, with clear margins.
- Three flat colours per effect from the element ramps in 2.4; the white core is HDR so bloom catches only the core.
- One instanced quad mesh per atlas and blend mode, with fixed-size pools.
- Textures: the CC0 particle pack from 4.4 packed into one atlas, plus noise generated in code.

### 11.6 Effect library

| Effect | Build | Life |
|---|---|---|
| Tackle trail | Crescent or ribbon behind the slime, eroding along its length; vanishes on hit | 0.15-0.25 s |
| Hit spark | Burst flipbook + 4-8 stretched streaks along the hit normal + a white disc scaling 0.2 -> 1.2 in 50 ms | 0.12-0.2 s |
| Shock ring | Flat ring scaling 0.3 -> 3-6 m, thinning as it grows | 0.25-0.4 s |
| Speed lines | Full-screen radial lines on stepped time, clear centre, 30-60% opacity; parallel lines for dashes | 150-250 ms |
| Dust puff | 3-6 instanced cloud shapes moving outward with heavy drag | 0.4-0.7 s |
| Impact frame | Two-tone inverted frame, then two-tone with radial lines, then colour returns with an exposure spike | 2-3 frames; finishers only; "reduce flashes" swaps it for a mild desaturate |
| Hit flash | `flash` to 1 on hit, held through the stop, decaying in 60-100 ms; white, or the element colour | |
| Telegraph decals | Circle, cone or line filling from centre to edge | Windup length |
| Magicule aura | A slightly larger shell with upward-scrolling noise and a hard cut-off, plus rising motes | Looping |
| Pickup and potion | Rising ring, sparkles, short column of light | 0.4 s |

### 11.7 Devour vortex (the signature effect)

Anticipation: motes and dust are pulled inward toward the slime. Capture: three or four spiral ribbons, revealed along their length, wrap the target while it shrinks toward the slime's core and erodes in hard-edged pieces; a dark-centred, bright-rimmed disc opens beneath it. Swallow: a ring collapses inward, the slime gulps, then one outward pulse and a brief aura in the devour ramp, followed at once by the Voice of the World line. Scale everything with target size.

### 11.8 Skill effects

List every skill and form that exists in the build and give each an effect by type. Do not invent skills.

| Type | Look |
|---|---|
| Water blade or jet | Thin crescent in the water ramp with a white foam edge, droplet streaks, a splash crown on impact |
| Poison or paralysis breath | Cone of rolling hard-edged cloud shapes in the poison ramp (yellow-tinted for paralysis) with popping bubbles |
| Thread | Fast white line with a bright tip and an anchor burst; a pale-blue glinting variant for steel thread |
| Sound wave | Thin concentric rings expanding in a cone, slight screen ripple |
| Drain | Motes flowing from target to user along a curved ribbon |
| Body armour or guard | Hex-plate shell flashing on with a bright rim; plates pop off on break |
| Lightning | Jagged strip regenerated every two frames, white core, coloured halo |
| Fire | Two scrolling noise layers in a teardrop mask with inner and outer cut-offs |
| Heal | Green rising rings and plus-shaped sparkles |

## 12. Animation rules

- Pose to pose: build actions from a few strong key poses; hold them. Template at 60 fps: anticipation 4-8 frames held, strike 1-3 frames with a smear, impact hold equals hit stop, follow-through 4-6 frames, recovery 8-16 frames. Never lengthen an action's existing gameplay timing; fit the poses inside it.
- Stepped where it helps: attack and emote poses on stepped time (about 12 poses per second, or discrete key interpolation); locomotion, root motion and the camera stay smooth.
- Anticipation and overshoot on everything that moves, including UI.
- Squash and stretch, volume-preserving; smear by stretching along the motion direction for the strike frames.
- Secondary motion from spring-dampers on tails, ears, antennae, wing tips and the slime's core: damping ratio 0.5-0.8 for lively follow-through; sub-step if a spring becomes unstable.
- Procedural first: the slime, serpent, centipede and spider are animated in code (springs, path following, IK), with authored key poses layered on top for attacks.
- Idle personality for everyone: breathing, blinking, an occasional look-around.
- Blends between states take 0.15-0.25 s, except into attacks and hurts, which snap.
- No simulated cloth or ragdoll.

## 13. Camera

Rig: pivot (follows the player with damping) -> yaw -> pitch -> arm (distance) -> shake -> camera. Use frame-rate-independent damping.

| Aspect | Starting values |
|---|---|
| Framing a small slime | Pivot 0.6-0.9 m above the slime's base so it sits in the lower third; distance 4-5 m exploring, 5.5-7 m in combat; pitch -12 to -20 degrees, range -60 to +35; base field of view 55 degrees (try 45-60) |
| Follow | Position damping 10-14 horizontally, 5-7 vertically; ignore vertical motion under 0.3 m so hops do not bob the view; look-ahead 0.5-1 m along velocity |
| Auto-recentre | Only while moving and after 1.5-2 s without mouse input; manual input always wins |
| Collision | Sphere-cast from pivot to camera (radius 0.2-0.3 m): snap in at once, ease back out; "whisker" rays to either side steer gently around obstacles; fade the slime when the camera is within 0.8 m |
| Tall targets | Bias the look-at point 0.3-0.5 m above the midpoint between the slime and what it faces |
| Tackle kick | Field of view +8-12 degrees over 80-100 ms, back over 250-350 ms, arm +0.3-0.5 m, with speed lines |
| Zoom punch | -2 to -4 degrees on heavy hits, recovering in 150-250 ms; one additive "field-of-view stack" so kicks, punches and cuts compose |
| Lock-on (optional; ask before binding a key) | Candidates within 20-25 m and a 45-60 degree cone with line of sight; camera keeps both in frame; the player still moves freely; break on death, distance or lost sight; small rotating bracket reticle |
| Area triggers | Volumes that change distance and field of view over a transition time |

Veldora's chamber and dialogue: the entrance trigger pulls the camera back and widens the view for the reveal. On "speak" (E), blend over 400 ms to a low camera near the slime looking up: slime in the lower-left third, his head in the upper right, field of view about 45. The dialogue box must never cover his eyes. Blend back over 300 ms when dialogue ends.

Skill presentation (cut-in): for signature moments only (devouring a large target, first use of a new form, a skill being acquired): a slanted band (15-25 degrees) slides across in 80-120 ms with a close-up of the slime and the skill icon over moving speed lines, holds 300-500 ms, exits in 80 ms on a white frame; the skill name slams in at scale 1.6 -> 1.0 over 100 ms and holds 600-900 ms. Full version once per life, a 250 ms version afterwards, and a setting to shorten it always.

## 14. UI and HUD overhaul

Restyle every existing screen in the manner of anime mobile action games, adapted to keyboard and mouse. Keep all existing information and bindings. Draw original icons as two-tone SVGs with a dark outline.

### 14.1 Type (all SIL Open Font License; self-host, ship OFL.txt, system fallbacks until the files exist)

| Role | Family (alternative) | Size at 1080p |
|---|---|---|
| Combat callouts, banners, big titles | Dela Gothic One (Russo One) | 56-96 px |
| HUD labels, body, dialogue | Barlow Condensed (Kanit) | labels 16-18 px minimum, dialogue 22-26 px |
| Numerals, cooldowns | Teko (Russo One) | 28-36 px |
| Damage numbers | Bangers | 28-64 px |
| Voice of the World, scan readouts | Chakra Petch (Rajdhani) | 20-24 px |
| Last thoughts and rebirth titles | Cinzel | 40-56 px |

Where a family has no italic, skew the text container by -10 degrees. Display text gets a 4-6 px dark stroke painted behind the fill and a hard 4 px drop shadow. Scale all sizes with the smaller viewport dimension. No text under 16 px at 1080p.

### 14.2 Global rules

- One slant everywhere: -12 degrees on panels, bars, buttons and tabs, with content counter-skewed.
- Panels: navy at 88% opacity, a 2 px bright edge, a faint diagonal-stripe or halftone texture. One accent per context (cyan = player, yellow-orange = ready or critical, magenta-red = danger).
- Motion: entrances ease out over 120-200 ms with slight overshoot; exits are faster; nothing moves linearly.
- Layering (RULE): world < HUD < banners < dialogue < modal backdrop < modal < transition wipes, under one modal manager. Opening any modal hides the HUD and message log and blocks their input.
- Keep the central 40% of the screen clear during play; pin HUD groups to safe margins on ultrawide.

### 14.3 Screens

| Screen | Redesign |
|---|---|
| Status box (top-left) | Skewed portrait frame with a slime icon; name in the display face; "Rank E" and "Life 1" as chips. Health: skewed bar with a pale ghost segment draining 0.4-0.6 s late, a one-frame white flash on change, a 2-3 px shake on damage, numerals at the right. Magicules: cyan bar beneath. Stamina: a thinner yellow bar bound to the existing value; if none exists, remove the label rather than invent a mechanic |
| Skill and form selectors (bottom-right) | A large tackle button (LMB) beside the current skill button (RMB) with its icon and, only if cooldowns exist, a clock-wipe, seconds remaining and a ring flash with a 1.0 -> 1.2 -> 1.0 pop when ready. Keycap tags: Q with the next skill's icon, Z with the current form, H with the potion count. Changing skill or form slides the icons and flashes the name |
| Controls hints | Compact keycap chips, bottom-left, replacing the sentence strip; contextual ("F Devour", "E Speak" appear only when valid, and beside the target); a setting hides them |
| Dialogue box | Wide skewed panel at the bottom; speaker name on a raised tab. Thought-speech ("Veldora (in thought)") uses italic text and a softly glowing dashed border. Text types at 30-60 characters per second; a click completes the line. Choices are skewed buttons with 1/2/3 keycaps; hover lifts, selection flashes. A bouncing chevron marks "continue" |
| Voice of the World | A separate, calm system layer: thin centred window, cool cyan-white text, bracket ornaments, lighter typeface, typed out with a soft chime; messages queue. Past messages stack in a small log at the left edge and fade after 4-6 s |
| Banners | Full-width skewed strip sliding in over 120 ms; text slams with overshoot; a light sweep crosses it; hold 1-1.5 s; exit to the other side. For area names ("Sealed Cave") and major announcements (skill acquired, evolution) |
| Scan readout (R) | Bracket reticle pops onto the target (1.5 -> 1.0 in 100 ms); a small panel on a leader line types out name, rank chip, weaknesses and devour gains from existing data |
| Damage numbers | Spawn at the hit point with a small random offset; scale 0 -> 1.4 in 60 ms -> 1.0 in 80 ms; drift up 40-60 px over 500-700 ms; fade in the last 200 ms; real time. White normal; yellow-orange, larger and shaking for criticals; element colours for elemental hits; green "+N" for healing; red for damage to the player. Merge rapid multi-hits into one growing number; cap about 30 live |
| Status sheet (Tab) | Full-screen modal sliding in over 200 ms: a large slime portrait with name, race, rank and existence points on the left; skills by tier with icons, resistances and forms on the right; skewed section headers |
| Hurt and low health | 200 ms red vignette on damage; slow pulse at low health |

### 14.4 Last thoughts, rebirth, and the two bug fixes

Last thoughts choreography
1. On death the world slows to 0.2x, desaturates and darkens behind an opaque backdrop; the HUD and message log are hidden.
2. Voice of the World lines type out above the cards, inside the modal.
3. Cards deal in from below with a 60-80 ms stagger and flip face-up (250 ms each) with a soft chime.
4. Card face: skewed header strip with the thought's name, a large icon, two lines of text, a rarity gem, and the gold edge restyled.
5. Hover: the card lifts 12-16 px, tilts toward the cursor (up to 8-10 degrees) and glows at the edge; the others dim to 60%. Number keys, arrows and Enter also work.
6. Select: the chosen card moves to the centre and grows, the others fall away over 200 ms, a brief white-out, then a "Confirmed." line from the Voice of the World.
7. "Be born [Enter]" is a large skewed primary button shown only when a choice is valid.

Rebirth and race spin: present the result the game already determines; add no spin logic. A reel of race cards accelerates in 200 ms, runs 1.2-2 s, eases out over 1.5-2.5 s with a tick per card, locks with an 80-120 ms freeze and a white flash; the card scales 1.0 -> 1.3 with a radial burst, the race name appears in banner style and the Voice of the World confirms it. A click skips to the lock. Then a wipe into the new life.

Bug fixes (the only logic changes allowed)
- The message log showing through the Last thoughts panel, and the status box overlapping it: fixed by the layering rule and modal manager in 14.2.
- Two cards giving the identical result: make results unique within a hand; if the pool is too small, deal fewer cards rather than a duplicate. Tell me the cause.

Acceptance: every screen uses the shared fonts, slant and palette; nothing overlaps or shows through a modal at 1280x720, 1920x1080 and ultrawide; every existing key still works.

## 15. Audio pass (brief)

- Every interaction gets a sound; gameplay sounds sit above ambience and are compressed so they cut through.
- Hit sounds in three layers fired together (short high snap, low body thud, a character layer by damage type; slime hits get a wet "blorp"), with 3-5 variants, slight random pitch and volume, starting on the first frame of hit stop.
- UI: quiet hover tick, firm confirm, descending cancel, rising ticks for the reel, a clean synthetic chime for the Voice of the World.
- Sources: the CC0 interface sound pack from 4.4; for anything else use CC0 only, verify the licence on the page, and record it in the manifest. Start audio on the first user input.

## 16. Performance and quality tiers

Budget by draw calls and filled pixels, not triangles. Every outlined mesh costs a second draw, and a third if it casts a shadow; instance or merge everything repeated; share materials.

| Setting | Low | Medium | High |
|---|---|---|---|
| Pixel ratio cap | 1.0-1.25 | 1.5 | 2.0 |
| Draw calls | <= 100 | <= 200 | <= 500 |
| Triangles in view | <= 150k | <= 400k | <= 1.5M |
| Shadows | Blob only | 1 x 1024 | 1 x 2048 |
| Outlines | Player and key characters | All characters and props | Plus environment edge pass |
| Post | Tone map + FXAA | Bloom, tone map, SMAA | Full stack, half-float |
| Lights | Key + fill | + 2 point | + 4-6 point |
| Grass instances | 5-15k | 30-60k | 100k+ |
| Water | Baked shoreline | Depth foam | + refraction |
| Slime | Opaque banded | + core mesh | + fake refraction |

Detect a tier at start-up with a short frame-time probe; at runtime, if the average frame time stays above about 20 ms for two seconds, step the pixel ratio down by 0.25, then drop effects. Beyond the first level-of-detail distance, drop outlines and shadow casting. Target 60 fps on medium.

## 17. Passes, deliverables and acceptance

| Pass | Deliverables | Done when |
|---|---|---|
| 0. Pipeline and renderer | Project audit; pinned versions; `visualConfig` and debug panel; asset manager, manifest, `ASSETS_TODO.md`, `CREDITS.md`; composer with tone mapping, fog and colour management; screenshot bookmarks; "before" screenshots | Game plays identically; a missing asset yields a stand-in and one warning; frame stats reported |
| 1. Toon material and outlines | `makeToon`, ramps, hull outline with smoothed normals, key light, re-thresholded shadows, blob shadows, applied to everything currently on screen | Every object is two-tone with a tinted shade; outline width holds near and far; no split hulls or shadow speckle |
| 2. Slime | Section 5 complete | Section 5 acceptance |
| 3. Cave environment | Section 9 complete, with pack assets or stand-ins | Section 9 acceptance |
| 4. Veldora and the seal | Section 6 complete | Section 6 acceptance |
| 5. Monsters | Section 7 for every monster in the build | Section 7 acceptance |
| 6. VFX and game feel | Time architecture, hit stop, shake, flashes, effect library, devour vortex, skill effects, hit sounds | A tackle hit shows stop, flash, spark, shake, number and sound in one frame; settings respected |
| 7. UI and HUD | Section 14 complete, both bugs fixed | Section 14 acceptance |
| 8. Camera and polish | Section 13, cut-ins, colour grade, area banner | Chamber reveal and dialogue framing work; hops do not bob the camera |
| 9. Performance and tiers | Tier detection, adaptive quality, levels of detail, final report | Budgets in section 16 met on medium |

Final hand-over: before and after screenshot pairs for every bookmark; the regression checklist ticked; the complete `CREDITS.md`; the state of `ASSETS_TODO.md`; the list of tunables; and this before/after checklist answered yes or no:
- No raw primitive is visible anywhere.
- Every character has a tinted two-tone shade and a coloured ink line.
- No shadow anywhere is grey or black.
- The cave is dark in hue but readable in value; the route to Veldora is obvious.
- Only emissive things glow.
- The slime reads as jelly, not as a sphere.
- Veldora reads as a dragon in silhouette and tracks the slime.
- A hit feels like a hit with the sound off, and with the screen effects off.
- All text is at least 16 px at 1080p, outlined where it sits over the world.
- Nothing overlaps or shows through any modal.
- Every key and system from section 1 behaves as before.

## 18. What to do first

1. Confirm the ENGINE line; inspect the project and report what you find (rule 1), including the installed library versions and the versions you propose to pin.
2. List every skill, form, monster and UI screen that exists in the build, so later passes cover exactly those.
3. Give me a one-page plan for Pass 0 with the folder layout and the `visualConfig` outline, and write `ASSETS_TODO.md` if you cannot download files.
4. Then do Pass 0 only, show the "before" screenshots and frame stats, and wait.
````

## What is sourced and what is not

**Backed by sources the research read.** The style rules rest on documented studio practice: Arc System Works' hard lit-or-shadow split, per-material shadow tint, per-character light, no normal maps, inverted-hull lines with per-vertex width and hand-keyed animation ([Motomura, GDC 2015](https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf); [ASW Academy line slides](https://docswell.com/s/ASW_Academy/5LVY67-GG-Toonline-Eng)); miHoYo's "bright and clean" brief and its rejection of ACES tone mapping ([Unity Japan deck](https://www.docswell.com/s/UnityJapan/KWRPQ5-210617-unity-dojo20211mihoyozhenzhongyi)) and its split between geometry lines on characters and screen-space lines on scenery ([Unite Tokyo 2018 deck](https://image.docswell.com/s/UnityJapan/KWLQP5-unite-tokyo-20183rd)); the "plastic figure" failure mode of realistic surfaces on anime characters ([Push Square](https://pushsquare.com/reviews/ps4/jump_force), [Nintendo Life](https://www.nintendolife.com/news/2021/11/random-ever-wondered-what-zelda-breath-of-the-wild-looks-like-without-cel-shading)); and the open-world lessons that flat colour looks empty at scale and that detail should simplify with distance ([CyberConnect2 interview](https://www.unrealengine.com/developer-interviews/cyberconnect2-shares-how-its-artists-faithfully-recreated-the-dragon-ball-z-universe-in-3d), [BotW CEDEC report](https://www.thefamicast.com/2017/12/part-5-art-and-implementation-of-3d.html)). The renderer advice follows the Three.js manual's statement that WebGPURenderer is experimental and does not support `ShaderMaterial`, `onBeforeCompile` or `EffectComposer` ([Three.js manual](https://threejs.org/manual/pages/webgpurenderer.html)), the documented nearest-filter gradient map ([MeshToonMaterial docs](https://threejs.org/docs/pages/MeshToonMaterial.html)), `OutlineEffect`'s defaults and WebGL-only status ([OutlineEffect docs](https://threejs.org/docs/pages/OutlineEffect.html)), the pmndrs renderer and half-float guidance ([postprocessing README](https://cdn.jsdelivr.net/npm/postprocessing@6.39.4/README.md)) and a forum overview of how ACES, Neutral and AgX treat colour ([tone mapping overview](https://discourse.threejs.org/t/tone-mapping-overview/75204)). Pack contents, formats and CC0 status come from each pack's own page (listed under Sources), font licences from the Google Fonts repository ([google/fonts](https://github.com/google/fonts)), the shake model from Bevy's camera-shake example ([Bevy](https://bevy.org/examples/camera/2d-screen-shake/)), the effect-building toolkit from two VFX breakdowns ([80.lv beam](https://80.lv/articles/crafting-a-kamehameha-like-vfx-001agt/), [80.lv Zelda-style](https://80.lv/articles/creating-stylized-combat-vfx-in-the-zelda-style/)), the camera ingredients from an Unreal Engine write-up ([Unreal Engine](https://www.unrealengine.com/tech-blog/six-ingredients-for-a-dynamic-third-person-camera)), the grass system from a Codrops build ([Codrops](https://tympanus.net/codrops/2025/02/04/how-to-make-the-fluffiest-grass-with-three-js/)), and the off-screen light-shaft limitation from a cave thread on the Three.js forum ([forum](https://discourse.threejs.org/t/help-with-persistent-volumetric-light-god-rays-light-shafts-sunbeam-sunburst-for-underground-cave-scene/79085)). The monster descriptors and the cave's contents come from the earlier game design prompt, which drew on the Tensura wiki ([Sealed Cave](https://tensura.fandom.com/wiki/Sealed_Cave), [Tempest serpent](https://tensura.fandom.com/wiki/Tempest_serpent)).

**Not sourced: treat as starting points.**

- **One Piece Bounty Rush's look.** Only its engine (Unity, via a Wikipedia mirror), developer, format and low PC requirements are documented ([Wikipedia mirror](https://wikwiand-revamp.pages.dev/en/One_Piece_Bounty_Rush), [Steam](https://store.steampowered.com/app/2918150/ONE_PIECE_Bounty_Rush/)). No technical or art breakdown of its shading, outlines, camera or HUD was found; every description of how it looks is the researcher's observation. The prompt therefore uses it as a mood reference and builds the rules from other studios' documented practice.
- **Every number and colour.** All hex values, band thresholds, rim and outline widths, shadow biases, bloom and vignette settings, slime spring values, the hit-stop table, camera distances and field-of-view changes, UI sizes and timings, and the quality-tier table are the researchers' recommendations or my design suggestions, not measurements. The hit-stop table is deliberately a third to a half of fighting-game values (about 150-230 ms per hit in [Street Fighter-style games](https://sonichurricane.com/?p=1043)), on the reasoning that freezes should shorten when many fighters are involved ([Sakurai](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/)).
- **Two of the style rules.** "Dark in hue, not dark in value" and "silhouette first" are the researcher's synthesis. No source was found on stylising dark or underground areas in anime-style games, and none states silhouette as an explicit rule, although the outline and exaggeration practices above all serve it.
- **Shader and engine recipes.** The toon shader, clip-space hull, shadow re-thresholding, toon-jelly slime, water, crystals and the Unity and Godot one-liners come from the researcher's working knowledge and were not verified against a fetched page or tested. The same holds for three-vrm's built-in outline and spring-bone behaviour. The prompt tells the assistant to check each against the pinned version.
- **Versions.** r186 (September 2026) is the newest Three.js release the research could confirm ([CGWORLD](https://cgworld.jp/flashnews/01-202610-Threejs-r186.html)); whether a newer one exists is unknown. Sources disagree on the latest three-vrm (3.4.4 on one mirror, 3.5.x on a CDN). Only `postprocessing` 6.39.4 was seen. Hence the instruction to run `npm view`.
- **What is inside the creature packs.** Pack-level availability is confirmed; which specific creatures each Quaternius monster or dinosaur pack contains is not. No free pack was confirmed for a crystal cave, a rigged dragon, a spider, a centipede or a snake, which is why the prompt builds those in code.
- **Licence details at the edges.** Mixamo's terms rest on a 2022 Adobe community FAQ plus a 2026 secondary guide ([Adobe Community](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400)); baking clips into your own files is a cautious reading, not Adobe's wording. Free-tier Tripo terms come from one vendor blog; that blog also calls Meshy's free tier non-commercial, which conflicts with Meshy's own help page ([Meshy](https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects)). The exact permissions of the Open Font License, which font families have true italics, and the licences of Kenney packs other than the two named were not checked on primary pages.
- **UI conventions and reveal choreography.** No source documents typography or layout rules for anime action games, card reveals or roulette screens; that section is genre convention as the researcher knows it.
- **Legal position.** Imitating a general style is ordinary practice, and using a franchise's names and characters in a fan game depends on the rights holder's tolerance. This is general information, not legal advice; no fan-content policy for this series was researched.

## Sources

- Studio practice: [Motomura, Guilty Gear Xrd GDC 2015 slides](https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf); [ASW Academy toon-line slides](https://docswell.com/s/ASW_Academy/5LVY67-GG-Toonline-Eng); [Guilty Gear Strive interview](https://www.unrealengine.com/en-US/developer-interviews/how-guilty-gear--strive--hits-an-ultra-combo-with-groundbreaking-visuals-and-gameplay); [miHoYo console rendering deck](https://www.docswell.com/s/UnityJapan/KWRPQ5-210617-unity-dojo20211mihoyozhenzhongyi) and [talk notes](https://nugglet.github.io/posts/2022/12/console_graphics_rendering_pipeline_genshin_impact); [Honkai Impact 3rd, Unite Tokyo 2018](https://image.docswell.com/s/UnityJapan/KWLQP5-unite-tokyo-20183rd); [B. Ayers character shader breakdown](https://bjayers.artstation.com/blog/category/5); [CyberConnect2 interview](https://www.unrealengine.com/developer-interviews/cyberconnect2-shares-how-its-artists-faithfully-recreated-the-dragon-ball-z-universe-in-3d); [Siliconera on CyberConnect2](https://www.siliconera.com/evolution-of-cyberconnect-2s-anime-style-graphics/); [BotW CEDEC report](https://www.thefamicast.com/2017/12/part-5-art-and-implementation-of-3d.html); [Dragon Quest XI spotlight](https://www.unrealengine.com/en-US/spotlights/how-dragon-quest-xi-came-to-life-with-unreal-engine-4); [Push Square on Jump Force](https://pushsquare.com/reviews/ps4/jump_force); [TheSixthAxis on Jump Force](https://www.thesixthaxis.com/2018/07/02/jump-force-is-a-flashy-anime-crossover-but-something-feels-off/); [Nintendo Life on BotW without cel shading](https://www.nintendolife.com/news/2021/11/random-ever-wondered-what-zelda-breath-of-the-wild-looks-like-without-cel-shading)
- One Piece Bounty Rush: [Wikipedia mirror](https://wikwiand-revamp.pages.dev/en/One_Piece_Bounty_Rush); [Steam page](https://store.steampowered.com/app/2918150/ONE_PIECE_Bounty_Rush/); [Pocket Gamer review](https://www.pocketgamer.com/articles/079922/one-piece-bounty-rush-video-review/)
- Three.js and rendering: [WebGPURenderer manual](https://threejs.org/manual/pages/webgpurenderer.html); [MeshToonMaterial docs](https://threejs.org/docs/pages/MeshToonMaterial.html); [OutlineEffect docs](https://threejs.org/docs/pages/OutlineEffect.html); [r186 news, CGWORLD](https://cgworld.jp/flashnews/01-202610-Threejs-r186.html); [pmndrs postprocessing README](https://cdn.jsdelivr.net/npm/postprocessing@6.39.4/README.md); [tone mapping overview](https://discourse.threejs.org/t/tone-mapping-overview/75204); [pmndrs tone mapping guidance](https://discourse.threejs.org/t/pmndrs-post-processing-tone-mapping-guidance/59374); [post-process outline tutorial thread](https://discourse.threejs.org/t/how-to-render-full-outlines-as-a-post-process-tutorial/22674); [Seaside Studios outline docs](https://seasidestudios.gitbook.io/seaside-studios/3d-shader/outlines); [Hon Tran, Three.js performance](https://www.hontran.dev/blog/three-js-performance-optimization); [Codrops grass](https://tympanus.net/codrops/2025/02/04/how-to-make-the-fluffiest-grass-with-three-js/); [Tuts+ toon water](https://code.tutsplus.com/creating-toon-water-for-the-web-part-2--cms-30485t); [cave god rays thread](https://discourse.threejs.org/t/help-with-persistent-volumetric-light-god-rays-light-shafts-sunbeam-sunburst-for-underground-cave-scene/79085); [three-good-godrays README](https://cdn.jsdelivr.net/npm/three-good-godrays@0.12.0/README.md)
- Assets and licences: [Quaternius Stylized Nature MegaKit](https://quaternius.com/packs/stylizednaturemegakit.html); [Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html); [Quaternius LowPoly Animated Monsters](https://quaternius.itch.io/lowpoly-animated-monsters); [Quaternius itch.io profile](https://quaternius.itch.io/); [KayKit Forest Nature Pack](https://kaylousberg.itch.io/kaykit-forest); [KayKit Dungeon Remastered](https://kaylousberg.itch.io/kaykit-dungeon-remastered); [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers); [KayKit Skeletons](https://kaylousberg.itch.io/kaykit-skeletons); [Kenney Nature Kit](https://kenney.nl/assets/nature-kit); [Kenney Particle Pack](https://kenney.nl/assets/particle-pack); [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds); [VRoid CC0 models on OpenGameArt](https://opengameart.org/content/vroid-studio-cc0-models); [Poly Pizza fact sheet](https://poly.pizza/docs/press); [Poly Haven licence](https://www.polyhaven.com/license); [Cinevva guide to free 3D model sites](https://app.cinevva.com/guides/free-3d-model-sites); [Cinevva guide to free animations and rigging](https://app.cinevva.com/guides/free-character-animations-rigging); [pixiv three-vrm](https://github.com/pixiv/three-vrm/); [vrm-mixamo-retarget README](https://unpkg.com/vrm-mixamo-retarget@1.0.3/README.md); [VRoid Studio guidelines](https://vroid.com/en/studio/guidelines); [VRoid Hub conditions of use](https://developer.vroid.com/en/guidelines/conditions_of_use.html); [Adobe Community Mixamo FAQ](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400); [glTF-Transform CLI](https://www.npmjs.com/package/@gltf-transform/cli); [Meshy help on asset licences](https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects); [Sorceress blog on free AI 3D generators](https://sorceress.games/blog/best-free-ai-3d-model-generator-honest-2026-picks); [google/fonts repository](https://github.com/google/fonts)
- Game feel, effects, animation, camera: [Sakurai on hit stop, Source Gaming](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/); [SmashWiki, Hitlag](https://ssbwiki.com/Hitlag); [Sonic Hurricane, Impact Freeze](https://sonichurricane.com/?p=1043); [uhiyama-lab hit feedback](https://uhiyama-lab.com/en/notes/ue/game-feel-hit-feedback/); [Bevy screen shake example](https://bevy.org/examples/camera/2d-screen-shake/); [Game Developer on juice](https://gamedeveloper.com/design/squeezing-more-juice-out-of-your-game-design-); [80.lv impact frames](https://80.lv/articles/learn-how-to-add-accents-to-your-animations-with-impact-frames); [80.lv anime beam breakdown](https://80.lv/articles/crafting-a-kamehameha-like-vfx-001agt/); [80.lv Zelda-style combat VFX](https://80.lv/articles/creating-stylized-combat-vfx-in-the-zelda-style/); [VFX Apprentice on flipbooks](https://www.vfxapprentice.com/blog/what-are-flipbooks-in-games); [Three.js From Zero, procedural animation](https://masterallarts.pages.dev/learn/threejs-from-zero/s3-05-procedural-animation/); [jayts, fighting game feel](https://jayts.neocities.org/guide/smooth.html); [Unreal Engine, dynamic third-person camera](https://www.unrealengine.com/tech-blog/six-ingredients-for-a-dynamic-third-person-camera); [Mythicism target-lock devlog](https://arcanestudios.itch.io/mythicism/devlog/368083/target-lock-tech-discussion); [Wayline damage numbers](https://www.wayline.io/blog/godot-dynamic-damage-numbers)
- Game world: [Sealed Cave](https://tensura.fandom.com/wiki/Sealed_Cave); [Tempest serpent](https://tensura.fandom.com/wiki/Tempest_serpent)
