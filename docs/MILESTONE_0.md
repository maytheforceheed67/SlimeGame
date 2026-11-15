# Milestone 0: the Sealed Cave vertical slice

Scope, from section 21 of the design document: *Sealed Cave only. Slime
controller (hop, cling, squeeze, swim); sightless opening until Mana
Perception; Predator's five functions; Great Sage scan and analysis queue with
the link upgrade; herb and ore to potions; serpent, centipede, spider, bat and
armoured lizard with simple behaviours; Water Blade learned by practice;
Veldora dialogue, naming and swallow-by-agreement; Voice of the World banners;
status sheet; death -> wish cards -> rebirth as a slime with codex kept.*

Done when: *a 20-30 minute loop is fun and a second life is visibly faster
because of memory.* The second half is measured by an automated test (below).
Whether it is fun needs you to play it.

## 1. Engine and assumptions

Engine line confirmed: **Godot 4** (4.3 or newer; built and tested on 4.5.1),
GDScript, content in JSON. (The renderer was Forward+ during this milestone;
the visual overhaul moved the project to the Compatibility renderer in its
Pass 1.)

Assumptions and design calls I made where the document left room. Each is
cheap to change; tell me which you want differently.

| # | Decision | Why |
|---|---|---|
| 1 | The prologue grants its thoughts without a choice: Predator, Sage twice (so Great Sage), Pain Nullification, weight toward the slime, and one thought that comes to nothing. Choice starts at the first real death. | The first life is the tutorial for Predator and the Great Sage link, so it must have both. It also teaches what each of those cards does. |
| 2 | A card's result is hidden (shown as "?") until the soul has seen it happen once. | Knowledge outlives the body: learning what wishes do is itself progression. Easy to switch off. |
| 3 | A skill learned by practice (Water Blade, Water Current Motion, Hydraulic Propulsion, Mana Perception) needs only 15% of the practice in a later life. The skill itself is still lost with the body. | Makes a second life visibly faster without adding a permanent stat. |
| 4 | A soul that once linked Analysis to Parallel Processing has Great Sage remake the link at once in later lives. | Same reason. |
| 5 | Nameplates show numeric EP for species the advisor appraised this life, and for species already in the soul's codex. | Section 7 gates numeric EP behind appraisal; remembered analysis is appraisal. |
| 6 | Being named by Veldora adds 200 EP. | Canon says a named monster gains strength; the amount is mine. |
| 7 | The default shared family name is "Tempest" (editable). The given name defaults to a random original suggestion (editable). | Section 18 has the player stand where the story placed its lead; the name is the player's to choose. |
| 8 | Devouring gives 25% of a creature's EP at once; skills, recipes and forms come when Analysis finishes. | Section 7: EP rises through absorbed magicules. |
| 9 | Damage multiplier is the square root of EP / 100, and maximum health is 40 + 2 x the square root of EP. | EP is quantity, not quality: growth matters but skill still decides close fights. |
| 10 | A Mimicry form hits with power sqrt(your EP / the species' EP) and costs magicules per second in proportion to the species' EP over yours. | Section 9.1: forms cost magicules to hold, less as you grow. |
| 11 | "impact" is an added damage type with no imprint. Abnormal Condition Nullification also covers poison. | Section 5 has no blunt entry; the merge inputs are canon, the coverage is my modelling. |
| 12 | Quitting mid-life does not count as a death and the life is not saved. | The two save layers (LifeSave) are Milestone 1. |
| 13 | The form wheel and skill wheel are single "next" buttons for now. | Wheels need more forms and skills than one cave provides. |
| 14 | Without Predator, a slime can still absorb remains and plants for magicules, but keeps and learns nothing. | Absorb is intrinsic; the Stomach and Analysis are Predator's. |

## 2. What is in, and how closely it follows the scope

| Scope item | State | Notes |
|---|---|---|
| Hop, cling, squeeze, swim | Done | Clinging costs stamina and mantles onto ledges. Squeezing shrinks the body to pass a 0.6 m gap. Without Water Current Motion a slime sinks and bounces along the lake bed. |
| Sightless opening | Done | Dark beyond touch; arcs show sounds; Veldora's voice leads along the passages. |
| Predation | Done | Hold to devour. Certain on remains and plants; a chance on the living from EP and stagger. Hostile shots are swallowed while the devour button is held (no timing window yet). Swallowing spells waits for the magic milestone. |
| Stomach | Done | Items, stored water, Veldora held by agreement. |
| Analysis | Done | Queue with slots; grants skills, recipes, forms and codex entries. |
| Mimicry | Done | Five forms with their moves; bat form glides and flaps. "Forms improve when followers evolve" needs followers (Milestone 2). |
| Isolation | Done, thin | Turns swallowed toxin into magicules. The cave has no standing hazards (poison pools) yet, so its "answer to hazards" role is only shown against poison shots. |
| Great Sage scan | Done | Rank, EP, health, weaknesses, resistances, devour gains. Sage gives a basic version. |
| Analysis queue and link upgrade | Done | Offered as a Yes/No prompt when the first analysis starts; about fifty times faster. |
| Herb and ore to potions | Herb done | Hipokute herb teaches the healing potion. Magic ore is analysed and stocked; it has no recipe until crafting (Milestone 4). |
| Five monsters | Done | One behaviour routine driven by each attack's range band. No pathfinding: creatures stay near their homes. |
| Water Blade by practice | Done | Eight spits of stored water. |
| Veldora | Done | Thought-speech, lesson, friendship, exchange of names, carried by agreement. |
| Voice of the World banners | Done | Paced lines, broadcasts, Yes/No prompts; the advisor has its own colour and corner. |
| Status sheet | Done | Identity, vitals, skills by tier with sub-functions, resistances, Arts, Stomach, analysis, forms, recipes. |
| Death, wish cards, rebirth | Done | Slow motion, drained colour, imprint, six to eight cards, up to three chosen. |
| Not in scope, not built | | Lock-on, dodge, Thought Acceleration, auto-battle, fusion tree (Milestone 3), sound and music, final art, LifeSave. |

## 3. Technical plan

```
Database  (autoload)  loads data/*.json, cross-checks ids, answers lookups
Voice     (autoload)  the only announcer: paced lines, broadcasts, Yes/No
Soul      (autoload)  memory; the only state saved to disk
Game      (autoload)  the current LifeState and the run loop

Main
├─ SealedCave (Level)      fixed geography; seeds what each life finds
│   └─ Spawned             creatures, herbs, ore, motes, Veldora, sounds
├─ Player (CharacterBody3D)
│   ├─ Attacker            runs one attack at a time (shared with creatures)
│   ├─ Predator            predation, Stomach, Analysis, Isolation
│   ├─ Advisor             scan, link upgrade, hints
│   └─ CameraRig           orbit camera on a spring arm
└─ HUD (CanvasLayer)       veil, nameplates, senses, status, prompts,
                           dialogue, names, death screen, status sheet
```

Rules the code holds itself to:

- **Body and soul.** `LifeState` is discarded at death. `Soul` holds only the
  "carries over" column of section 3.
- **One rule set.** The player and every creature fight through the same
  `Vitals` (health, statuses, resistance growth) and `Attacker` (attacks as
  data). A boss earns Heat Resistance from burns exactly as the player does.
- **Data first.** Skills, creatures, items, recipes, dialogue, cards, regions
  and every tuning number are data. Scripts read them; they do not restate them.
- **The Voice is the interface.** System messages go through `Voice`; text
  lives in `voice_lines.json`.

## 4. Data schemas

All tables share: `_meta` (source and notes), records with `id` and `label`.

| Table | A record holds |
|---|---|
| `ranks.json` | `ep_min`, `ep_max` (half-open band), `danger_class`, guild meaning; plus danger classes, informal labels, thresholds |
| `races.json` | `evolution_line` (stages with optional `trigger`, `variants`, `life_form`), `traits`, `intrinsic_skills`, `base_rank`, `base_ep`, `vitals`, `moveset`, `sightless`, `spin_weight`, `spawn_regions` |
| `skills.json` | `category`, `sub_functions` (id, name, canon effect, game mapping), `active` (an attack), `passive` (always-on effects), `practice` (stat, needed, precursor attack, required flag), `summary` |
| `fusions.json` | `kind` (fusion or evolution), `inputs`, `result`, conditions (`event`, `sacrifices`, `absorbs`, `requires`, `gate`) |
| `resistances.json` | `grade` (resistance or nullification), `mitigates`; plus `merges` (inputs to result) |
| `damage_types.json` | `imprint_resistance`; plus `statuses` (damage type, tick interval, speed factor, blocks attacks) |
| `creatures.json` | `rank`, `ep`, `family`, `traits`, `model`, `body`, `stats`, `resistances`, `weak_to`, `attacks` (with `use_range`), `devour` (EP share, analysis time, skills tagged C / U / D) |
| `items.json`, `recipes.json` | item `kind`, `ep`, `analysis_time`, effects; recipe `inputs`, `output`, `learned_from` |
| `regions.json` | `magicule_density`, `spawn` rules; plus density levels |
| `dialogues.json` | `speaker`, `mode` (thought or speech), `nodes` with `text`, `next` / `options` / `end`, `effects`, `remember`; options may need a memory, a skill or a flag |
| `wish_cards.json` | `thought`, `reason`, `when` (stat and threshold, cause, or always), `result` (skill, resistance, reel weight, nothing), `prologue` |
| `voice_lines.json` | key to line text with `{placeholders}` |
| `tuning.json` | global numbers by section |

An attack (creature attack, race moveset, skill active or practice precursor)
is one schema: `kind` (melee, lunge, projectile, cone), `damage`,
`damage_type`, `range`, `arc`, `windup`, `recover`, `cooldown`, `stagger`,
optional `status`, `lifesteal`, `knockback`, `cost`.

## 5. What memory changes in a second life

| The soul keeps | Effect in the next life |
|---|---|
| Codex of analysed species and materials | Re-analysis takes half a second instead of up to minutes; the skill still needs the new body to devour the thing again |
| Codex | Known species show their EP on nameplates without a scan |
| How a practised skill was learned | 15% of the practice: Water Blade in 2 spits, Mana Perception in 0.6 s |
| The analysis link | Great Sage remakes it at birth |
| Meeting Veldora | An extra line that skips the introduction |
| What each last-thought card leads to | Results are shown instead of "?" |
| The imprint of the last death | The matching Resistance at birth |
| The chosen last thoughts | Skills, resistances or reel weight at birth |

`tests/test_full_loop` plays two lives to the same point (sight, potion, Water
Blade, a bat's skills). The second takes about 60% of the game time of the
first, with sight in 0.6 s instead of 4 s.

## 6. Manual test checklist

Play a fresh soul (delete `user://soul.json` or press 5, then restart).

**Prologue and birth**
1. The screen is dark; six thoughts turn gold one by one and the Voice says what comes of each, the last being nothing. Enter begins the life.
2. The Voice announces a slime in the Sealed Cave with Absorb, Dissolve, Self-Regeneration, Predator, Great Sage and Pain Nullification.
3. The world is black beyond a small circle around the slime. A gold arc labelled "a voice" points the way; the advisor says to follow it.

**Veldora and sight**
4. Following the arc leads north out of the birth chamber, west across the hall and into a large chamber.
5. "[E] Answer the voice" appears. The conversation offers choices; W/S or number keys pick, E confirms.
6. After the lesson, standing still and holding R fills a percentage; at 100% the Voice announces Mana Perception and the darkness opens outward.
7. Speaking again leads to friendship and a name panel. After confirming, the nameplate shows the name, the Voice registers it, and EP rises.
8. Asking how to get him out, then agreeing, opens a Yes/No prompt. Yes: the dragon and his dome shrink into the slime. The status sheet lists him in the Stomach.

**Predator and Great Sage**
9. Hold F on a hipokute herb: a bar fills, the herb vanishes, and "Analysis" appears at the top right with a time near 50 s.
10. Great Sage offers the link. Y: the time drops to about 1 s, and the healing potion recipe is announced.
11. Take damage, press H: health rises and the potion count drops.
12. R on a creature shows a card with rank, EP, weaknesses and what devouring yields; its nameplate then shows EP.

**Water**
13. Walk into the lake at its shallow western edge. Hold F: stored water rises in fives.
14. In deep water the slime sinks; Space on the bed pushes off. After about 12 s of moving, Water Current Motion is announced, and Space and Ctrl now swim up and down.
15. In deep water with stored water, press Space five times: Hydraulic Propulsion is announced, and Space becomes a jet.
16. On land, right-click eight times with stored water: Water Blade is announced and is bound to the skill button. If another skill is already bound, press Q until the HUD shows "Water Spit (practice)" first.

**Traversal**
17. In the birth chamber's east wall is a low slot. Walking into it fails; holding Ctrl crawls through to the herb grotto.
18. On the lake's north side, hold Shift and W against the wall: the slime climbs to the bat roost while the stamina bar drains.

**Combat and Mimicry**
19. Water Blade kills a giant bat in a few hits. Hold F on the remains: EP rises at once; after analysis the bat's skills and form are announced.
20. Z takes the bat form: the body changes, magicules drain, Space held in the air glides. Z again returns to the slime.
21. Tackling a creature repeatedly shows "Staggered" over it; the devour prompt then shows a much higher percentage.
22. A creature far above the slime's EP triggers an advisor warning. The tempest serpent in the northern lair kills a weak slime quickly.

**Death and the second life**
23. On death, time slows and colour drains; the Voice names the cause and the Resistance it leaves.
24. Six to eight cards appear. Cards seen in the prologue show their results; new ones show "?". At most three can be chosen. Enter confirms (Space does not, and nothing confirms in the first moment); with no card chosen, Enter asks once and a second press lets go of everything. Quitting on this screen loses nothing: the soul is written only when the choice is made.
25. The next life begins sightless again, with the chosen wishes and the imprinted Resistance announced, and no name, Stomach, forms or EP from before.
26. In this life: Veldora offers a third option; sight takes under a second; the herb analyses at once; Water Blade takes two spits; the analysis link is already made.

## 7. Automated tests

`tools/run_tests.sh` runs the data validator and ten headless scenes, 410
checks in all:

| Scene | Covers |
|---|---|
| `test_foundation` | data loading, rank bands, Voice, movement, EP and rank, plain death and rebirth, save file |
| `test_combat` | vitals, resistance growth and merges, statuses, creature behaviour, stagger, projectiles, death by a monster |
| `test_predator` | absorb versus Predator, Stomach, analysis timing, potions, living prey, Isolation, swallowed shots, remembered analysis |
| `test_advisor` | Sage versus Great Sage, scan, hints, the link prompt, status sheet |
| `test_level` | per-life seeding, squeeze, cling, sinking and swimming, drinking, skills by practice and their memory |
| `test_mimicry` | forms, upkeep, form moves, gliding, losing a form |
| `test_veldora` | sightless start, the voice path, the full Veldora flow, the second-life shortcut |
| `test_death` | prologue, slow motion, card offer and limits, grants at birth, hidden results |
| `test_full_loop` | two whole lives with real settings, and that the second is faster |
| `test_visual` | the visual pipeline from Pass 0 of the visual overhaul: config, asset manifest, world look, the F4 editor |

These were run on Godot 4.5.1 with the headless renderer. Screenshots for
layout checks were rendered with the Compatibility renderer on software GL.
Since Pass 1 of the visual overhaul that is also the project's renderer, so
what those screenshots show is what the game shows.

## 8. Canon notes

Places where what I recall differs from or goes beyond the document. I
followed the document in each case.

- **Mimicry.** Section 8.4 lists Mimicry as a fusion input; section 9.1 makes
  it a function of Predator. I modelled it as Predator's sub-function, and
  fusion inputs may name sub-functions.
- **Cave monster ranks.** The document marks the bat, centipede and
  armorsaurus as "not sourced". I recall guides placing the centipede and
  armorsaurus around rank B. I set bat D, centipede D, armorsaurus C so the
  cave runs E to B with the serpent above, as section 13 asks. One field each
  in `creatures.json`.
- **Who names whom.** As I recall it, the slime offers the shared family name
  and the dragon gives the personal name. The name panel is worded that way.
- **Veldora and Velgrynd skills.** Section 8.4 does not name them; they are
  placeholders in `skills.json`.
- **Skill tiers.** Where the document names a skill without a tier, the tier
  in `skills.json` is my best guess and is marked `category_label:
  UNCONFIRMED`. Capacity cost follows the tier, so these matter slightly.
- **Wording.** No line is taken from the books. The Voice of the World and the
  advisor deliberately avoid the series' catchphrases.

## 9. Known gaps and risks

- Balance has not been played by a person. Every number is in `data/`.
- No sound. The design's two voices are text only for now.
- Card choice needs the mouse or number keys; gamepad navigation of menus is
  not done.
- Placeholder bodies are primitives; the serpent and spider are dark against a
  dark cave.
- Creatures have no pathfinding and can be led to walls and left there.
- The lake's deep water can only be left by bouncing off the bed, swimming, or
  clinging; a player who never moves in water never learns to swim.

## 10. Proposed next step

Milestone 1 (section 21): the three-reel spin, goblin and human, Arts with
practice, memory and re-attunement, and the two save layers. The pieces it
builds on are in place: `spin.json`, race data, the practice system, `Soul`,
and reel weights already stored by wish cards.
