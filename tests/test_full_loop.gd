extends TestCase
## One whole run of the Milestone 0 slice with the real settings: prologue,
## a sightless birth, Veldora, herbs, the lake, a hunt, a death at the
## serpent's fangs, last thoughts, and a second life that is measurably
## faster because of what the soul remembers.

var _death: DeathScreen
var _dialogue: DialoguePanel


func _run() -> void:
	print("Full loop")
	sequences = true
	populate = true
	sighted = false
	await start_main()
	_death = main.get_node("HUD/DeathScreen")
	_dialogue = main.get_node("HUD/DialoguePanel")

	await _until(func() -> bool: return _death.is_open() and _death._confirm.visible)
	_death.confirm()
	await _until(func() -> bool: return Game.life != null)
	check(Game.life.has_skill("predator") and Game.life.has_skill("great_sage") and not Game.is_sighted(),
			"life 1 begins: a sightless slime with Predator and Great Sage")

	var first := await _live(true)
	check(first["sight_seconds"] > 3.5, "life 1: learning to see took %.1f s of stillness" % first["sight_seconds"])
	check(first["herb_seconds"] > 40.0, "life 1: an unlinked herb analysis would take %.0f s" % first["herb_seconds"])
	check(first["spits"] == 8, "life 1: Water Blade took 8 spits")
	check(Game.life.full_name() == "Mizu Tempest" and Game.life.sealed == ["Veldora"], "life 1: named, and carrying Veldora")
	check(Game.life.ep > 600, "life 1: grew to %d EP" % Game.life.ep)

	# The serpent ends it.
	var life := Game.life
	var serpent := _nearest("tempest_serpent")
	check(serpent != null, "the serpent is in its lair")
	player._invulnerable = 0.0
	player.respawn(serpent.global_position + Vector3(0.0, 0.5, 5.0))
	await _until(func() -> bool: return not life.alive)
	check(not life.alive, "the tempest serpent kills the slime")
	await _until(func() -> bool: return _death.is_open())
	var ids: Array[String] = []
	for card in _death.offered():
		ids.append(str(card["id"]))
	check(ids.has("take_in_everything") and ids.has("wished_to_understand") and ids.has("more_to_understand"),
			"the last thoughts reflect a life of devouring and study")
	for wanted: String in ["take_in_everything", "wished_to_understand", "more_to_understand"]:
		_death.toggle(ids.find(wanted))
	_death.confirm()
	await _until(func() -> bool: return Game.life != life)
	life = Game.life
	check(life.life_number == 2 and life.has_skill("predator") and life.has_skill("great_sage"),
			"life 2 begins with the wishes that were held on to")
	check(life.full_name() == "" and life.sealed.is_empty() and life.ep == 100 and not Game.is_sighted(),
			"and none of the old body: unnamed, empty, 100 EP, sightless")
	check(Soul.knows("species", "giant_bat") and Soul.knows("item", "hipokute_herb"), "the codex came along")
	await seconds(2.0)
	check(life.analysis_linked, "Great Sage remakes the analysis link without being asked")

	var second := await _live(false)
	check(second["sight_seconds"] < first["sight_seconds"] * 0.3,
			"life 2: sight in %.1f s instead of %.1f s" % [second["sight_seconds"], first["sight_seconds"]])
	check(second["herb_seconds"] <= 0.5, "life 2: the herb is analysed in %.1f s" % second["herb_seconds"])
	check(second["spits"] <= 2, "life 2: Water Blade after %d spits" % second["spits"])
	check(second["bat_seconds"] <= 0.5, "life 2: the bat is analysed in %.1f s" % second["bat_seconds"])
	check(second["total_seconds"] < first["total_seconds"] * 0.85,
			"life 2 reaches the same point in %.0f s instead of %.0f s" % [second["total_seconds"], first["total_seconds"]])
	await seconds(2.0)


