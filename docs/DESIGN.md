# Reincarnate, devour, evolve: your Tensura game prompt

This is a single, copy-paste-ready design prompt for a 3D open-world reincarnation roguelike set in the world of "That Time I Got Reincarnated as a Slime", with the power system, map and progression taken from the light novel and your own design decisions (race spin, memory carry-over, dying wishes, Ramiris's Dungeon) layered on top and labelled as such. To use it, copy everything inside the block below into your AI game-building assistant, change the one line marked `ENGINE / TECH STACK`, and let it start with Milestone 0 (Sealed Cave, slime, Predator loop). It is a fan project based on a series owned by its creators and publishers, so it suits personal, non-commercial use unless you obtain a licence.

````markdown
# Game design prompt: a 3D open-world reincarnation roguelike in the world of "That Time I Got Reincarnated as a Slime"

## 1. Your role and how to work with me

You are my lead game designer and programmer. Build the game described below with me, one milestone at a time.

ENGINE / TECH STACK: [FILL IN - for example Unity (C#), Unreal Engine 5, Godot 4, or Three.js/WebGL]   <-- the only line I edit

Working rules:
- This document is engine-agnostic. Translate every system into the idioms of the engine named above.
- Three labels are used throughout:
  - [CANON] = a fact or rule of the light novel's world. Keep it intact.
  - [DESIGN] = a game adaptation I have chosen. You may suggest a better implementation, but keep the intent.
  - [UNCONFIRMED] = commonly repeated but not verified against the novels. Use it as a tunable default; never let it override a [CANON] line.
- The light novel is the standard of truth. If you recall an anime, manga or web-novel detail that conflicts with this document, follow this document and tell me about the conflict.
- Every number not tagged [CANON] is a starting value for tuning.
- Keep content data-driven: skills, fusions, races, monsters, bosses, regions and dungeon floors live in data files, so lore can be corrected without touching code.
- Make original models, art, music, interface and text. Do not reproduce the series' official artwork, logos, music, voice lines or passages from the books. This is a personal, non-commercial fan project.
- Follow the build order in section 21 and start with Milestone 0 only. For each milestone give me a short plan, the folder layout, the code, and a test checklist.
- Where something is underspecified, choose the simplest option that respects [CANON], state the assumption in one line, and carry on.

## 2. Concept and pillars

A third-person 3D action RPG on one seamless map of the Tensura world, explored freely in the manner of The Legend of Zelda: Breath of the Wild. The player is a soul that keeps reincarnating. Each life is one run: you are reborn as a randomly rolled race, grow by the world's real rules (devour and analyse as a slime, name followers, evolve, awaken as Demon Lord or Hero), and when you die you are born again. What you learned survives. What your body was does not.

Pillars:
1. Power is earned the way the novel earns it: eat, analyse, fuse, name, evolve, awaken.
2. The Voice of the World is the interface.
3. Knowledge outlives the body.
4. Go anywhere; danger is readable through the world's own rank system.

## 3. Roguelike structure: life, death, reincarnation

[CANON] Grounding:
- When a being dies and its innermost (astral) body dissolves, the soul passes on to reincarnation.
- People from another world arrive by summoning, by accident or by reincarnation, and the crossing gives them a raised chance of a Unique skill.
- Rimuru's starting body and skills were built by the Voice of the World from the thoughts he had while dying.
- True Dragons are reborn with their memories if destroyed.

[DESIGN] The run loop:
1. Birth: reincarnation spin (section 4), then spawn in the rolled race's home region with a starting kit shaped by the previous life's death (section 5).
2. Life: free roaming. Grow existence points, skills and followers; follow the story arc or ignore it.
3. Death: the Voice of the World death sequence (section 5).
4. Rebirth: a new life in a fresh branch of the timeline.

[DESIGN] What persists and what resets:

| Carries over (memory, held by the soul) | Resets (body and world) |
|---|---|
| Arts already performed, with mastery level | Race, evolution stage, body and mimic forms |
| Spell knowledge and magic theory ranks | Intrinsic (race) skills |
| Weapon mastery per weapon class | Magicule capacity and existence points |
| Analysis records: codex of species, materials, recipes | Common, Extra, Unique and Ultimate skills; resistances (except those granted at birth by section 5) |
| Map knowledge, lore, extra dialogue options from past lives | Followers, names given, soul corridors, settlement, inventory |
| Dungeon records (deepest floor, floor notes) | Faction standing and story progress |

Carry-over rules:
- [CANON] Arts are learned only through practice; no copying or absorbing skill can acquire them. [DESIGN] So Arts are the main permanent progression: never obtainable by Predation, Mimicry or gifts, only by doing them, and once learned they belong to the soul.
- [CANON] When someone first performs an Art successfully, the Voice of the World registers a matching Extra skill that makes it easier to use. [DESIGN] In a new life a remembered Art starts unregistered: perform it once in the new body (a short re-attunement challenge) and it is registered again at its remembered mastery.
- [DESIGN] Remembered spells still need a body that can pay for them: enough magicules, and the right source (a spirit contract for spirit magic, a faith pact for holy magic). Knowledge is not power until the body can use it.
- [DESIGN] Remembered analysis makes re-analysis of a known species or material near-instant, but the skill is only granted again after the new body devours that target.
- [DESIGN] The world does not remember you. Geography, nations and major characters are fixed; monster spawns, loot, optional events, event timing and dungeon layouts are reseeded each life.
- [DESIGN] Rimuru Tempest does not exist as a character. The player stands where the story placed him, so canon events happen to or around the player and adapt to the rolled race.
- [DESIGN] No permanent stat upgrades exist apart from memory.

## 4. Reincarnation spin

[DESIGN] A three-reel roulette presented by the Voice of the World at each birth:
- Reel 1, race (table below).
- Reel 2, origin: native-born, reincarnated otherworlder, or (humans only) summoned otherworlder. [CANON] Falmuth summons otherworlders and binds them as living weapons, so a summoned start in Falmuth is a hard start.
- Reel 3, affinity: one element (fire, water, wind, earth, light, dark) that eases the matching spirit contract and magic.
- The first life is always a slime in the Sealed Cave (tutorial). Later, dying wishes add weight to reels (section 5). One reel may be re-spun per birth.

| Race | Evolution line [CANON] | Traits [CANON] | Spawn and playstyle [DESIGN] |
|---|---|---|---|
| Slime (signature, highest weight) | Slime -> Demon Slime (on True Demon Lord awakening) -> Ultimate Slime (True Dragon class) | Demi-spiritual life-form that thinks with its spiritual body; intrinsic skills Absorb, Dissolve, Self-Regeneration; no sight until it learns Mana Perception | Sealed Cave. Devour, analyse, mimic (section 9) |
| Goblin | Goblin -> Hobgoblin (male) / Goblina (female) | Rank E; weak alone, dangerous in groups; evolves when named | Jura goblin village. Tribe leader, relies on Arts and allies |
| Direwolf | Direwolf -> Tempest wolf -> Star wolf / Tempest star wolf -> Soul wolf -> Divine wolf | Magic beast; pack hunter | Jura Forest. Fast quadruped, pack commands |
| Ogre | Ogre -> Kijin -> Oni -> Soul oni -> Divine oni (Death oni and Wicked oni exist as variants) | Rank B; an oni is a spiritual life-form with power comparable to a Demon Lord | Ogre village on Jura's western route. Weapon Arts specialist |
| Orc | Orc -> High orc -> Orc Lord -> Orc Disaster (Soul boar and Divine boar are listed above these) | Rank D; an Orc Lord is a rare mutant | Orc host on the march (homeland not fixed by sources). Endurance bruiser |
| Lizardman | Lizardman -> Dragonewt | Rank C | Lake Siss marsh caves. Spear fighter, strong swimmer |
| Lesser daemon | Lesser daemon -> Greater daemon -> Archdaemon -> Daemon lord -> Devil lord | Spiritual life-form; needs a physical vessel to stay in this world; can be manipulated through its true name; an archdaemon is comparable to a Demon Lord seed | Summoned into a vessel by a random summoner. Dark-magic caster |
| Human (otherworlder) | Human -> Enlightened (demi-spiritual) -> Saint (spiritual); separate Hero's Egg route | No intrinsic skills; low magicule capacity and tolerance; strongest at aura-based Arts; raised chance of a Unique skill | Blumund, Englassia or Falmuth. Arts, gear, spirit and holy magic, Free Guild work |

Notes:
- [CANON] Base ranks E (goblin), D (orc), C (lizardman) and B (ogre) are from the novel's guild scale. Other base ranks are [DESIGN].
- [UNCONFIRMED] The exact trigger for each evolution step (for example lizardman to dragonewt, kijin to oni). Default: naming for the first step, magicule thresholds or awakening gifts for later ones.
- [DESIGN] Any non-slime monster may seek a stronger being to name it: instant evolution, but you become that being's subordinate, and [CANON] a recognised subordinate cannot hold a Demon Lord seed.
- [DESIGN] Dwarves, elves, lycanthropes, harpies, vampires and insectoids exist in canon and can be added later as extra reel entries.

## 5. Death sequence and dying wishes

[CANON] Basis: as Rimuru's former self lay dying, the Voice of the World read his stray thoughts as wishes. Wanting a body without blood produced the slime body; a thought about devouring produced the Unique skill Predator; a rueful joke about being a sage produced the Extra skill Sage, upgraded at once to the Unique skill Great Sage; a set of resistances including Pain Nullification was granted in the same process; and his final request produced nothing at all. Separately, Unique skills in general are born from their owner's emotions and desires, and only about one in ten has an obvious combat use.

[DESIGN] The death sequence:
1. Time slows and colour drains. The Voice of the World begins to speak.
2. Imprint of the cause (automatic): the damage type that killed you grants the matching Resistance at next birth (blade -> Pierce Resistance, fire -> Heat Resistance, cold, electricity, poison, paralysis, corrosion, spiritual). Resistance only; Nullification has to be earned in life.
3. Last thoughts (player choice): pick up to three from six to eight cards generated from this life (what you did most, what you lacked, how you died). Each card becomes one of: a Unique skill for the next life, an Extra skill, extra weight on a spin reel, or nothing.
4. Rebirth and spin.

Example cards (all [DESIGN]; invent more in this spirit):

| Last thought (paraphrased) | Generated when | Result next life |
|---|---|---|
| Wanting to take in everything | Many devours or kills | Unique skill Predator (always offered in the first life) |
| Wishing you had understood | Much scanning and analysis | Extra skill Sage; a second wisdom card upgrades it to Great Sage |
| Wanting the pain to stop | Long fight at low health | Pain Nullification |
| Wanting a body that cannot bleed | Death by blood loss | Heavy weight on Slime |
| Wanting to protect someone | Followers died this life | A defensive Unique skill of your design |
| An idle worldly worry | Always present | Nothing (a nod to canon) |

The Unique skill pool should be mostly utility, in line with the one-in-ten rule.

## 6. The Voice of the World: announcer and interface

[CANON]
- An impersonal phenomenon of the world. It announces skill acquisition, race evolution, receipt of a Demon Lord seed or Hero's egg, the awakening of a Demon Lord or Hero, and the activation of some skills.
- It can address one individual or everyone within range of an event, and every listener understands it.
- Some skills use it to put Yes/No confirmations to their owner.
- It announces the Harvest Festival immediately before it starts; the process then begins and cannot be refused.

[DESIGN]
- Every system message is the Voice of the World: flat, neutral, brief, in wording you write yourself.
- Yes/No prompts for evolutions, fusions and devouring something risky.
- World broadcasts (visible on screen and heard by nearby characters) when the player or a boss awakens.
- The slime's advisor skill (Sage line) is a second, distinct voice: tutorial guide, scan readouts, tactical hints, optional auto-battle.

## 7. Magicules, existence points and rank

[CANON] Magicules:
- Spiritual particles that respond to thought. Monsters are made of them and live on them; most monsters need no food, sleep or air.
- They behave like radiation: air, materials and creatures are contaminated to different degrees by region. There is a safe limit; untrained humans tolerate little, demi-humans more.
- Dense magicules condense into monsters whose strength depends on the density, and long exposure to higher density can cause evolution. Ordinary matter soaked in them becomes magic ore, magisteel and similar materials.
- Mindless monsters hunt magicule-rich prey in order to evolve. Intelligent monsters are called majin.

[CANON] Existence points (EP): the amount of energy (magicules, aura, holy power) held in a body and soul, objects included. The numeric scale was devised in Tempest using the analysis ability of Ramiris's labyrinth.

| Rank | EP band [CANON] | Danger class [CANON] | Guild meaning [CANON] |
|---|---|---|---|
| F | - | - | No real combat ability |
| E | under 1,000 | - | Average adult human |
| D | 1,000-3,000 | - | Soldier; three or four ordinary people can win |
| C | 3,000-6,000 | - | Seasoned professional soldier |
| B | 6,000-8,000 | - | Can wipe out a village alone |
| B+ / A- | 8,000-9,000 / 9,000-10,000 | - | Intermediate steps |
| A | 10,000-100,000 | Hazard | Can wreck a town; needs a nation's knights |
| Special A | 100,000-400,000 | Calamity | Can topple a small nation |
| S | 400,000-800,000 | Disaster | Demon Lord level; needs a great power's whole military |
| Special S | above 800,000 | Catastrophe | Beyond any single nation |
| Million class | above 1,000,000 | - | Informal label for super-awakened beings |

[CANON] Catastrophe is officially reserved for True Dragons and is judged by power near theirs, not by an EP figure. Danger classes also reflect influence and politics. A Demon Lord seed needs at least 200,000 EP.

[DESIGN] Game use:
- EP is the level number. It rises through absorbed magicules, evolution, awakening and follower growth (Food Chain, section 10).
- EP measures quantity, not quality: skill tier, Arts, technique and will decide fights between similar EP.
- [CANON] Gaining a skill spends magicules and permanently lowers the owner's capacity. [DESIGN] Each skill reserves part of maximum capacity, so builds are a trade-off; humans hold few skills.
- Nameplates show letter rank and danger class. Numeric EP appears once the player has an appraisal skill or builds the capital's analysis facility.
- Each region has a magicule density level that sets spawn strength, resource richness (magic ore, hipokute herb) and a hazard for low-tolerance races, working like temperature zones in Breath of the Wild.

## 8. Skill system

### 8.1 Tiers and categories [CANON]

| Category | What it is | How it is obtained |
|---|---|---|
| Common skill | Baseline tier | Practice and effort |
| Extra skill | One step up; the ceiling for effort. Power ranges from barely above Common to rivalling Unique | Effort, mastering an Art, species inheritance, evolution of a Common skill |
| Unique skill | One of a kind, born from the owner's mind and desires; anchored in body or soul; cannot be copied | Intense emotion, trials, crossing worlds; evolution of an Extra skill |
| Ultimate skill | Final stage; control over natural law | A Unique skill pushed past its limit, or fusion of skills (8.4) |
| Intrinsic skill | Innate to a species; scales with race evolution | Race and evolution |
| Resistance / Nullification | Not strictly skills; mitigate or cancel a damage type | Exposure, evolution, merging |
| Art | A practised technique, mostly developed by humans | Practice only |
| Ultimate Gift | A weaker Ultimate handed down through a soul corridor | Granted by a superior |
| Manas | An Ultimate skill that gained an ego and a name | Naming the skill |

From Extra tier up, a skill is a bundle: a core concept plus passive effects plus active abilities. Model every Unique and Ultimate skill as a package of named sub-functions.

### 8.2 Acquisition, growth and loss
- [CANON] A skill forms when power and desire align and the world recognises it. Skills evolve with the owner's evolution and through proficiency, can be fused if the owner understands them deeply, can be sacrificed into another skill to push its evolution, and redundant ones can be discarded.
- [CANON] A user who treats a Unique skill as a mere tool never draws out its full potential. [DESIGN] Unique skills have a resonance meter that fills when used in ways that match the desire that created them.

### 8.3 Counter rules
- [CANON] Unique skills give resistance to lower-tier effects; soul-anchored ones protect best against mental interference.
- [CANON] An Ultimate skill is countered only by another Ultimate skill or a short list of equivalents such as ultimate-level magic, god-grade equipment or divinity. When Ultimates clash, willpower decides.
- [DESIGN] Ultimate is a hard gate: sub-Ultimate defences do not stop Ultimate effects. Ultimate against Ultimate resolves on a Will stat (built from resonance, story choices and remembered lives), not on EP.

### 8.4 Fusion and evolution chains [CANON] (use as the upgrade tree)

| Inputs | Result | Further evolution |
|---|---|---|
| Absorb + Dissolve + Self-Regeneration + Mimicry | Ultraspeed Regeneration | Infinite Regeneration |
| Sticky Thread + Steel Thread | Sticky-Steel Thread | Universal Thread |
| Water Current Motion + Hydraulic Propulsion + Water Blade | Water Manipulation | with Flame Manipulation -> Molecular Manipulation; with Mana Jamming -> Mana Manipulation |
| Flame Transformation; Black Lightning | Black Flame; Black Thunder | combined -> Black Flame-Thunder |
| Mana Perception + Heat Source Perception + Sound Wave Perception | Universal Perception | - |
| Coercion | Haki | with Magic Aura -> Demon Lord's Haki (needs seed-level rank) |
| Telepathy; Ranged Barrier; Body Double; Shadow Motion | Thought Communication; Multilayer Barrier; Enhanced Body Double; Spatial Motion | - |
| Sage | Great Sage (Unique) | Raphael (Ultimate; at the Harvest Festival, sacrificing Degenerate) -> Ciel (Manas; by naming the skill) |
| Predator + Starved | Gluttony (Unique) | Beelzebuth (Ultimate; at the Harvest Festival, absorbing Merciless) |
| Infinity Prison + skills gathered through Food Chain | Uriel (Ultimate) | - |
| Raphael + Beelzebuth, with the Veldora and Velgrynd skills folded in | Azathoth | - |

[DESIGN] Fusions trigger automatically when inputs are owned and the advisor skill is strong enough, or manually at a fusion screen. Ultimate-tier steps only fire at awakening events (section 11).

### 8.5 Resistances [CANON]
- Two grades: Resistance (partial), then Nullification.
- Merge tree: Cold + Heat -> Thermal Fluctuation Resistance -> Thermal Fluctuation Nullification -> (with Electricity Resistance) Natural Effects Nullification. Pierce -> Physical Attack Resistance -> Physical Attack Nullification. Paralysis + Corrosion -> Abnormal Condition Nullification. Magic Resistance -> Holy-Demonic Attack Resistance. Spiritual Attack Resistance -> Spiritual Attack Nullification. Pain Nullification stands alone.
- [DESIGN] Surviving enough of a damage type earns its Resistance, for players and for bosses. [CANON] The Orc Disaster picked up Heat Resistance in the middle of a fight after being burned.

### 8.6 Ultimate skills [CANON]
- Requirements: a Unique skill pushed beyond its limit, a strong will and soul, being a spiritual life-form, and a large energy payment. No numeric EP threshold is given.
- Named after mythological figures. Two naming families: a Sin (demonic) series and a Virtue (angelic) series; rarer god-tier skills come from pushing an Ultimate to its limit or merging across the families.
- A self-awakened Ultimate cannot be stolen while its owner lives.
- True Dragons need none: their inborn powers already count as Ultimate.
- [UNCONFIRMED] Examples by holder, usable as boss kits: Satan/wrath (Milim), Lucifer/pride (Guy), Belphegor/sloth (Dino), Asmodeus/lust (Luminous), Mammon/greed (Yuuki), Leviathan/envy and Gabriel/patience (Velzard), Metatron/purity (Leon), Michael/justice (Rudra), Cthugha (Velgrynd), Mephisto (Zegion).
- [UNCONFIRMED] Holders of Virtue-series skills can be dominated by the skill Michael. Use as a late-game risk for a player who holds one, and as the reason for naming the advisor skill.

### 8.7 Arts [CANON]
- Battlewill: turn aura into fighting spirit to reinforce the body.
- Modelwill: shape fighting spirit into projectiles or enclosing bubbles.
- Formhide: conceal presence, potentially beating Mana Perception.
- Ogre Cannon: a large electrical burst.
- Airflight: flight using magicules.
- Magic Aura (hybrid): coat a weapon in Modelwill plus magicules; the magic half hurts spiritual beings, the aura half bypasses a daemon's magic resistance.
- [DESIGN] Add sword, spear, bow and unarmed Art trees learned from teachers and by repetition. Weapon Arts need a body with hands (a humanoid race or a humanoid mimic form).

## 9. Slime core loop: Predator and Great Sage

### 9.1 Predator's five functions [CANON]

| Function | Canon effect | Game mapping [DESIGN] |
|---|---|---|
| Predation | Draws a target into the body; works on living things, objects, skills and magic; far less likely to work on a conscious target | Hold-to-devour. Certain on dead, downed or inanimate targets; on conscious ones the chance scales with your EP against theirs and their stagger. Can swallow projectiles and spells with timing |
| Analysis | Studies what was swallowed; unlocks recipes and copies; a fully analysed skill or spell becomes usable | Timed unlock per item; grants skills, recipes and codex entries |
| Stomach | Storage with no time limit | Inventory; later holds sealed beings and souls |
| Mimicry | Reproduces the look and abilities of an analysed target; forms improve when one's own followers evolve | Form wheel: each analysed species is a playable form with its moveset. Forms cost magicules to hold, less as you grow |
| Isolation | Quarantines harmful or unanalysable material and converts it to energy | Turns poison, curses and junk into magicules; the answer to hazards |

More [CANON] rules: eating only part of a body can still give a skill, but less reliably. Predator can take skills from living prey. Some beings are swallowed by agreement rather than by force (Veldora, together with his seal; Shizu, at her own request as she died).

### 9.2 Great Sage's functions [CANON]

| Function | Canon effect | Game mapping [DESIGN] |
|---|---|---|
| Thought Acceleration | Thinking speed multiplied a thousandfold | Focus/bullet-time meter |
| Analytical Appraisal | Analyse and appraise a target | Scan: rank, weaknesses, devour drops |
| Parallel Processing | Separate, accelerated thought threads | Extra background analysis slots |
| Chant Annulment | Spells need no incantation | Instant casting of known spells |
| All of Creation | Understand any non-hidden phenomenon once seen | Codex fills from observation; can learn observed spells |
| Auto Battle Mode | With permission, the skill pilots the body | Optional autopilot for a limited time |

- [CANON] Linking Predator's Analysis to Parallel Processing cut herb analysis from roughly fifty minutes to about a second. [DESIGN] This link is the first upgrade the tutorial teaches.
- [CANON] As Gluttony, Predation reaches further, Stomach doubles, Analysis moves into the advisor skill, and Corrosion, Receive and Provide are added. As Beelzebuth, Predation works at huge range and can consume space and souls, and Food Chain appears (section 10).
- [CANON] As Raphael the advisor thinks a thousand times faster again, gains Synthesis/Separation, skill Alteration and Future Attack Prediction, and acts on its own initiative, reporting afterwards.

### 9.3 Slime-specific rules
- [CANON] The newborn slime cannot see; sight comes from the Extra skill Mana Perception, taught by Veldora. It learns to move through water with Water Current Motion and Hydraulic Propulsion, develops Water Blade through its own practice, and builds a speaking voice from a bat's sound skill.
- [DESIGN] So the first minutes are played by touch and sound until Mana Perception unlocks full vision, and spoken dialogue with most characters is locked until a sound skill is analysed (thought-speech works with Veldora).
- [CANON] The human form comes from absorbing Shizu; it starts child-sized and grows after victories over strong enemies. The Demon Slime body is silver with gold streaks.

## 10. Naming, followers and settlement

[CANON] Naming rules:
- A strong being names an unnamed monster. The target becomes a Named monster, gains strength, learns skills more easily and may evolve at once.
- The stronger the namer, the bigger the jump. The stronger the target, the more magicules it takes.
- The magicules spent normally never return: the namer's capacity is cut permanently, and overspending can kill. This is why naming is rare and why the named revere their namer.
- Any energy source the namer can tap may pay instead. Rimuru drew on Veldora, sealed inside him, and later on stored souls. He still collapsed into a dormant sleep after naming six ogres, far fewer than the goblins and wolves he had named before, because stronger targets cost more.
- Monsters named by Rimuru shifted toward human-like forms.
- A Named monster loses that status when its master dies.
- Sharing a family name makes two beings equals rather than master and servant; equals can exchange energy and use each other's abilities.
- Naming ties the two at the level of the soul. Through that corridor a master's awakening sends gifts to followers.
- [CANON] Receive and Provide (Gluttony), later Food Chain (Beelzebuth): the master obtains copies of followers' skills, can grant compatible skills, and gains magicules when followers grow substantially. Spells and knowledge do not transfer.

[DESIGN] Game rules:
- Naming cost = a share of the target's EP, taken from maximum capacity unless paid from a battery (a sealed ally in Stomach, banked souls).
- Cost above current magicules: sleep mode (the body is helpless, time skips, events advance). Cost above maximum capacity: death.
- Each named follower gets a soul-corridor entry: shared buffs, gifted skills, a trickle of EP back to you after Gluttony, and a new mimic form when they evolve.
- Followers staff the settlement: builders, smiths, scouts, mounts, officers who fight beside you.

Settlement:
- [CANON] Minimum early population: about 500 goblins (hobgoblins once named), 100+ direwolves (Tempest wolves), six ogres, 2,000+ high orcs as builders, 100+ dragonewts, a handful of dwarven craftsmen.
- [CANON] Growth: bare plot -> larger planned town near the Sealed Cave with water and farmland -> expansion when the high orcs join -> shops, farms, plumbing, roads, a capital building -> highways to Dwargon and Blumund -> a nation with a Dungeon, an arena and festivals. The light novel calls the capital Rimuru City; here it takes the name the player chooses.
- [DESIGN] Settlement tiers unlock crafting, potion production (hipokute herb farm in the Sealed Cave), gear, fast travel by highway, and the Dungeon.

## 11. Evolution and the two awakening routes

[CANON] General: monsters evolve on reaching a magicule threshold; some evolutions need special conditions. Naming, living in denser magicules, and gifts from a master's awakening can all trigger it.

| Stage | Demon Lord route [CANON] | Hero route [CANON] |
|---|---|---|
| Eligibility | Demon Lord seed: Special A in raw magicules, at least 200,000 EP, and no master. Rimuru gained his by consuming the Orc Disaster | Hero's egg: the blessing of a light or dark elemental, with the Elemental Queen judging the person worthy; the elemental lives inside the bearer |
| Trigger | Feed the seed the equivalent of 10,000 human souls | Prove oneself; the egg hatches and merges with the elemental |
| Event | Harvest Festival: announced, starts at once, cannot be refused. Rimuru slept through it while his advisor skill ran his body | Awakening as a True Hero |
| Results | Race evolution, a large magicule gain, easier skill gain and evolution during the process, a risk of personality change; every soul-linked follower receives gifts (skills, evolutions) | Power equal to a True Demon Lord; often divinity, which raises the odds of an Ultimate skill; gear that grows toward god-grade |
| Catch | The souls must come from somewhere | The status is lost if the elemental leaves; being proclaimed a Hero sets up a fated tie to a Demon Lord |

- [CANON] Rimuru met the quota with the souls of the invading Falmuth army, about 20,000 in total, and the process also brought back citizens who had been killed.
- [CANON] Humans and demi-humans can instead rise to Enlightened and then Saint. Ultimate skills require being a spiritual life-form.
- [CANON] A lord can awaken a qualified follower to the same level for 100,000 soul-equivalents each; souls of Enlightened and Saints count for more.
- [CANON] Rimuru's final race step, Ultimate Slime, came from absorbing the True Dragons Veldora and Velgrynd during the war with the Eastern Empire.

[DESIGN]
- Demon Lord route = resource trigger. Human souls come only from hostile armies and invaders, never from farming civilians, and the choice changes how nations treat you.
- Hero route = quest trigger: trials set by Ramiris, who in canon guides and blesses heroes. Open to humans and demi-humans; monster races take the Demon Lord route.
- The Harvest Festival is a playable set piece: the player sleeps, the advisor skill fights on autopilot, pending Ultimate fusions resolve, and a gift screen lists what each follower received.
- A third, endgame tier (True Dragon class) requires bonding with and then absorbing a True Dragon.

## 12. Magic, damage layers and anti-magic zones

[CANON] Magic is an image made real under a law, which is why it can affect spiritual beings. Chants and gestures only help focus the image.

| Type | Canon rule | Game note [DESIGN] |
|---|---|---|
| Aspectual magic | Uses the caster's own magicules to bend natural law; mana jamming or a Holy Field shuts it down | Main caster school; disabled in anti-magic zones |
| Elemental (spirit) magic | Borrows a contracted elemental's power; obeys physics, so it still works inside an anti-magic area; the user must be liked by elementals | Needs a contract; the safe choice against the Church |
| Holy magic | Faith-powered; purifies magicules; healing, curses, few attacks, strong against monsters and above all undead | Bonus damage to magicule-bodied enemies, including a monster player |
| Summoning | Calls daemons, elementals or monsters; needs spatial magic | Pets and daemon allies; daemons need a vessel |
| Illusion | Acts on the spiritual body, from deception to direct spiritual damage | Status effects and spirit damage |
| Engraving (runes) | Enchants people or objects; can power autonomous devices | Gear crafting and traps |
| Physics magic | Rimuru's invention; purely physical effects, so anti-magic defences do not stop it. Megiddo focuses sunlight through water droplets into beams | Late spell line that ignores magic barriers |
| Disintegration | Holy-energy spell, the strongest anti-personnel magic; long preparation, large energy, near light speed, reaches the soul; taught only by the Western Holy Church | Boss ultimate with a readable wind-up |

- [CANON] Triangle of spiritual beings: elementals beat daemons, daemons beat angels, angels beat elementals.
- [CANON] Layers of a being: soul, astral body, spiritual body, material body; monsters also have a core in the material body. Spiritual life-forms can rebuild a destroyed body from magicules.
- [DESIGN] Damage typing: physical damage destroys only the material layer; spiritual, holy and soul-reaching damage is needed to finish spiritual and demi-spiritual enemies; ordinary monsters die when the core breaks.
- [CANON] A Holy Field disables aspectual magic and weakens monsters inside it; in the Falmuth attack it was paired with a separate Anti-Magic Area that cut the town's magic and communications. [DESIGN] Treat it as an arena modifier (heavy debuff to monster players and followers, aspectual magic off) that ends when its anchor casters are defeated. Spirit magic, Arts and physics magic still work.

## 13. World map and regions

[CANON] Frame: three continents surrounded by ocean made impassable by sea monsters. Most of the story is on the central Magic Continent. [DESIGN] One seamless map of the Magic Continent; the Ice Continent and El Dorado are reached late by spatial travel; the sea is the map edge, patrolled by giant sea beasts.

| Region | Position | Canon description | Role and threat [DESIGN] |
|---|---|---|---|
| Sealed Cave | Jura, near the later capital | Cavern saturated by 300 years of the sealed Storm Dragon Veldora's aura; rich in magic ore and hipokute herb; home to serpents, centipedes, spiders, bats and armoured lizards; an underground lake | Tutorial and Milestone 0. E to B, serpent above B |
| Great Jura Forest | Centre of the continent | Vast buffer woodland that grew under Veldora's protection; split east and west by the Great Ameld River; reachable by three winding routes no army can use; goblin villages, a destroyed ogre village on the western route, a hidden treant grove guarded by dryads; merfolk and river monsters in the Ameld | First open zone. E to A |
| Lake Siss marshes | Middle of Jura | Lake on the Ameld more than 1,000 km across; limestone marsh; a maze of large caverns that serves as the lizardmen's fortress capital | Marsh biome, cave maze, Orc war battlefield. C to Special A |
| Player capital (Rimuru City in canon) | Near the Sealed Cave | Planned town that becomes a trade hub and capital | Main hub; Dungeon entrance |
| Armed Nation of Dwargon | Inside the Canaat Mountains, north | Cavern kingdom of dwarves under King Gazel Dwargo; strictly neutral, violence banned; trade and arms; huge gate opened only for the army or state guests, with a side door split into a noble lane and a common lane; Dragon Lords hold the peaks above | No-combat crafting hub; mountain climbing; dragons above |
| Kingdom of Blumund | Borders Falmuth and the player's nation | Small rural human kingdom; capital Londo of plain stone with one tall castle; Free Guild branch under Fuze | First human hub; guild quests |
| Kingdom of Falmuth | West of Dwargon | Gateway to the western nations; rich on tariffs and transit trade; summons otherworlders as weapons; Royal Knights, a sorcerer corps, noble knights and mercenaries | Hostile mid-game nation; source of the invasion |
| Kingdom of Englassia | West of Jura | Hub of the western nations; walled capital with two gates, a white castle on a central lake joined by four bridges, four ring districts; Council of the West, Free Guild headquarters, an academy for summoned children | Large city hub; guild rank-ups; school quests |
| Holy Empire of Lubelius | Western border | Seat of the Western Holy Church; capital Lune under a city-wide barrier that blocks monsters, elementals and demons; a sacred mountain sanctuary where Demon Lord Luminous secretly lives as the faith's god; an underground Night Garden | High-level holy zone; Church storyline |
| Sorcerous Dynasty of Sarion | Southern border of Jura | Elven superpower of thirteen kingdoms under Emperor Elmesia; capital built into a gigantic divine tree; advanced magic science | Vertical tree city; spirit-magic teachers |
| Eurazania and Milim's domain | South to south-east of Jura | Beastman kingdom of the Lion King Carrion; its capital is later destroyed by Milim and rebuilt as her new seat; Frey's harpy queendom Fulbrosia also joins her territory; Milim's old seat is the City of the Forgotten Dragon, run by her dragon-worshipping priests | Plains and beastfolk arenas; Beastketeer duels |
| Puppet Nation of Jistav | Far east | Clayman's realm of dark elves; capital Amrita is both a vault of ancient technology and a tomb, with a hidden undercity guarded by golems | Undead and golem zone; Clayman arc |
| Barren Lands | Far west | Magicule-contaminated desert made by a clash between Milim and Guy; giants under Dagruel; the Heaven Tower and ancient ruins | High-density hazard zone; endgame |
| Eastern Empire | Far east | Largest military state, about two thousand years old; capital beside a holy mountain said to house its guardian dragon | Late-game invasion source and counter-attack target |
| Ice Continent | North, over the sea | Permafrost caused by the True Dragon Velzard's aura; Guy Crimson's Frost Palace and a daemon army | Endgame |
| El Dorado | South-west, over the sea | Leon's volcanic, gold-rich continent | Endgame |
| Dwelling of the Spirits | Later housed in the player's capital | Ramiris's original labyrinth where spirits are contracted | Spirit-contract trial |

## 14. Traversal and exploration [DESIGN, built from canon abilities]
- Stamina-based climbing on any surface; slimes cling and squeeze through gaps.
- Glide: bat-wing mimic form ([CANON] Rimuru took flight from the giant bat's wings); later the Art Airflight and gravity control from Charybdis.
- Water: Water Current Motion and Hydraulic Propulsion for swimming and jet dashes.
- Swing and trap with Sticky Thread and Steel Thread.
- Mounts: named wolves. [CANON] The capital's army fields a Goblin Rider unit.
- Fast travel in layers: Shadow Motion between known followers, then Spatial Motion, plus the highways built from the capital to Dwargon and Blumund.
- Discovery: Mana Perception as the sensing pulse; Heat Source and Sound Wave Perception as vision modes; magicule density visible as a haze.
- No hunger for monster races ([CANON] they live on magicules); humans need food and rest.

## 15. Bestiary by region

Devour-gain legend: C = canon gain by Rimuru; U = [UNCONFIRMED] pairing; D = [DESIGN] drop. Enemies that canon recruits rather than eats give allies, not skills.

| Region | Enemy | Rank | Canon traits | Devour gain or reward |
|---|---|---|---|---|
| Sealed Cave | Tempest serpent | Above B (inferred); strongest cave monster | Jet-black giant snake, thorned scales, tough hide | C: Poison Breath. U: Heat Source Perception. Serpent form |
| Sealed Cave | Evil centipede | Not sourced | Giant centipede | C: Paralyzing Breath |
| Sealed Cave | Black spider | B | Village-destroyer tier, hard to flee from | C: Sticky Thread, Steel Thread |
| Sealed Cave | Giant bat | Not sourced | Drain, Ultra Sound Waves, wings that adjust its own gravity | C: Ultra Sound Waves (voice), flight; Drain (canon discarded it; let the player discard skills) |
| Sealed Cave | Armorsaurus | Not sourced | Armoured lizard | U: Body Armor |
| Sealed Cave | Hipokute herb, magic ore | - | Abundant because of Veldora's aura | C: healing potions, ore stock |
| Jura | Goblin | E | Dangerous in numbers | Recruit and name |
| Jura | Direwolf pack | Not sourced | Pack hunters; become Tempest wolves when named | Recruit. U (alpha): Ultra Smell, Coercion, Telepathy, wolf form |
| Jura | Ogre | B | Village-destroyer tier, hard to flee from | Recruit six ogres by naming (costly) |
| Jura / marsh | Orc soldier | D | Vast starving host, hundreds of thousands strong | D: minor stamina skill; survivors recruited after the war |
| Marsh | Lizardman | C | Marsh and cave defenders | Allies |
| Jura sky | Megalodon | Not sourced | Flying sharks escorting Charybdis; immune to magic | D: minor magic resistance |
| Rivers, coast | River monsters, sea beasts | Varies | Harass merfolk; sea beasts around ten metres attack ships | D: aquatic forms |
| Anywhere | Lesser and greater daemons | Not sourced | Summoned; humanoid with claws, wings, horns | D: dark-magic knowledge |
| Falmuth, west | Soldiers, knights, court sorcerers | Varies | Conventional army | Souls only (section 11) |
| West | Holy Knights | Not sourced | Spirit magic plus swordsmanship | D: nothing to devour; duels teach Arts |
| Eurazania | Beastfolk warriors | Varies | Transforming lycanthropes | Spar for Arts |
| Jistav | Undead, golems, dark elves | Varies | Undead are extra weak to holy magic | D: undead and golem forms |
| Canaat peaks | Lesser dragons, Dragon Lords | High | Elemental dragons | D: elemental breath |

Enemy families for artificial-intelligence templates [CANON taxonomy]: magic beasts (animal-derived, the majority), named monsters, unique monsters (mutants), majin (intelligent), dragons, cryptids and their insectoid branch, undead, daemons, angels, elementals.

## 16. Bosses by tier

| Tier | Boss | Canon rank | Canon kit and behaviour | Canon outcome | Reward |
|---|---|---|---|---|---|
| 0 | Tempest serpent | Above B (inferred) | Cave apex predator | Killed and eaten | See section 15 |
| 1 | Ifrit, inside its host Shizu | About A+ | Superior flame spirit; fire attacks and self-copies | Pulled out of its host and swallowed | C: Flame Manipulation, Flame Transformation, Body Double, fire resistance. U: Ranged Barrier. C: human form from Shizu, with the Unique skill Degenerate |
| 2 | Orc Disaster Geld | Demon Lord seed holder | Unique skill Starved (devours to take power and recover); regenerates; evolves mid-battle after eating the majin Gelmud; adapts with new resistances | Out-eaten by Predator; yields once his people's future is promised | C: Starved (fuses into Gluttony), Demon Lord seed |
| 3 | Charybdis | Calamity, treated as near Disaster | Mindless flying colossus born of Veldora's magicules, hosted by Phobio; scale barrage, magic jamming, ultraspeed regeneration, megalodon escort | Finished by Milim with a non-magical blast | C: Gravity Manipulation from the core. U: Mana Jamming |
| 4 | Falmuth invasion | - | Holy Field plus Anti-Magic Area over the town; otherworlders Shogo (Berserker, later Survivor), Kyoya (Severer: unseen spatial blades), Kirara (Bewilder: compelling voice); Knight Captain Folgen (Spearhead); archmage Razen (body possession, heavy spells); then the army | Army destroyed by Megiddo | C: Merciless, souls for awakening. D: one otherworlder skill of choice |
| 4 | Hinata Sakaguchi, first duel | Not sourced | Holy Knight commander; Mathematician (prediction), Usurper (steals skills), a seven-hit rapier technique that kills the soul, Disintegration | Rimuru cannot win and escapes with a decoy | D: survive-and-escape encounter; she can steal one equipped skill for the fight |
| 5 | Clayman and his Five Fingers | Disaster (Demon Lord) | Puppet master: mind control, a multi-armed puppet, Demon Blaster beam, awakened form; lieutenants Yamza (ice sword), Myulan (Anti-Magic Area), Pirone, Adalmann (undead), Kumara (fox) | Devoured at the Demon Lords' council; his skill was absorbed and dismantled | Seat among the Demon Lords. D: Demon Blaster |
| 6 | Hinata rematch, Ten Great Saints, Seven Luminaries | Not sourced | Element-themed magic swordsmen; elders who cast Disintegration together; Hinata adds Meltslash | Rimuru wins; peace with the Church | C: Meltslash, analysed from a swallowed holy attack |
| 7 | Dungeon guardians | S to million class | See section 17 | - | Section 17 |
| 8 | Other Demon Lords (optional duels) | True Demon Lord tier | Carrion (beast form, Beast Roar), Frey (Duplicator, magic jamming), Dagruel (magic nullification, grows with rage), Dino (Sloth, later Belphegor), Leon (holy light), Luminous (drain, life-and-death powers) | Mostly rivals or allies | D: one technique each |
| 8 | Milim Nava | Special S | Dragonoid; Drago-Buster, Drago-Nova | Never beaten; won over with honey | D: survive the timer or offer honey; friendship unlocks her help |
| 9 | Eastern Empire: Imperial Guardians, Yuuki, Velgrynd, dominated Veldora, Emperor Rudra with Michael | Up to Catastrophe | Ranked elite guard; Yuuki (skill-cancelling touch, later Mammon); Velgrynd (scorch and acceleration, parallel bodies); Michael's domination of others | Rimuru absorbs both dragons and reaches True Dragon class | C: storm and scorch dragon powers, merged into Azathoth |
| 10 | Angel war: Michael, Feldway, Velzard, Dagruel's titans, the insect lord Zelanus | Catastrophe | Seraph armies; Velzard's endless winter; dominated Demon Lords | Michael is devoured by Rimuru; other outcomes are not covered here | C: the angelic Ultimate skills. Post-game; kits largely [DESIGN] |
| - | Guy Crimson | Top of the Demon Lords | Primordial daemon; copies any skill he has seen | Never fights Rimuru in earnest | D: unwinnable secret duel |

## 17. Ramiris's Dungeon: the pure dungeon-crawl mode

[CANON] A labyrinth created in the capital by the fairy Demon Lord Ramiris, with Veldora as its final boss. It opens as a festival attraction and becomes a major draw for adventurers; in wartime the whole capital is moved inside it, and the invading Imperial army was fought there. Its strongest guardians are the Ten Dungeon Marvels, and several of them are former enemies. A settlement of treants and elves lives on floor 95.

Rules [UNCONFIRMED: from franchise explainers, medium not stated]:

| Rule | Detail |
|---|---|
| Entry | Small fee (three silver coins) |
| Resurrection Bracelet | Cancels one death inside and returns the wearer, healed, to the surface |
| Return Whistle | Single use; teleports one person to the entrance (thirty silver) |
| Recording Crystal | One save point to resume from; checkpoints sit every ten floors |
| Guardians | A boss every tenth floor gates the floors beyond |
| Loot | Chests stocked with crafted weapons and armour; first clears pay gold and rare chests |
| Structure | 100 floors built from blocks that Ramiris can rearrange; monsters are born from Veldora's aura and grow stronger with depth; she can revive those registered to the labyrinth |

Floors:

| Floors | Content | Guardian |
|---|---|---|
| 1 | Safe practice area | - |
| 2-10 | Monsters rise from F to B rank | 10: [DESIGN] cave-fauna boss |
| 11-40 | Not described in sources | 20, 30, 40: [DESIGN] |
| 41-50 | Slimes: corrode gear, shrug off physical hits, block corridors, merge | 50: Gozul and Mezul (ox-head and horse-head) |
| 51-60 | Lethal traps, golems, poison gas, sonic cannons | 60: Gadra, rune master and former Imperial archmage |
| 61-70 | Undead necropolis | 70: Adalmann (EP about 0.88 million), with the swordsman Albert (0.68 million) and the undead dragon Wenti (0.98 million) |
| 71-80 | [DESIGN] insect floors | 79: Apito, insect queen (0.78 million). 80: Zegion, martial insect lord (4.99 million) |
| 81-90 | [DESIGN] beast floors | 90: Kumara, nine-tailed fox who fields eight tail-beasts (1.88 million) |
| 91-95 | Production and storage; floor 95 is a green settlement of elves and treants with an inn, a shop and the last save point | - |
| 96-99 | Four Dragon Lords | 96 earth (Boreas), 97 wind (Notos), 98 ice (Zephyrus), 99 fire (Euros) |
| 100 | Veldora, Storm Dragon | Final boss |

Guardian EP figures are [UNCONFIRMED] fan transcriptions of late-volume stat sheets. Which named Dragon Lord holds which element is [UNCONFIRMED].

[DESIGN] Integration:
- The Dungeon opens when the capital reaches its nation tier. Because the labyrinth is its own pocket world, it sits outside the timeline reset: once unlocked it is available in every later life from a shrine near the Sealed Cave, with records kept.
- With a bracelet, death inside ejects you and is not a reincarnation. Without one it is a real death.
- Floors are modular blocks reshuffled each visit, which matches the rearranging rule above.
- It is the best place to practise Arts safely, so it feeds the memory progression.
- Late twist: defend your own Dungeon against the Imperial invasion, placing guardians and traps.

## 18. Story progression arc (mirrors the light novel's volume order)

All arcs are optional and can be reached out of order; the world scales by region, not by story flag.

| Act | Volumes | Events | Main places | Power milestones [CANON] |
|---|---|---|---|---|
| 1 | 1 | Rebirth; friendship and mutual naming with Veldora, who is swallowed with his seal; goblin village; dwarven kingdom; Shizu and Ifrit | Sealed Cave, Jura, Dwargon | Predator, Great Sage, cave skills, fire skills, human form |
| 2 | 2 | Ogres join; Orc Disaster war in the marshes; the forest unites | Jura, Lake Siss | Starved -> Gluttony; Demon Lord seed; mass naming |
| 3 | 3 | Milim arrives; Demon Lords take notice; Charybdis | Capital and skies above Jura | Gravity power; magicules grow toward Disaster class |
| 4 | 4 | Beast kingdom contact; the summoned children; spirit labyrinth | Englassia, Dwelling of the Spirits | Spirit contracts; first clash with Hinata follows |
| 5 | 5 | Falmuth and the Church attack; Megiddo; Harvest Festival; Veldora freed | Capital and its outskirts | Merciless; Raphael; Beelzebuth; Demon Slime; then Uriel and the Veldora skill |
| 6 | 6 | Demon Lords' council; Clayman falls; the eight-seat council forms | Council hall, Jistav | Recognised Demon Lord |
| 7 | 7 | Hinata and the Holy Knights; the Luminaries exposed | Placement is the designer's choice | Meltslash; Future Attack Prediction |
| 8 | 8-9 | Nation-building; Founder's Festival; tournament; Dungeon opens | Capital, Dungeon | Dungeon mode unlocked |
| 9 | 10-11 | Council of the West and the hidden Rozzo family; journey to Lubelius | Western nations, Lubelius | Political standing |
| 10 | 12-16 | Eastern Empire invades with over 900,000 troops; capital moved into the Dungeon; counter-march; Velgrynd | Jura, Dungeon, Imperial capital | Followers awakened with souls; Ciel; Azathoth; Ultimate Slime |
| 11 | 17-23 | Angel war against Michael and Feldway; Velzard controlled; titans; finale | Whole world | Michael absorbed; post-game |

For non-slime lives, keep the same events but change the player's part in them: a human may meet the forest's rise from the guild or Church side; a goblin or ogre may be the one who unites the forest.

## 19. Art direction, camera, controls and interface [DESIGN]
- Look: stylised, cel-shaded 3D with clean silhouettes and readable colour; bright forest, glowing-ore caves, distinct palettes per nation. Original character designs.
- Slime: translucent, squash-and-stretch, colour chosen by the player; visible swallowed items for a moment; silver-and-gold body after Demon Lord awakening.
- Camera: third-person orbit, lock-on targeting, focus slow-motion while Thought Acceleration is held.
- Controls (gamepad first, rebindable): move, camera, jump/climb, glide, dodge, light and heavy attack, skill wheel (hold), form wheel (hold), devour (hold near a valid target), scan, advisor prompt, map.
- Combat feel: stagger enemies to open a devour window; each mimic form has its own moveset; weapon Arts in humanoid forms.
- Interface: Voice of the World banners; advisor subtitles in a different style; status sheet showing name, race, rank and EP, skills by tier, resistances and Arts; fusion tree; soul-corridor list; codex; magicule density overlay on the map.
- Audio: neutral synthetic voice for the world, warmer one for the advisor; original score.

## 20. Technical architecture [DESIGN]
- Data definitions: Skill (tier, sub-functions, capacity cost, tags), FusionRecipe, Race (evolution graph, intrinsics, base EP), Creature (rank, EP, family, drops with C/U/D source tag), Boss (phases), Region (density, spawn tables), DungeonFloor (block set, guardian), WishCard.
- Core systems: character controller with swappable form modules; skill runtime; Predator module (five functions); advisor module (analysis queue, scan, hints); EP and capacity; resistance tracker; naming and soul-corridor graph; evolution and awakening state machine; Voice of the World event bus that every system publishes to; world streaming for the seamless map; spawn director driven by density; faction reputation; dungeon generator.
- Two save layers: MemorySave (Arts, spells, weapon mastery, codex, map, dungeon records, pending wishes) and LifeSave (everything else, deleted on death).
- Every lore fact shown in-game should be traceable to a data field carrying its CANON, DESIGN or UNCONFIRMED tag.

## 21. Build order and milestones

| Milestone | Scope | Done when |
|---|---|---|
| 0. Vertical slice | Sealed Cave only. Slime controller (hop, cling, squeeze, swim); sightless opening until Mana Perception; Predator's five functions; Great Sage scan and analysis queue with the link upgrade; herb and ore to potions; serpent, centipede, spider, bat and armoured lizard with simple behaviours; Water Blade learned by practice; Veldora dialogue, naming and swallow-by-agreement; Voice of the World banners; status sheet; death -> wish cards -> rebirth as a slime with codex kept | A 20-30 minute loop is fun and a second life is visibly faster because of memory |
| 1. Reincarnation | Spin with three reels; goblin and human races; Arts practice, memory and re-attunement; cause-of-death resistances; two save layers | Three lives as three races share Arts and codex |
| 2. Open world slice | Streaming Jura Forest and marsh; climbing, gliding, threads, mounts; density system; goblin village; direwolves; naming with cost, sleep mode and corridor | A village can be named and evolved, and overspending is survivable or fatal as designed |
| 3. Boss trio | Ifrit, Orc Disaster, Charybdis; fusion tree; Gluttony with Receive and Provide; seed | A slime life can go from cave to Demon Lord seed |
| 4. Capital and Dungeon | Settlement tiers; crafting; floors 1-10, then the full hundred with guardians and bracelet rules | The Dungeon is replayable alone as a mode |
| 5. Human nations and awakening | Dwargon, Blumund, Falmuth, Englassia; Free Guild ranks; Falmuth invasion with Holy Field; soul quota; Harvest Festival; Hero route trials | Both awakening routes can be completed |
| 6. Demon Lords and the Church | Council, Clayman, Hinata rematch, Lubelius, Ultimate skills and the Will contest | An Ultimate-against-Ultimate duel works |
| 7. Endgame | Empire war and Dungeon defence, True Dragons, remaining continents | True Dragon tier reachable |

## 22. What I want from you first
1. Confirm the engine line and list any assumptions.
2. Give a one-page technical plan for Milestone 0 with the folder layout and data schemas.
3. Then write Milestone 0 in working increments, starting with the slime controller and the Predator module.
````

## Accuracy notes

**Firmly light-novel-sourced (wiki pages that follow the light novel, publisher blurbs, or text quoted from the novel):**

- Skill tiers, intrinsic skills, the resistance-to-nullification ladder, the practice-only rule for Arts, and the Voice of the World's announcements and Yes/No prompts ([Skill](https://tensura.fandom.com/wiki/Skill), [Extra skill](https://tensura.fandom.com/wiki/Extra_skill), [Unique skill](https://tensura.fandom.com/wiki/Unique_skill), [Art](https://tensura.fandom.com/wiki/Art), [World Language](https://tensura.fandom.com/wiki/World_Language)).
- The Ultimate-counters-Ultimate rule and the awakening requirements ([Ultimate skill](https://tensura.fandom.com/wiki/Ultimate_skill)).
- Existence point bands, danger classes and guild rank meanings ([Rank](https://tensura.fandom.com/wiki/Rank)); the 200,000 EP seed threshold and the 10,000-soul quota ([Demon lord](https://tensura.fandom.com/wiki/Demon_lord)); the Harvest Festival ([Harvest Festival](https://tensura.fandom.com/wiki/Harvest_Festival)); the Hero's egg route ([Chosen hero](https://tensura.fandom.com/wiki/Chosen_hero)); the 100,000-soul follower awakening ([Twelve Guardian Lords](https://tensura.fandom.com/wiki/Twelve_Guardian_Lords)).
- Naming costs, risks, the sleep after naming six ogres, loss of Named status on the master's death, and equal naming ([Name](https://tensura.fandom.com/wiki/Name)).
- Predator's five functions, Great Sage's functions, and the fusion chains ([Predator](https://tensura.fandom.com/wiki/Predator), [Great Sage](https://tensura.fandom.com/wiki/Great_Sage), [Gluttony](https://tensura.fandom.com/wiki/Gluttony), [Beelzebuth](https://tensura.fandom.com/wiki/Beelzebuth), [Raphael](https://tensura.fandom.com/wiki/Raphael), [Rimuru abilities](https://tensura.fandom.com/wiki/Rimuru_Tempest/Abilities_%26_gear)).
- The dying-thought origin of the slime body, Predator and Great Sage ([Death and Reincarnation](https://tensura.fandom.com/wiki/Death_and_Reincarnation)).
- Race trees, magic types, the spirit triangle and body layers ([Species](https://tensura.fandom.com/wiki/Species), [Magic](https://tensura.fandom.com/wiki/Magic), [Body](https://tensura.fandom.com/wiki/Body)).
- Geography and nations ([Great Jura Forest](https://tensura.fandom.com/wiki/Great_Jura_Forest), [Lake Siss](https://tensura.fandom.com/wiki/Lake_Siss), [Central World](https://tensura.fandom.com/wiki/Central_World), and the nation pages listed under Sources).
- Base ranks for goblins (E), orcs (D), lizardmen (C), ogres and black spiders (B), Ifrit (about A+) and Charybdis (Calamity), from a thread quoting the novel ([VS Battles thread](https://vsbattles.com/threads/tensei-shitara-slime-datta-ken-ln-minor-crt.64052/)).
- Volume anchors for the festival and Dungeon (Vol. 9) and the Imperial invasion fought in the Dungeon (Vol. 13) ([Yen Press Vol. 9](https://yenpress.com/9781975314378/that-time-i-got-reincarnated-as-a-slime-vol-9-light-novel), [Yen Press Vol. 13](https://yenpress.com/titles/9781975314453-that-time-i-got-reincarnated-as-a-slime-vol-13-light-novel)).

**Kept in the prompt but inferred, lower-confidence or conflicting (tagged `[UNCONFIRMED]` or worth checking):**

- Monster-to-skill pairings for Heat Source Perception (serpent), Body Armor (armorsaurus), the direwolf alpha's skills, Ranged Barrier (Ifrit) and Mana Jamming (Charybdis). The skills are on Rimuru's sheet, but no page read names the source monster.
- Dungeon rules (fees, bracelet, whistle, crystal, floor themes) come from a [CBR explainer](https://www.cbr.com/that-time-i-got-reincarnated-as-a-slime-dungeon-details/) and an [anime episode recap](https://sportskeeda.com/anime/that-time-i-got-reincarnated-slime-season-3-episode-14-rimuru-gets-veldora-ramiris-help-dungeon), not verified light-novel text. They disagree on what happens after a death, and the prompt picks one reading. Floors 11-40 and their guardians are not described anywhere in the notes.
- Adalmann's post: one source puts the undead zone in the 60s, the [Tempest military page](https://tensura.fandom.com/wiki/Jura-Tempest_Federation/Military) puts him on floor 70 with Gadra on 60. The prompt uses floors 61-70 with Adalmann as the floor-70 guardian. The Dragon Lord name-to-element pairing combines two sources that each give half.
- Guardian EP figures and Velgrynd's kit are fan transcriptions of Vol. 16 stat sheets ([Wattpad information book](https://www.wattpad.com/1171622003-tensura's-information-book-character-info-zegion)). No light-novel EP for True Dragons or Demon Lords was sourced, so none is given.
- Ultimate-skill holders by sin or virtue, the rule that Michael can dominate Virtue-series holders, the Holy Field weakening monsters, and "EP ignores skill and will" rest on [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Anime/TenseiShitaraSlimeDattaKen), which mixes media. The full seven-member lists were not verified and are left out.
- Volume placements for Ultimate Slime, Ciel and Azathoth (Vol. 15) are inferred from chapter titles; Uriel and the Veldora skill (Vol. 5-6) are not directly sourced; Michael's absorption (Vol. 19) rests on a single source ([VS Battles profile](https://vsbattles.fandom.com/wiki/Rimuru_Tempest_(Light_Novel))).
- Evolution triggers for lizardman to dragonewt and kijin to oni, the one-to-one mapping of each dying thought to each resistance, and the order of the water-to-mana fusion chain are not confirmed. The upper stages of each race line (soul and divine forms) are read from the wiki's nested species tree, which does not state the order outright.
- The 100-floor count, block rearrangement and aura-born monsters come from the same explainers. That the Orc war climaxes in the lizardman marshes, and where the second Hinata duel takes place, are recollection-level, so the prompt leaves placement open.
- The Demon Lord seed coming from the Orc Disaster, the Orc Disaster gaining Heat Resistance mid-fight, and Milim being won over with honey are sourced only to [TV Tropes character pages](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ThatTimeIGotReincarnatedAsASlimeRimuruTempest).
- Eurazania's position: one source says south of Jura, another puts Milim's domain on the east border. The prompt says south to south-east.
- Kyoya's skill is "Severer" in one source and "All-Seeing Eye" in another. The orc host is given only as hundreds of thousands. The notes on Vols. 20-23 are thin, so Act 11 is a sketch.

**Left out because unverified or web-novel-only:**

- The web novel's rank table (S at about 2 million, True Dragons at about 5 million, per-species EP values), the web-novel capital name "Tempest City", Apito's web-novel gift name, and the web novel's different ending ([WN rank page](https://tensura.fandom.com/wiki/WN/Rank)).
- Recollection-only details: the cave's sealed door and the adventurer trio, the dryad's formal request, nuclear-magic tiers, the Sky Dragon, knight spiders and giant ants, the elemental colossus's stats, early Dungeon guardians, and the "101st floor".
- Shub-Niggurath is omitted from the fusion table because sources conflict on its inputs.

**Name variants (the prompt uses the first form):** Falmuth / Farmus; Englassia / Ingrassia; Sarion / Thalion; Gluttony / Glutton; Beelzebuth / Belzebuth or Beelzebub; Degenerate / Deviant; Mana Perception / Magic Sense; Infinity Prison / Unlimited Imprisonment; Gozul and Mezul / Bovix and Equix; Moderate Harlequin Alliance / Moderate Clown Troupe; Lake Siss / Sisu. The second forms appear to be the official English wording in several cases, which was not checked against the books.

**Game design, not canon:** the repeating reincarnation loop, the spin, memory carry-over, wish cards for later lives, the timeline reset, removing Rimuru as a character, seeking a namer, the Dungeon persisting across lives, traversal, every drop marked D, and all tuning numbers.

## Sources

- Tensura Wiki (light-novel-following pages): [Skill](https://tensura.fandom.com/wiki/Skill), [Extra skill](https://tensura.fandom.com/wiki/Extra_skill), [Unique skill](https://tensura.fandom.com/wiki/Unique_skill), [Ultimate skill](https://tensura.fandom.com/wiki/Ultimate_skill), [Art](https://tensura.fandom.com/wiki/Art), [World Language](https://tensura.fandom.com/wiki/World_Language), [Magicule](https://tensura.fandom.com/wiki/Magicule), [Existence value](https://tensura.fandom.com/wiki/Existence_value), [Rank](https://tensura.fandom.com/wiki/Rank), [Name](https://tensura.fandom.com/wiki/Name), [Species](https://tensura.fandom.com/wiki/Species), [Monster](https://tensura.fandom.com/wiki/Monster), [Oni](https://tensura.fandom.com/wiki/Oni), [Archdaemon](https://tensura.fandom.com/wiki/Archdaemon), [Demon lord](https://tensura.fandom.com/wiki/Demon_lord), [Harvest Festival](https://tensura.fandom.com/wiki/Harvest_Festival), [Chosen hero](https://tensura.fandom.com/wiki/Chosen_hero), [Twelve Guardian Lords](https://tensura.fandom.com/wiki/Twelve_Guardian_Lords), [Magic](https://tensura.fandom.com/wiki/Magic), [Disintegration](https://tensura.fandom.com/wiki/Disintegration), [Body](https://tensura.fandom.com/wiki/Body), [Soul](https://tensura.fandom.com/wiki/Soul), [True Dragon](https://tensura.fandom.com/wiki/True_Dragon)
- Tensura Wiki (Rimuru and skills): [Rimuru abilities and gear](https://tensura.fandom.com/wiki/Rimuru_Tempest/Abilities_%26_gear), [Rimuru chronology](https://tensura.fandom.com/wiki/Rimuru_Tempest/Chronology), [Rimuru Tempest](https://tensura.fandom.com/wiki/Rimuru_Tempest), [Death and Reincarnation](https://tensura.fandom.com/wiki/Death_and_Reincarnation), [Predator](https://tensura.fandom.com/wiki/Predator), [Great Sage](https://tensura.fandom.com/wiki/Great_Sage), [Starved](https://tensura.fandom.com/wiki/Starved), [Gluttony](https://tensura.fandom.com/wiki/Gluttony), [Beelzebuth](https://tensura.fandom.com/wiki/Beelzebuth), [Raphael](https://tensura.fandom.com/wiki/Raphael), [Birth of a Demon Lord](https://tensura.fandom.com/wiki/Birth_of_a_Demon_Lord_(chapter))
- Tensura Wiki (world): [Sealed Cave](https://tensura.fandom.com/wiki/Sealed_Cave), [Tempest serpent](https://tensura.fandom.com/wiki/Tempest_serpent), [Giant bat](https://tensura.fandom.com/wiki/Giant_bat), [Great Jura Forest](https://tensura.fandom.com/wiki/Great_Jura_Forest), [Lake Siss](https://tensura.fandom.com/wiki/Lake_Siss), [Rimuru City](https://tensura.fandom.com/wiki/Rimuru_City), [Central World](https://tensura.fandom.com/wiki/Central_World), [Dwargon](https://tensura.fandom.com/wiki/Armed_Nation_of_Dwargon), [Blumund](https://tensura.fandom.com/wiki/Kingdom_of_Blumund), [Falmuth](https://tensura.fandom.com/wiki/Kingdom_of_Falmuth), [Englassia](https://tensura.fandom.com/wiki/Kingdom_of_Englassia), [Lubelius](https://tensura.fandom.com/wiki/Holy_Empire_of_Lubelius), [Sarion](https://tensura.fandom.com/wiki/Sorcerous_Dynasty_of_Sarion), [Jistav](https://tensura.fandom.com/wiki/Puppet_Nation_of_Jistav), [Eastern Empire](https://tensura.fandom.com/wiki/Nasca_Namrium_Ulmeria_United_Eastern_Empire), [Ramiris](https://tensura.fandom.com/wiki/Ramiris), [Tempest military](https://tensura.fandom.com/wiki/Jura-Tempest_Federation/Military), [Moderate Harlequin Alliance](https://tensura.fandom.com/wiki/Moderate_Harlequin_Alliance), [Charybdis](https://tensura.fandom.com/wiki/Charybdis), [Folgen](https://tensura.fandom.com/wiki/Folgen), [Gozul](https://tensura.fandom.com/wiki/Gozul), [Zegion](https://tensura.fandom.com/wiki/Zegion), [Kumara](https://tensura.fandom.com/wiki/Kumara), [Imperial Guardians](https://tensura.fandom.com/wiki/Imperial_Guardians), [Empowerment (Vol. 1)](https://tensura.fandom.com/wiki/Empowerment), [WN rank page](https://tensura.fandom.com/wiki/WN/Rank)
- Wikipedia: [series article](https://en.wikipedia.org/wiki/That_Time_I_Got_Reincarnated_as_a_Slime), [volume list](https://en.wikipedia.org/wiki/List_of_That_Time_I_Got_Reincarnated_as_a_Slime_volumes), [character list](https://en.wikipedia.org/wiki/List_of_That_Time_I_Got_Reincarnated_as_a_Slime_characters)
- Yen Press volume pages: [Vol. 9](https://yenpress.com/9781975314378/that-time-i-got-reincarnated-as-a-slime-vol-9-light-novel), [Vol. 10](https://yenpress.com/titles/9781975314392-that-time-i-got-reincarnated-as-a-slime-vol-10-light-novel), [Vol. 11](https://yenpress.com/titles/9781975314415-that-time-i-got-reincarnated-as-a-slime-vol-11-light-novel), [Vol. 12](https://yenpress.com/titles/9781975314439-that-time-i-got-reincarnated-as-a-slime-vol-12-light-novel), [Vol. 13](https://yenpress.com/titles/9781975314453-that-time-i-got-reincarnated-as-a-slime-vol-13-light-novel), [Vol. 14](https://yenpress.com/titles/9781975314477-that-time-i-got-reincarnated-as-a-slime-vol-14-light-novel), [Vol. 15](https://yenpress.com/titles/9781975314491-that-time-i-got-reincarnated-as-a-slime-vol-15-light-novel), [Vol. 18](https://yenpress.com/titles/9781975375553-that-time-i-got-reincarnated-as-a-slime-vol-18-light-novel)
- VS Battles: [Rimuru Tempest (Light Novel) profile](https://vsbattles.fandom.com/wiki/Rimuru_Tempest_(Light_Novel)), [light-novel rank thread](https://vsbattles.com/threads/tensei-shitara-slime-datta-ken-ln-minor-crt.64052/)
- TV Tropes (mixed media, lower confidence): [series page](https://tvtropes.org/pmwiki/pmwiki.php/Anime/TenseiShitaraSlimeDattaKen), [Rimuru](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ThatTimeIGotReincarnatedAsASlimeRimuruTempest), [Demon Lords](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ThatTimeIGotReincarnatedAsASlimeDemonLords), [Human Nations](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ThatTimeIGotReincarnatedAsASlimeHumanNations), [Non-Human Nations](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ThatTimeIGotReincarnatedAsASlimeNonHumanNations), [Other Characters](https://tvtropes.org/pmwiki/pmwiki.php/Characters/ThatTimeIGotReincarnatedAsASlimeOtherCharacters)
- Dungeon explainers (medium not stated): [CBR](https://www.cbr.com/that-time-i-got-reincarnated-as-a-slime-dungeon-details/), [Sportskeeda season 3 episode 14 recap](https://sportskeeda.com/anime/that-time-i-got-reincarnated-slime-season-3-episode-14-rimuru-gets-veldora-ramiris-help-dungeon)
- Fan-transcribed stat sheets (Vol. 16): Wattpad information book entries for [Zegion](https://www.wattpad.com/1171622003-tensura's-information-book-character-info-zegion), [Kumara](https://www.wattpad.com/1171617633-indef-hiatus-tensura%27s-information-book-character), [Adalmann](https://www.wattpad.com/1171636682-indef-hiatus-tensura%27s-information-book-character), [Albert](https://www.wattpad.com/1171638089-indef-hiatus-tensura%27s-information-book-character), [Wenti](https://www.wattpad.com/1171639389-indef-hiatus-tensura%27s-information-book-character), [Apito](https://www.wattpad.com/1171619114-indef-hiatus-tensura's-information-book-character), [Velgrynd](https://www.wattpad.com/1171544168-indef-hiatus-tensura%27s-information-book-character), [unique skills list](https://www.wattpad.com/1200502057-indef-hiatus-tensura%27s-information-book-list-of)
- Other: [SoBrief summary of Vol. 5](https://sobrief.com/books/that-time-i-got-reincarnated-as-a-slime-light-novel-vol-5), [LitRetreat reading order](https://litretreat.com/that-time-i-got-reincarnated-as-a-slime-light-novel-reading-order/), [Anime Corner on the final volume](https://animecorner.me/that-time-i-got-reincarnated-as-a-slime-ending-volume-23-fuse-mitz-vah-announcement-november/)
