extends TestCase
## The prologue, the death sequence, last-thought cards and rebirth.


func _run() -> void:
	print("Death")
	sequences = true
	sighted = false
	await start_main()
	var death: DeathScreen = main.get_node("HUD/DeathScreen")

	# Prologue: the death before the first life, its thoughts read aloud.
	check(Game.life == null, "no life begins until the prologue is over")
	await _until(func() -> bool: return death.is_open())
	check(death.offered().size() == 6, "the prologue reads six thoughts")
	check(Game._cursor_locks == 1, "the cursor is free while the cards are up")
	check(death._buttons[0].text.contains("?"), "a thought's result is hidden before it is read")
	await _until(func() -> bool: return death._confirm.visible)
	check(death._buttons[0].text.contains("Predator"), "each thought is granted as it is read")
	await seconds(2.5)
	check(spoken().contains("A wish is heard. Unique skill: Predator.") and spoken().contains("Nothing comes of it"),
			"the Voice says what comes of each thought, including nothing")
	death.confirm()
	await _until(func() -> bool: return Game.life != null)
	var life := Game.life
	check(life.life_number == 1 and life.race_id == "slime", "then the first life begins, as a slime")
	check(life.has_skill("predator") and life.has_skill("great_sage") and not life.has_skill("sage"),
			"born with Predator, and Sage wished twice is Great Sage")
	check(life.resistances.has("pain_nullification"), "and with Pain Nullification")
	check(life.birth_skills.has("predator") and is_equal_approx(life.max_magicules, 100.0), "wished skills reserve no capacity")
	check(Soul.birth_grants["reel_weights"]["race"]["slime"] == 20.0, "the bloodless wish is kept as weight toward the slime")
	check(not Game.is_sighted(), "it is still born sightless")
	await seconds(3.0)
	check(not death.is_busy() and not get_tree().paused, "the world runs once the life has begun")
	check(Game.ui_locks == 0 and Game._cursor_locks == 0, "and nothing still holds the controls or the cursor")

	# At a first death the Predator thought is offered however the life went.
	life.stats = {"scans": 400.0, "analyses": 300.0, "seconds_at_low_health": 1500.0, "seconds_blind": 4500.0,
			"seconds_in_water": 4000.0, "talks": 200.0, "damage_taken": 25000.0}
	var crowded: Array[String] = []
	for card in Wishes.offer(life, "blade"):
		crowded.append(str(card["id"]))
	check(crowded.size() == 8 and crowded.has("take_in_everything"),
			"a first death always offers the thought that leads to Predator, even with eight better fits")

	# Death: slow motion, drained colour, then the cards.
	life.stats = {"devours": 10.0, "scans": 6.0, "analyses": 4.0, "seconds_blind": 80.0, "kills": 2.0}
	Game.die("blade")
	await frames(3)
	check(Engine.time_scale < 0.5, "time slows as the life ends")
	check(Soul.lives_lived == 1 and Soul.birth_grants["resistances"] == ["pierce_resistance"], "the cause is inscribed at once")
	await _until(func() -> bool: return death.is_open())
	check(is_equal_approx(Engine.time_scale, 1.0) and get_tree().paused, "the world stops while the last thoughts are read")
	var saved := _saved()
	check(int(saved.get("lives_lived", -1)) == 0 and (saved["birth_grants"]["wish_skills"] as Array).has("predator"),
			"nothing is written until the thoughts are chosen: quitting here loses no wish")
	await seconds(1.0)
	check(_voice_line_shown("Last thoughts are read"), "the Voice is still seen while the world is stopped")
	var veil: WorldVeil = main.get_node("HUD/Veil")
	check(is_equal_approx(veil.desaturation, 1.0), "the colour has drained from it")
	var ids := _ids(death)
	check(ids.size() >= 6 and ids.size() <= 8, "six to eight cards are offered")
	for wanted: String in ["take_in_everything", "wished_to_understand", "more_to_understand", "body_cannot_bleed", "wanted_to_see", "idle_worry"]:
		check(ids.has(wanted), "the offer fits the life: %s" % wanted)
	check(death._buttons[ids.find("take_in_everything")].text.contains("Predator"), "a card the soul has seen shows its result")
	check(death._buttons[ids.find("wanted_to_see")].text.ends_with("?"), "a card it has not seen shows a question mark")

	death.toggle(ids.find("take_in_everything"))
	death.toggle(ids.find("wished_to_understand"))
	death.toggle(ids.find("more_to_understand"))
	death.toggle(ids.find("idle_worry"))
	check(death._chosen.size() == 3, "no more than three can be chosen")
	death.confirm()
	await _until(func() -> bool: return Game.life != life)
	life = Game.life
	check(life.life_number == 2 and not get_tree().paused, "confirming leads to the next life")
	saved = _saved()
	check(int(saved.get("lives_lived", -1)) == 1 and saved["birth_grants"]["resistances"] == ["pierce_resistance"]
			and (saved["birth_grants"]["wish_skills"] as Array).has("great_sage"),
			"the death and its wishes are written together")
	check(life.has_skill("predator") and life.has_skill("great_sage"), "the chosen wishes are granted at birth")
	check(life.resistances == ["pierce_resistance"], "with the imprint of the cause, and nothing that was not chosen")
	await seconds(3.0)
	check(is_equal_approx(veil.darkness, 0.0) and is_equal_approx(veil.desaturation, 0.0), "colour returns with the new life")

	# An unknown card: the result is learned by choosing it.
	life.stats = {"seconds_blind": 80.0}
	Game.die("fire")
	await _until(func() -> bool: return death.is_open())
	ids = _ids(death)
	death.toggle(ids.find("wanted_to_see"))
	death.confirm()
	await _until(func() -> bool: return Game.life != life)
	life = Game.life
	check(life.has_skill("mana_perception") and Game.is_sighted(), "wishing to see grants Mana Perception: born sighted")
	check(not life.has_skill("predator"), "a wish not made again is not granted again")
	check(life.resistances == ["heat_resistance"], "and the imprint follows the latest death")
	check(Wishes.is_known(Database.wish_cards["wanted_to_see"]), "the soul now knows what that card leads to")
	await seconds(3.0)

	# Letting go of everything takes a deliberate press, never a stray one.
	Game.die("poison")
	await _until(func() -> bool: return death.is_open())
	death.request_confirm()
	await _key(KEY_ENTER)
	check(death.is_open() and not death._empty_confirm_armed, "a confirm in the first moment after the cards appear is ignored")
	await seconds(1.0)
	await _key(KEY_SPACE)
	check(death.is_open() and not death._empty_confirm_armed, "Space, the hop key, never confirms")
	await _key(KEY_ENTER)
	check(death.is_open() and death._empty_confirm_armed and Game.life == life, "with nothing chosen, Enter asks first")
	death.toggle(0)
	death.toggle(0)
	check(not death._empty_confirm_armed, "touching a card takes the question back")
	await _key(KEY_ENTER)
	await _key(KEY_ENTER)
	await _until(func() -> bool: return Game.life != life)
	life = Game.life
	check(life.skills == ["absorb", "dissolve", "self_regeneration"], "choosing nothing leaves only the body's own skills")
	check(life.resistances == ["poison_resistance"] and Soul.lives_lived == 3, "and the imprint")

	# A life that ends while the dark is still lifting is not left stranded.
	check(death.is_busy(), "the new life begins before the dark has lifted")
	Game.die("cold")
	await _until(func() -> bool: return death.is_open())
	check(death.is_open() and not Game.life.alive, "a death during that fade still reaches its last thoughts")
	death.confirm()
	await _until(func() -> bool: return Game.life != life)
	life = Game.life
	check(life.life_number == 5 and life.resistances == ["cold_resistance"] and Soul.lives_lived == 4, "and the life after it")
	await seconds(3.0)
	check(not death.is_busy() and Game.ui_locks == 0 and Game._cursor_locks == 0 and not get_tree().paused,
			"after which the world runs as usual")


## Waits until a condition holds, for at most twenty seconds.
func _until(condition: Callable) -> void:
	for i in 1200:
		if condition.call():
			return
		await frames(1)
	check(false, "timed out waiting for a condition")


## The soul as it is on disk.
func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Soul.save_path))
	return parsed if parsed is Dictionary else {}


## Whether the Voice's column is showing a fully typed-out line with this text.
func _voice_line_shown(text: String) -> bool:
	for strip in main.get_node("HUD/VoicePanel")._world_column.get_children():
		var label := strip.get_child(0) as Label
		if label.text.contains(text) and is_equal_approx(label.visible_ratio, 1.0):
			return true
	return false


## Presses and releases a keyboard key as a real event.
func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)


func _ids(death: DeathScreen) -> Array[String]:
	var ids: Array[String] = []
	for card in death.offered():
		ids.append(str(card["id"]))
	return ids