## Plays one life up to "can see, has potions, Water Blade and a bat's
## skills". Returns how long the memory-sensitive steps took.
func _live(first_life: bool) -> Dictionary:
	var took := {}
	var life := Game.life
	var level: Level = main.level
	var started := _now()
	player._invulnerable = 9999.0
	await seconds(1.0)

	# Veldora teaches Mana Perception.
	player.respawn(level.point("VeldoraAudience"))
	await frames(30)
	await tap("interact")
	await _talk([0, 0] if first_life else [2])
	var sight_started := _now()
	Input.action_press("scan")
	await _until(func() -> bool: return Game.is_sighted())
	Input.action_release("scan")
	took["sight_seconds"] = _now() - sight_started

	# A herb: devour, link (Great Sage asks), analyse.
	var herb := _nearest_harvest("hipokute_herb")
	player.respawn(herb.global_position + Vector3(1.0, 0.4, 0.0))
	await frames(20)
	Input.action_press("devour")
	await _until(func() -> bool: return life.item_count("hipokute_herb") > 0)
	Input.action_release("devour")
	await frames(2)
	took["herb_seconds"] = player.predator.time_left(life.analysis_queue[0]) if not life.analysis_queue.is_empty() else 0.0
	await _until(func() -> bool: return Voice.is_confirm_open() or life.analysis_linked)
	if Voice.is_confirm_open():
		await tap("voice_yes")
	await _until(func() -> bool: return life.recipes.has("healing_potion"))

	# Ore, for the codex.
	var ore := _nearest_harvest("magic_ore")
	player.respawn(ore.global_position + Vector3(1.0, 0.4, 0.0))
	await frames(20)
	Input.action_press("devour")
	await _until(func() -> bool: return life.item_count("magic_ore") > 0)
	Input.action_release("devour")
	await _until(func() -> bool: return life.analysed.has("item:magic_ore"))

	# The lake: drink, then practise Water Blade on dry land.
	await place_at_cell(18, 45, -0.9)
	Input.action_press("devour")
	await _until(func() -> bool: return life.item_count("water") >= 20)
	Input.action_release("devour")
	player.respawn(level.spawn_position())
	await frames(30)
	var spits := 0
	while not life.has_skill("water_blade") and spits < 12:
		await tap("attack_skill")
		await frames(40)
		spits += 1
	took["spits"] = spits

	# A hunt: Water Blade a bat, devour the remains, analyse them.
	var bat := Creature.create("giant_bat")
	level.get_node("Spawned").add_child(bat)
	bat.global_position = player.global_position + Vector3(0.0, 1.0, -8.0)
	bat.home = bat.global_position
	await frames(5)
	for i in 4:
		await tap("scan")
		await frames(10)
	for i in 30:
		if bat.is_corpse():
			break
		await tap("attack_skill")
		await frames(35)
	check(bat.is_corpse(), "Water Blade brings down a giant bat")
	await seconds(1.0)
	player.respawn(bat.global_position + Vector3(1.2, 0.3, 0.0))
	await frames(20)
	var devours_before := float(life.stats.get("devours", 0.0))
	Input.action_press("devour")
	await _until(func() -> bool: return float(life.stats.get("devours", 0.0)) > devours_before)
	Input.action_release("devour")
	await frames(2)
	took["bat_seconds"] = 0.0
	for entry in life.analysis_queue:
		if entry["key"] == "species:giant_bat":
			took["bat_seconds"] = player.predator.time_left(entry)
	await _until(func() -> bool: return life.forms.has("giant_bat"))
	check(life.has_skill("ultra_sound_waves"), "and its skills are acquired")
	took["total_seconds"] = _now() - started

	if first_life:
		# Friendship, names, and carrying Veldora away.
		player.respawn(level.point("VeldoraAudience"))
		await frames(30)
		await tap("interact")
		await _talk([0])
		await _until(func() -> bool: return main.get_node("HUD/NamePanel").is_open())
		main.get_node("HUD/NamePanel").submit("Mizu", "Tempest")
		await frames(5)
		await _talk([0, 0])
		await _until(func() -> bool: return Voice.is_confirm_open())
		await tap("voice_yes")
		await seconds(2.5)
	return took


## Runs the open conversation to its end, taking `choices` in order whenever
## options are offered (and the first option once they run out).
func _talk(choices: Array) -> void:
	for i in 60:
		if not _dialogue.is_open():
			return
		if _dialogue.option_texts().is_empty() or _dialogue._text.visible_ratio < 1.0:
			_dialogue.advance()
		else:
			_dialogue.choose(int(choices.pop_front()) if not choices.is_empty() else 0)
		await frames(2)


## Game time in seconds, counted in physics frames so it is the same on any machine.
func _now() -> float:
	return float(Engine.get_physics_frames()) / 60.0


func _until(condition: Callable) -> void:
	for i in 60 * 120:
		if condition.call():
			return
		await frames(1)
	check(false, "timed out waiting for a condition")


func _nearest(creature_id: String) -> Creature:
	for node in main.level.get_node("Spawned").get_children():
		if node is Creature and node.creature_id == creature_id and not node.is_corpse():
			return node
	return null


func _nearest_harvest(item_id: String) -> Harvestable:
	var best: Harvestable = null
	for node in main.level.get_node("Spawned").get_children():
		if node is Harvestable and node.item_id == item_id and node.is_available():
			if best == null or node.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
				best = node
	return best
