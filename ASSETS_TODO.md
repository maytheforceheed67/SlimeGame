# Assets to download

The visual overhaul (docs/VISUAL_STYLE.md, section 4.4) can use these free
packs. I could not download them from the build environment: its network
rules refuse kenney.nl, quaternius.com, itch.io, opengameart.org and
poly.pizza. Nothing is blocked by that. Every asset has a stand-in built in
code, and a pack only replaces a stand-in once its files are here.

Fonts are the exception: the Google Fonts repository is reachable, so I will
fetch the font files and their OFL.txt myself in Pass 7.

## What to do

1. Download the packs you want from the list below. Take the **free** tier
   where a page offers several.
2. Unzip each into its own folder under `assets_raw/`, using the folder name
   given. Leave the contents untouched. (`assets_raw/` is ignored by git and
   by Godot, so nothing there is imported or committed.)
3. Run this and send me the output:

   ```
   GODOT=/path/to/godot tools/inspect_assets.sh > assets_report.txt
   ```

   It lists the files and, for every model, its node names and animation clip
   names. I fill the asset manifest from that report rather than guessing
   names, copy only the files the game uses into `assets/`, and record each in
   `CREDITS.md`.

Godot reads `.glb`, `.gltf` and `.fbx` directly, so there is no conversion
step. Where a pack offers a choice, prefer glTF.

Check the licence line on each page when you download. Everything listed was
CC0 when the style document was written; if a page now says otherwise, tell me
and skip it.

## Checklist

| # | Needed for | Pack | Page | Licence | Unzip into |
|---|---|---|---|---|---|
| 1 | Pass 3, cave rocks and plants | Quaternius Stylized Nature MegaKit (free tier) | https://quaternius.com/packs/stylizednaturemegakit.html | CC0 | `assets_raw/quaternius_nature_megakit/` |
| 2 | Pass 3, cave and dungeon pieces | KayKit Dungeon Remastered (free) | https://kaylousberg.itch.io/kaykit-dungeon-remastered | CC0 | `assets_raw/kaykit_dungeon/` |
| 3 | Pass 3, filler rocks and plants | Kenney Nature Kit | https://kenney.nl/assets/nature-kit | CC0 | `assets_raw/kenney_nature_kit/` |
| 4 | Pass 5, bat candidate | Quaternius LowPoly Animated Monsters | https://quaternius.itch.io/lowpoly-animated-monsters | CC0 | `assets_raw/quaternius_monsters/` |
| 5 | Pass 5, armoured lizard candidate | Quaternius Animated LowPoly Dinosaurs | https://quaternius.itch.io | CC0 (confirm on the page) | `assets_raw/quaternius_dinosaurs/` |
| 6 | Pass 6, effect textures | Kenney Particle Pack | https://kenney.nl/assets/particle-pack | CC0 | `assets_raw/kenney_particle_pack/` |
| 7 | Pass 6 and 7, interface sounds | Kenney Interface Sounds | https://kenney.nl/assets/interface-sounds | CC0 | `assets_raw/kenney_interface_sounds/` |
| 8 | Later regions, forest | KayKit Forest Nature Pack (free) | https://kaylousberg.itch.io/kaykit-forest | CC0 | `assets_raw/kaykit_forest/` |

Not needed until humanoids are built, and only after you choose a route
(section 8 of the style document): Quaternius Universal Base Characters,
Modular Character Outfits and Universal Animation Library; KayKit Adventurers
and Skeletons; the VRoid CC0 sample avatars.

## Built in code regardless

No free pack was found for these, so they stay procedural: the slime, Veldora
and his seal, the tempest serpent, the centipede, the spider, crystal
clusters, stalactites, ore veins, the lake, and all effects.

## Status

| # | Pack | State |
|---|---|---|
| 1-8 | all | not downloaded |
| - | Google Fonts (Dela Gothic One, Barlow Condensed, Teko, Bangers, Chakra Petch, Cinzel) | I will fetch these in Pass 7 |
