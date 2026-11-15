extends TestCase
## Mimicry: wearing the shape and moves of an analysed species.


func _run() -> void:
	print("Mimicry")
	await start_main()
	await seconds(1.0)
	player._invulnerable = 9999.0
	var life := Game.life

	# Mimicry is a function of Predator and needs an analysed form.
	life.forms.append("giant_bat")
	check(not player.set_form("giant_bat"), "without Predator there is no Mimicry")
	Game.grant_skill("predator", true)
	check(not player.set_form("black_spider"), "a species that was never analysed cannot be mimicked")
	await tap("form_next")
	check(life.form_id == "giant_bat" and player.in_form(), "the form button takes a recorded form")
	check(not player.get_node("Visual/Body").visible and is_instance_valid(player._form_visual), "the slime's shape gives way to the bat's")

	# Holding a form costs magicules: a lot for a weak body, little for a strong one.
	check(is_equal_approx(player.form_upkeep(), 12.0), "a bat form is at the upkeep cap for a 100 EP slime")
	var before := life.magicules
	await seconds(1.0)
	check(before - life.magicules > 10.0, "and drains magicules while held")

	# The form fights with the species' moves, as strongly as the body allows.
	check(is_equal_approx(player.get_power(), sqrt(100.0 / 1200.0)), "a copy is weaker than the original while EP is lower")
	var prey := Creature.create("evil_centipede")
	main.add_child(prey)
	prey.global_position = player.global_position + Vector3(0.0, 0.0, -1.6)
	prey.set_physics_process(false)
	await frames(5)
	var prey_hp := prey.get_vitals().hp
	life.vitals.hp = 30.0
	await tap("attack_light")
	await seconds(1.0)
	var dealt := prey_hp - prey.get_vitals().hp
	check(is_equal_approx(dealt, 12.0 * player.get_power()), "the light button is the bat's bite")
	check(life.vitals.hp > 30.0 + dealt * 0.4, "and the bite drains life like the bat's")
	prey.queue_free()

	# Wings: glide and flap.
	life.magicules = life.max_magicules
	life.stamina = 100.0
	await tap("jump")
	await frames(25)
	Input.action_press("jump")
	await frames(60)
	check(player.velocity.y >= -1.05 and not player.is_on_floor(), "holding jump in the air glides")
	Input.action_release("jump")
	await frames(2)
	var height := player.global_position.y
	await tap("jump")
	await frames(10)
	check(player.global_position.y > height + 0.3 and life.stamina < 100.0, "pressing it again flaps upward for stamina")
	await seconds(2.0)

	# Out of magicules, the form is lost.
	life.magicules = 3.0
	await seconds(1.0)
	check(life.form_id == "" and not player.in_form(), "the form drops when magicules run out")
	check(player.get_node("Visual/Body").visible, "and the slime's own shape returns")
	await seconds(1.0)
	check(spoken().contains("Magicules exhausted"), "the Voice says so")

	# Growth makes forms cheap and strong.
	Game.add_ep(2300)
	life.magicules = life.max_magicules
	player.set_form("giant_bat")
	check(is_equal_approx(player.form_upkeep(), 0.75), "at twice the bat's EP the form costs a sixteenth of the cap")
	check(player.get_power() > 1.4, "and hits harder than the original")

	# Cycling: next form, then back to the slime.
	life.forms.append("tempest_serpent")
	await tap("form_next")
	check(life.form_id == "tempest_serpent", "the form button steps to the next form")
	check(is_equal_approx(player.get_body_radius(), 0.8), "large forms are capped to a body the cave can fit")
	Input.action_press("squeeze")
	await frames(10)
	check(not player.is_squeezed(), "only the slime's own body can squeeze")
	Input.action_release("squeeze")
	await tap("form_next")
	check(life.form_id == "" and not player.in_form(), "past the last form is the slime again")
	Input.action_press("squeeze")
	await frames(10)
	check(player.is_squeezed(), "which can squeeze")
	Input.action_release("squeeze")

	# Death ends the form with the body.
	await frames(20)
	player.set_form("giant_bat")
	Game.die("blade")
	await seconds(Game.REBIRTH_DELAY + 1.0)
	check(Game.life.form_id == "" and not player.in_form() and Game.life.forms.is_empty(),
			"a new life starts in its own shape with no forms")
