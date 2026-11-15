class_name TestCase
extends Node
## Base for headless test scenes. A test scene's root script extends this and
## implements `_run()`. Run one with:
##
##   godot --headless --fixed-fps 60 --path . res://tests/<name>.tscn
##
## The process exits with code 0 when every check passed, 1 otherwise. Tests
## use their own soul file, so a real save is never touched.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SOUL_PATH := "user://soul_test.json"

## Set true before start_main() to have the level spawn its creatures,
## harvestables and motes; by default tests get an empty cave.
var populate := false
## Set false before start_main() to begin sightless, as a newborn slime does.
## By default tests are given Mana Perception so they can see.
var sighted := true

var main: Node3D
var player: Player

var _checks := 0
var _failures := 0


func _ready() -> void:
	Soul.save_path = TEST_SOUL_PATH
	Soul.erase()
	await _run()
	_release_all_actions()
	print("\n%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


## Overridden by each test.
func _run() -> void:
	pass


func start_main() -> void:
	Level.populate_enabled = populate
	main = MAIN_SCENE.instantiate()
	add_child(main)
	player = main.get_node("Player")
	if sighted:
		Game.grant_skill("mana_perception", true)
	await frames(10)


## Puts the slime at a cell of the cave map (see tools/build_sealed_cave.py).
func place_at_cell(row: int, column: int, height: float = 0.5) -> void:
	player.respawn(Vector3((column - 28) * 2.0 + 1.0, height, (row - 22) * 2.0 + 1.0))
	await frames(20)


func check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("  ok    ", description)
	else:
		_failures += 1
		print("  FAIL  ", description)


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func seconds(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


func hold(action: String, frame_count: int) -> void:
	Input.action_press(action)
	await frames(frame_count)
	Input.action_release(action)


## Presses and releases an action as a real input event, so both polling
## (`is_action_just_pressed`) and `_unhandled_input` handlers see it.
func tap(action: String) -> void:
	_send(action, true)
	await frames(2)
	_send(action, false)
	await frames(1)


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


## Text of every line the Voice has spoken so far, joined for searching.
func spoken() -> String:
	var parts := PackedStringArray()
	for line in Voice.history:
		parts.append(str(line.get("text", "")))
	return "\n".join(parts)


func _release_all_actions() -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)
