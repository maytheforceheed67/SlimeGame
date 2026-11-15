# SlimeGame

A third-person 3D reincarnation roguelike set in the world of *That Time I Got
Reincarnated as a Slime*. Personal, non-commercial fan project. All models,
art, interface and text in this repository are original; nothing is taken from
the series' official artwork, music, logos or book text.

Engine: **Godot 4.3 or newer** (GDScript, Compatibility renderer).

- Design document: [docs/DESIGN.md](docs/DESIGN.md), the source of truth.
- Milestone 0 plan, schemas, test checklist and open questions:
  [docs/MILESTONE_0.md](docs/MILESTONE_0.md).
- Visual overhaul: the style brief is [docs/VISUAL_STYLE.md](docs/VISUAL_STYLE.md);
  progress by pass is under [docs/visual/](docs/visual/)
  ([Pass 0](docs/visual/PASS_0.md), [Pass 1](docs/visual/PASS_1.md)).
  Assets to download: [ASSETS_TODO.md](ASSETS_TODO.md).
  Credits: [CREDITS.md](CREDITS.md).

## Running it

1. Open the Godot project manager, choose **Import**, and select `project.godot`.
2. Let the editor finish its first import, then press **Run Project** (F5).

The first open creates `.godot/` (ignored by git). Godot also writes `*.import`
and `*.uid` files next to assets and scripts; those are committed.

