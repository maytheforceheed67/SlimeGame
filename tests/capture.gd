extends TestCase
## Developer tool: renders the game and saves screenshots. Needs a display
## (or a virtual one) because the headless renderer draws nothing:
##
##   xvfb-run -a godot --rendering-driver opengl3 --path . \
##       res://tests/capture.tscn -- --out=/tmp/shots --stage=birth
##
## Each stage sets up a moment worth looking at and saves <out>/<stage>.png.

var _out_dir := "user://shots"
var _stage := "birth"


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out_dir = argument.trim_prefix("--out=")
		elif argument.begins_with("--stage="):
			_stage = argument.trim_prefix("--stage=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	populate = _stage.begins_with("cave") or _stage.begins_with("veldora") or _stage == "blind" or _stage == "bookmarks"
	sighted = _stage != "blind"
	sequences = _stage == "death"
	await start_main()
	if has_method("_stage_" + _stage):
		await call("_stage_" + _stage)
	else:
		push_error("unknown stage '%s'" % _stage)


func shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(shot_name + ".png")
	image.save_png(path)
	print("saved ", path)


func _stage_birth() -> void:
	await seconds(2.5)
	await shot("birth")


## Spawns a creature in front of the slime, optionally frozen in place.
func spawn(id: String, offset: Vector3, frozen: bool = true) -> Creature:
	var creature := Creature.create(id)
	main.add_child(creature)
	creature.global_position = player.global_position + offset
	creature.home = creature.global_position
	if frozen:
		creature.set_physics_process(false)
	return creature


func _stage_creatures() -> void:
	spawn("giant_bat", Vector3(-5.0, 1.6, -5.0))
	spawn("evil_centipede", Vector3(-2.5, 0.0, -5.0)).rotation.y = 0.9
	spawn("armorsaurus", Vector3(0.5, 0.0, -6.0)).rotation.y = 0.8
	spawn("black_spider", Vector3(4.0, 0.0, -5.5)).rotation.y = -0.6
	spawn("tempest_serpent", Vector3(8.0, 0.0, -8.0)).rotation.y = -0.9
	var hurt := spawn("giant_bat", Vector3(-1.0, 1.0, -2.5))
	hurt.take_hit({"amount": 40.0, "damage_type": "impact", "stagger": 40.0})
	Game.life.vitals.apply_damage(22.0, "blade")
	Game.life.vitals.add_status("poisoned", 6.0, 1.0)
	await seconds(2.5)
	await shot("creatures")


## A slime a little way into a life: Predator, Great Sage, a few gains.
func _kit() -> void:
	Game.grant_skill("predator", true)
	Game.grant_skill("great_sage", true)
	Game.grant_resistance("pain_nullification")
	Game.add_ep(1400)
	for skill_id: String in ["water_blade", "ultra_sound_waves", "drain", "mana_perception"]:
		Game.grant_skill(skill_id)
	Game.life.forms.append("giant_bat")
	Game.life.recipes.append("healing_potion")
	Game.add_item("hipokute_herb", 3)
	Game.add_item("water", 12)
	Game.add_item("magic_ore", 2)
	player.predator.enqueue_analysis("species", "evil_centipede")
	player.predator.enqueue_analysis("item", "magic_ore")
	Game.life.flags["link_offered"] = true


func _stage_sheet() -> void:
	_kit()
	await seconds(4.0)
	main.get_node("HUD/StatusSheet").open()
	await seconds(0.5)
	await shot("sheet")


func _stage_scan() -> void:
	_kit()
	var bat := spawn("giant_bat", Vector3(0.5, 1.2, -5.0))
	bat.take_hit({"amount": 30.0, "damage_type": "impact"})
	var herb := Harvestable.create("hipokute_herb")
	main.add_child(herb)
	herb.global_position = player.global_position + Vector3(-1.2, 0.0, -1.6)
	var ore := Harvestable.create("magic_ore")
	main.add_child(ore)
	ore.global_position = player.global_position + Vector3(2.5, 0.0, -2.5)
	await seconds(5.0)
	player.advisor.scan()
	await seconds(1.5)
	await shot("scan")


## Stands the slime on a map cell looking along `yaw` (0 looks north).
func look_from(row: int, column: int, yaw: float, pitch: float = -0.3) -> void:
	await place_at_cell(row, column)
	player._camera_rig._yaw = yaw
	player._camera_rig._pitch = pitch
	player._camera_rig._apply()
	await seconds(0.5)


func _stage_cave() -> void:
	player._invulnerable = 9999.0
	Game.grant_skill("predator", true)
	Game.grant_skill("great_sage", true)
	for node in get_tree().get_nodes_in_group(Combat.GROUP):
		if node is Creature:
			node.set_physics_process(false)
	await look_from(37, 27, 0.0)
	await shot("cave_birth")
	await look_from(25, 28, 0.0, -0.35)
	await shot("cave_hall")
	await look_from(20, 16, PI * 0.5, -0.25)
	await shot("cave_veldora_chamber")
	await look_from(20, 41, -PI * 0.5, -0.35)
	await shot("cave_lake")
	await look_from(9, 28, 0.0, -0.3)
	await shot("cave_lair")
	await look_from(36, 39, -PI * 0.5, -0.3)
	await shot("cave_grotto")


func _stage_forms() -> void:
	player._invulnerable = 9999.0
	Game.grant_skill("predator", true)
	Game.add_ep(9000)
	for id: String in ["giant_bat", "black_spider", "tempest_serpent"]:
		Game.life.forms.append(id)
	await seconds(4.0)
	for id: String in ["giant_bat", "black_spider", "tempest_serpent"]:
		Game.life.magicules = Game.life.max_magicules
		player.set_form(id)
		await hold("move_left", 20)
		await seconds(0.4)
		await shot("form_" + id)


func _stage_blind() -> void:
	Game.grant_skill("predator", true)
	Game.grant_skill("great_sage", true)
	await seconds(5.0)
	await hold("move_forward", 40)
	await shot("blind")


func _stage_veldora() -> void:
	player._invulnerable = 9999.0
	Game.grant_skill("predator", true)
	player.respawn(main.level.point("VeldoraAudience") + Vector3(4.0, 0.0, 0.0))
	await frames(10)
	player._camera_rig._yaw = PI * 0.5
	player._camera_rig._pitch = -0.12
	player._camera_rig._apply()
	await seconds(6.0)
	await shot("veldora")
	await tap("interact")
	await seconds(2.0)
	var dialogue: DialoguePanel = main.get_node("HUD/DialoguePanel")
	dialogue.advance()
	dialogue.advance()
	await seconds(1.5)
	await shot("veldora_dialogue")


func _stage_death() -> void:
	var death: DeathScreen = main.get_node("HUD/DeathScreen")
	await seconds(8.5)
	await shot("prologue")
	death.confirm()
	await seconds(5.0)
	Game.life.stats = {"devours": 10.0, "scans": 6.0, "analyses": 4.0, "seconds_blind": 80.0, "kills": 2.0, "talks": 3.0}
	Game.die("blade")
	await seconds(1.6)
	await shot("dying")
	await seconds(3.0)
	death.toggle(0)
	death.toggle(2)
	await seconds(0.5)
	await shot("last_thoughts")


# --- Visual overhaul bookmarks -------------------------------------------------
# The eight fixed views docs/VISUAL_STYLE.md asks to be captured after every
# pass, with the renderer's frame statistics for each.

var _stats: Array[Dictionary] = []


## Saves a bookmark screenshot and records draw calls, primitives and frame time.
func mark(bookmark: String) -> void:
	await seconds(0.3)
	var started := Time.get_ticks_usec()
	for i in 20:
		await RenderingServer.frame_post_draw
	var frame_ms := float(Time.get_ticks_usec() - started) / 20000.0
	_stats.append({
		"bookmark": bookmark,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"frame_ms": snappedf(frame_ms, 0.1),
	})
	await shot(bookmark)


func _stage_bookmarks() -> void:
	player._invulnerable = 9999.0
	Game.grant_skill("predator", true)
	Game.grant_skill("great_sage", true)
	Game.life.flags["link_offered"] = true
	for node in get_tree().get_nodes_in_group(Combat.GROUP):
		if node is Creature:
			node.set_physics_process(false)
	await seconds(7.0)
	var rig: CameraRig = player._camera_rig

	await look_from(37, 27, 0.0, -0.3)
	await mark("01_spawn_view")

	rig._arm.spring_length = 2.4
	await look_from(37, 27, 0.7, -0.12)
	await mark("02_slime_closeup")
	rig._arm.spring_length = 6.0

	await look_from(22, 16, PI * 0.5, -0.08)
	await mark("03_veldora_chamber_wide")

	player.respawn(main.level.point("VeldoraAudience") + Vector3(3.0, 0.0, 0.0))
	await frames(20)
	rig._yaw = PI * 0.5
	rig._pitch = -0.12
	rig._apply()
	await tap("interact")
	var dialogue: DialoguePanel = main.get_node("HUD/DialoguePanel")
	await seconds(1.5)
	dialogue.advance()
	dialogue.advance()
	await seconds(1.5)
	await mark("04_veldora_dialogue")
	for i in 12:
		if dialogue.is_open():
			if dialogue.option_texts().is_empty():
				dialogue.advance()
			else:
				dialogue.choose(1)
			await frames(2)
	if main.get_node("HUD/NamePanel").is_open():
		main.get_node("HUD/NamePanel").submit("Mizu", "Tempest")

	await look_from(20, 41, -PI * 0.5, -0.35)
	await mark("05_lake")

	await look_from(37, 27, 0.0, -0.3)
	var bat := spawn("giant_bat", Vector3(0.0, 0.2, -2.2))
	await seconds(6.0)
	await tap("attack_light")
	await frames(9)
	await mark("06_combat_hit")
	bat.queue_free()

	Game.add_ep(1400)
	for skill_id: String in ["water_blade", "ultra_sound_waves"]:
		Game.grant_skill(skill_id)
	Game.life.forms.append("giant_bat")
	Game.add_item("hipokute_herb", 3)
	main.get_node("HUD/StatusSheet").open()
	await mark("07_status_sheet")
	main.get_node("HUD/StatusSheet").close()

	Game.sequences_enabled = true
	Game.life.stats = {"devours": 10.0, "scans": 6.0, "analyses": 4.0, "seconds_blind": 80.0, "kills": 2.0, "talks": 3.0}
	Game.die("blade")
	var death: DeathScreen = main.get_node("HUD/DeathScreen")
	for i in 600:
		if death.is_open():
			break
		await frames(1)
	death.toggle(0)
	death.toggle(2)
	await mark("08_last_thoughts")

	var lines := PackedStringArray(["| Bookmark | Draw calls | Primitives | Objects | Frame ms (software GL) |", "|---|---|---|---|---|"])
	for entry in _stats:
		lines.append("| %s | %d | %d | %d | %.1f |" % [entry["bookmark"], entry["draw_calls"], entry["primitives"], entry["objects"], entry["frame_ms"]])
	var file := FileAccess.open(_out_dir.path_join("frame_stats.md"), FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("\n".join(lines))
