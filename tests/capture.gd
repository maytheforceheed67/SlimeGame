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