The save file is `user://soul.json` (the soul's memory). To start over as a
soul with no past, delete it, or press **5** in a debug build.

## Controls

| Input | Action |
|---|---|
| W A S D / left stick | Move |
| Space / pad A | Hop. In water: swim up, or jet with Hydraulic Propulsion |
| Mouse / right stick | Look. Wheel zooms |
| Left mouse / pad X | Tackle (or a Mimicry form's first move) |
| Right mouse / pad Y | Bound skill (or a form's second move). With no skill: spit stored water |
| Q / d-pad right | Bind the next skill, or a practice move such as Water Spit |
| F (hold) / pad B | Devour what is in reach; store water while submerged |
| E / d-pad left | Speak, continue a conversation |
| R / pad RB | Scan with the advisor. While sightless: hold still and hold it to feel magicules |
| Shift (hold) / pad LB | Cling to a wall and climb (uses stamina) |
| Ctrl or C (hold) / left stick click | Flatten to squeeze under low rock; in water: swim down |
| Z / d-pad up | Next Mimicry form |
| H / d-pad down | Drink a healing potion |
| Tab / Start | Status sheet (pauses) |
| Y / N | Answer a Yes/No prompt |
| Enter / pad A | Confirm the last thoughts (Space never does; with nothing chosen it asks twice) |
| Esc | Free or capture the cursor |

Debug builds only: **F3** overlay, **F4** visual settings (live tuning of every
colour and number of the look), **1** +500 EP, **2** double EP, **3** Voice
test, **4** die (cycles the cause), **5** erase the soul's memory.

## Layout

```
project.godot
docs/                   DESIGN.md (the design document), MILESTONE_0.md
data/                   content tables (JSON): the only place lore lives
  ranks.json              EP bands, danger classes, thresholds
  races.json              the eight starting races and their evolution lines
  skills.json             skill categories, sub-functions, actives, passives, practice
  fusions.json            fusion and evolution chains (the upgrade tree)
  resistances.json        resistances and their merge tree
  damage_types.json       damage types, statuses, the resistance each imprints
  creatures.json          monsters: stats, attacks, devour gains, placeholder models
  items.json, recipes.json  what the Stomach holds and synthesises
  regions.json            regions, magicule density, spawn rules
  dialogues.json          conversations (original wording)
  wish_cards.json         last thoughts offered at death
  spin.json               reincarnation spin: origins, affinities, first life
  voice_lines.json        every line the Voice of the World and the advisor speak
  tuning.json             every global [DESIGN] number
  visual_config.json      every visual tunable (palette, post, fog, outline, tiers...)
  asset_manifest.json     one entry per model, texture, font and sound
assets/                 third-party files in use (empty until packs are added)
assets_raw/             untouched downloads; ignored by git and by Godot
scripts/
  autoload/               singletons, loaded in this order
    database.gd             Database: loads and cross-checks data/
    (visual/)               Visual, Toon and Assets, listed under visual/ below
    voice_of_world.gd       Voice: the announcer and Yes/No prompts
    soul.gd                 Soul: what survives death (saved to disk)
    game.gd                 Game: the current life and the run loop
  core/                   LifeState, Vitals, Wishes, InputBindings
  combat/                 Combat rules, Attacker, Projectile
  creatures/              Creature (behaviour), CreatureVisual (placeholder bodies)
  player/                 Player body and orbit camera
  skills/                 Predator and Advisor modules
  visual/                 the look, kept apart from the rules
    visual_config.gd        Visual: every visual tunable, live-editable (F4)
    toon.gd                 Toon: the one place a material is made
    asset_manager.gd        Assets: a model by id, from a file or a stand-in
    stand_ins.gd            models built in code
    mesh_kit.gd             shared shapes, smoothed normals, mesh baking
    world_look.gd           tone map, bloom, fog, key light
    blob_shadows.gd         a soft disc under every actor
    shaders/                toon (character, world), outline, veil, blob shadow
  world/                  Level, Veldora, water, harvestables, motes, sounds
  ui/                     HUD panels and screens
  main.gd                 entry scene script
scenes/                 main, player, HUD, the generated Sealed Cave
tests/                  headless test scenes and a screenshot tool
tools/
  validate_data.py        checks data/ without opening Godot
  build_sealed_cave.py    generates scenes/world/sealed_cave.tscn from a cell map
  run_tests.sh            validator plus every test scene
  build_credits.py        writes CREDITS.md from the asset manifest
  inspect_model.gd        prints a model file's nodes, clips and size
  inspect_assets.sh       lists assets_raw/ and inspects its models
  capture.sh              renders a named moment to a PNG
```

## Data conventions

Every record in `data/` carries a `label`:

- `CANON`: a fact of the light novels' world. Do not change it for gameplay reasons.
- `DESIGN`: a game adaptation. Numbers are starting values for tuning.
- `UNCONFIRMED`: commonly repeated but not verified against the novels. A tunable default.

Where one record mixes sources, extra keys such as `category_label`,
`rank_label`, `trigger_label` or `field_labels` label the individual fields.
Each file's `_meta.notes` explains its own rules. Global numbers live in
`data/tuning.json`, so tuning rarely means touching a script.

After editing a table, run:

```
python3 tools/validate_data.py
```

The game runs the same reference checks at boot and lists any problem in the
debug overlay (F3) and the Output panel.

## Tests

```
GODOT=/path/to/godot tools/run_tests.sh            # validator + every test scene
GODOT=/path/to/godot tools/run_tests.sh combat     # one scene: tests/test_combat.tscn
```

Each test scene boots the real game headless, drives it with input events and
prints one line per check; the process exits non-zero if any check fails.
`tests/test_full_loop` plays the whole slice across two lives.
`tools/capture.sh <stage> <dir>` renders a staged moment to a PNG (needs
`xvfb-run`; stages are the `_stage_*` functions in `tests/capture.gd`).

## Body and soul

The roguelike rule "knowledge outlives the body" is a hard line in the code:

- `LifeState` (held by `Game`) is the body and this branch of the timeline. It
  is discarded at death.
- `Soul` is memory. It is the only thing written to disk.

A field belongs in `Soul` only if it appears in the "carries over" column of
the design document.

## Exporting

The content tables are plain `.json` files read at run time. When you create
an export preset, add `data/*.json` under **Resources > Filters to export
non-resource files**, or the exported game will boot with no content.
