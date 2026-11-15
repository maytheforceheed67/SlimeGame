class_name InputBindings
extends RefCounted
## Default input map, registered in code so the project runs with no editor
## setup. Move these to Project Settings > Input Map once rebinding is needed.

const DEADZONE := 0.2

## action -> physical keys
const KEYS := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"toggle_mouse": [KEY_ESCAPE],
	"skill_next": [KEY_Q],
	"form_next": [KEY_Z],
	"devour": [KEY_F],
	"scan": [KEY_R],
	"interact": [KEY_E],
	"cling": [KEY_SHIFT],
	"squeeze": [KEY_CTRL, KEY_C],
	"use_potion": [KEY_H],
	"status_sheet": [KEY_TAB],
	"voice_yes": [KEY_Y],
	"voice_no": [KEY_N],
	"debug_overlay": [KEY_F3],
	"debug_add_ep": [KEY_1],
	"debug_double_ep": [KEY_2],
	"debug_voice_test": [KEY_3],
	"debug_die": [KEY_4],
	"debug_erase_soul": [KEY_5],
}

## action -> mouse buttons
const MOUSE_BUTTONS := {
	"attack_light": [MOUSE_BUTTON_LEFT],
	"attack_skill": [MOUSE_BUTTON_RIGHT],
}

## action -> gamepad buttons
const PAD_BUTTONS := {
	"jump": [JOY_BUTTON_A],
	"attack_light": [JOY_BUTTON_X],
	"attack_skill": [JOY_BUTTON_Y],
	"devour": [JOY_BUTTON_B],
	"scan": [JOY_BUTTON_RIGHT_SHOULDER],
	"cling": [JOY_BUTTON_LEFT_SHOULDER],
	"squeeze": [JOY_BUTTON_LEFT_STICK],
	"skill_next": [JOY_BUTTON_DPAD_RIGHT],
	"form_next": [JOY_BUTTON_DPAD_UP],
	"interact": [JOY_BUTTON_DPAD_LEFT],
	"use_potion": [JOY_BUTTON_DPAD_DOWN],
	"status_sheet": [JOY_BUTTON_START],
	"voice_yes": [JOY_BUTTON_A],
	"voice_no": [JOY_BUTTON_B],
}

## action -> [axis, direction]
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	"look_left": [JOY_AXIS_RIGHT_X, -1.0],
	"look_right": [JOY_AXIS_RIGHT_X, 1.0],
	"look_up": [JOY_AXIS_RIGHT_Y, -1.0],
	"look_down": [JOY_AXIS_RIGHT_Y, 1.0],
}

static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true

	for action: String in KEYS:
		_ensure(action)
		for keycode: int in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode as Key
			InputMap.action_add_event(action, key)

	for action: String in MOUSE_BUTTONS:
		_ensure(action)
		for button: int in MOUSE_BUTTONS[action]:
			var click := InputEventMouseButton.new()
			click.button_index = button as MouseButton
			InputMap.action_add_event(action, click)

	for action: String in PAD_BUTTONS:
		_ensure(action)
		for button: int in PAD_BUTTONS[action]:
			var press := InputEventJoypadButton.new()
			press.button_index = button as JoyButton
			InputMap.action_add_event(action, press)

	for action: String in PAD_AXES:
		_ensure(action)
		var motion := InputEventJoypadMotion.new()
		motion.axis = int(PAD_AXES[action][0]) as JoyAxis
		motion.axis_value = float(PAD_AXES[action][1])
		InputMap.action_add_event(action, motion)


static func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
