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
	for orb in main.get_node("Orbs").get_children():
		orb.queue_free()
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
