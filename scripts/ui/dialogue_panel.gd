class_name DialoguePanel
extends Control
## Runs a conversation from data/dialogues.json and shows it at the bottom of
## the screen. The world keeps moving, but the player's body waits.
##
## Continue with E, Enter, Space or pad A. Choose with W/S or the arrows and
## confirm, or press a number. Options that depend on a memory from an earlier
## life, a skill or a flag are hidden unless they apply.

const GROUP := "dialogue_panel"
const REVEAL_SPEED := 70.0

## A conversation ended. `effects` lists the hooks its last node carried.
signal finished(dialogue_id: String)

var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _option_box: VBoxContainer
var _hint: Label

var _dialogue: Dictionary = {}
var _node: Dictionary = {}
var _options: Array[Dictionary] = []
var _selected := 0
var _on_effect := Callable()
var _open := false
var _life_number_at_start := 0


func _ready() -> void:
	add_to_group(GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Bottom-aligned in a box container, which re-fits the panel to each
	# line: a panel sized by anchors alone would never shrink again.
	var frame := VBoxContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_bottom = -64.0
	frame.alignment = BoxContainer.ALIGNMENT_END
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.panel_box(UiStyle.BROADCAST_COLOR))
	_panel.custom_minimum_size.x = 800.0
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.visible = false
	frame.add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)
	_speaker = UiStyle.label(16, UiStyle.BROADCAST_COLOR)
	_text = UiStyle.label(18)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_option_box = VBoxContainer.new()
	_option_box.add_theme_constant_override("separation", 2)
	_hint = UiStyle.label(12, UiStyle.MUTED_COLOR)
	column.add_child(_speaker)
	column.add_child(_text)
	column.add_child(_option_box)
	column.add_child(_hint)

	Game.life_ended.connect(func(_life: LifeState, _cause: String) -> void: _close())


func is_open() -> bool:
	return _open


## Starts a conversation. `on_effect` is called with each effect name as the
## node that carries it is left. Returns false if it cannot start.
func start(dialogue_id: String, on_effect: Callable = Callable()) -> bool:
	var dialogue := Database.get_dialogue(dialogue_id)
	if _open or dialogue.is_empty() or Game.life == null:
		return false
	if str(dialogue.get("mode", "thought")) == "speech" and not _has_voice():
		return false
	_dialogue = dialogue
	_on_effect = on_effect
	_life_number_at_start = Game.life.life_number
	_open = true
	Game.lock_ui()
	_panel.visible = true
	_speaker.text = str(dialogue.get("speaker", ""))
	if str(dialogue.get("mode", "thought")) == "thought":
		_speaker.text += "  (in thought)"
	_show(str(dialogue.get("start", "")))
	return true


## Reveals the whole line, or moves on: to the next node, the chosen option,
## or the end.
func advance() -> void:
	if not _open:
		return
	if _text.visible_ratio < 1.0:
		_text.visible_ratio = 1.0
		return
	if not _options.is_empty():
		choose(_selected)
		return
	var effects: Array = _node.get("effects", [])
	var next := str(_node.get("next", ""))
	if next != "":
		_run_effects(effects)
		_show(next)
	else:
		var id := str(_dialogue.get("id", ""))
		_close()
		_run_effects(effects)
		finished.emit(id)


func choose(index: int) -> void:
	if not _open or index < 0 or index >= _options.size():
		return
	_text.visible_ratio = 1.0
	_show(str(_options[index].get("next", "")))


## The options currently offered, as their texts.
func option_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for option in _options:
		texts.append(str(option.get("text", "")))
	return texts


func current_text() -> String:
	return _text.text


func _process(delta: float) -> void:
	if _open and _text.visible_ratio < 1.0:
		var length := maxf(1.0, float(_text.text.length()))
		_text.visible_ratio = minf(1.0, _text.visible_ratio + REVEAL_SPEED * delta / length)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		advance()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		get_viewport().set_input_as_handled()
		_select(_selected + 1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		get_viewport().set_input_as_handled()
		_select(_selected - 1)
	elif event is InputEventKey and event.pressed and not event.echo:
		var number: int = event.physical_keycode - KEY_1
		if number >= 0 and number < _options.size():
			get_viewport().set_input_as_handled()
			choose(number)


func _show(node_id: String) -> void:
	var nodes: Dictionary = _dialogue.get("nodes", {})
	_node = nodes.get(node_id, {})
	var life := Game.life
	_text.text = str(_node.get("text", "")).format({"name": life.given_name, "family": life.family_name})
	_text.visible_ratio = 0.0

	_options.clear()
	for option: Dictionary in _node.get("options", []):
		if _allowed(option):
			_options.append(option)
	_selected = 0
	for child in _option_box.get_children():
		_option_box.remove_child(child)
		child.queue_free()
	for i in _options.size():
		var row := UiStyle.label(16)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_option_box.add_child(row)
	_refresh_options()
	_hint.text = "W / S choose   ·   E confirm" if not _options.is_empty() else "E continue"
	if _node.has("remember"):
		Soul.remember(str(_node["remember"]), life.life_number)


func _allowed(option: Dictionary) -> bool:
	var life := Game.life
	var memory := str(option.get("requires_memory", ""))
	if memory != "" and not Soul.remembers_from_before(memory, _life_number_at_start):
		return false
	var skill := str(option.get("requires_skill", ""))
	if skill.begins_with("!"):
		if life.has_skill(skill.substr(1)):
			return false
	elif skill != "" and not life.has_skill(skill):
		return false
	var flag := str(option.get("requires_flag", ""))
	return flag == "" or life.flags.has(flag)


func _select(index: int) -> void:
	if _options.is_empty():
		return
	_selected = posmod(index, _options.size())
	_refresh_options()


func _refresh_options() -> void:
	var rows := _option_box.get_children()
	for i in mini(rows.size(), _options.size()):
		var row := rows[i] as Label
		var chosen := i == _selected
		row.text = "%s %d.  %s" % ["›" if chosen else "  ", i + 1, str(_options[i].get("text", ""))]
		row.add_theme_color_override("font_color", UiStyle.WORLD_COLOR if chosen else UiStyle.MUTED_COLOR)


func _run_effects(effects: Array) -> void:
	if not _on_effect.is_valid():
		return
	for effect: Variant in effects:
		_on_effect.call(str(effect))


func _close() -> void:
	if not _open:
		return
	_open = false
	Game.unlock_ui()
	_panel.visible = false
	_options.clear()


func _has_voice() -> bool:
	for skill_id in Game.life.skills:
		var passive: Variant = Database.get_skill(skill_id).get("passive")
		if passive is Dictionary and passive.get("voice", false):
			return true
	return false
