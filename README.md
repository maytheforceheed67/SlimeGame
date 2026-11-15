# SlimeGame

A third-person 3D reincarnation roguelike set in the world of *That Time I Got
Reincarnated as a Slime*. Personal, non-commercial fan project. All models,
art, interface and text in this repository are original; nothing is taken from
the series' official artwork, music, logos or book text.

Engine: **Godot 4.3 or newer** (GDScript, Forward+ renderer).

## Running it

1. Open the Godot project manager, choose **Import**, and select `project.godot`.
2. Let the editor finish its first import, then press **Run Project** (F5).

The first open creates `.godot/` (ignored by git) plus `*.import` and, on
Godot 4.4+, `*.uid` files next to assets and scripts. Commit the `.import` and
`.uid` files.

## Controls

| Input | Action |
|---|---|
| W A S D / left stick | Move |
| Space / pad A | Hop |
| Mouse / right stick | Look |
| Mouse wheel | Zoom |
| Esc | Free or capture the cursor |
| Y / N (pad X / B) | Answer a Yes/No prompt |

Debug builds only: **F3** overlay, **1** +500 EP, **2** double EP, **3** Voice
test, **4** die (cycles the cause), **5** erase the soul's memory.

## Layout

```
project.godot
data/                  content tables (JSON): the only place lore lives
  ranks.json             EP bands, danger classes, thresholds
  races.json             the eight starting races and their evolution lines
  skills.json            skill categories and every skill named so far
  fusions.json           fusion and evolution chains (the upgrade tree)
  resistances.json       resistances and their merge tree
  damage_types.json      damage types and the resistance each imprints
  regions.json           regions and magicule density levels
  spin.json              reincarnation spin: origins, affinities, first life
  voice_lines.json       every line the Voice of the World can speak
scripts/
  autoload/              singletons, loaded in this order
    database.gd            Database: loads and cross-checks data/
    voice_of_world.gd      Voice: the announcer and Yes/No prompts
    soul.gd                Soul: what survives death (saved to disk)
    game.gd                Game: the current life and the run loop
  core/                  plain classes (LifeState, InputBindings)
  player/                body controller and orbit camera
  ui/                    HUD panels
  world/                 things placed in the world
  main.gd                entry scene script
scenes/                scenes for the above
tools/validate_data.py checks data/ without opening Godot
```

## Data conventions

Every record in `data/` carries a `label`:

- `CANON`: a fact of the light novels' world. Do not change it for gameplay reasons.
- `DESIGN`: a game adaptation. Numbers are starting values for tuning.
- `UNCONFIRMED`: commonly repeated but not verified against the novels. A tunable default.

Where one record mixes sources, extra keys such as `category_label`,
`trigger_label` or `field_labels` label the individual fields. Each file's
`_meta.notes` explains its own rules.

After editing a table, run:

```
python3 tools/validate_data.py
```

The game runs the same reference checks at boot and lists any problem in the
debug overlay and the Output panel.

## Body and soul

The roguelike rule "knowledge outlives the body" is a hard line in the code:

- `LifeState` (held by `Game`) is the body and this branch of the timeline. It
  is discarded at death.
- `Soul` is memory. It is the only thing written to disk (`user://soul.json`).

A field belongs in `Soul` only if it appears in the "carries over" column of
the design document.
