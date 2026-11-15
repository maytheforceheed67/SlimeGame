class_name NamePanel
extends Control
## Asks for the two names exchanged with Veldora: a family name the player
## offers for both of them, and the name the player's body receives.
##
##   var names: Array = await name_panel.ask()    # [given, family]

const GROUP := "name_panel"
const MAX_LENGTH := 16
const GIVEN_SUGGESTIONS: Array[String] = ["Lumen", "Sora", "Mizu", "Aoi", "Ren", "Kiri", "Nagi", "Haru"]
const DEFAULT_FAMILY := "Tempest"

signal _answered(given: String, family: String)

var _panel: PanelContainer
var _family_edit: LineEdit
var _given_edit: LineEdit
var _open := false


func _ready() -> void:
	add_to_group(GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.screen_box())
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -230.0
	_panel.offset_right = 230.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var title := UiStyle.label(20, UiStyle.BROADCAST_COLOR)
	title.text = "An exchange of names"
	column.add_child(title)
	_family_edit = _field(column, "The name you offer for both of you")
	_given_edit = _field(column, "The name he gives you")
	var confirm := Button.new()
	confirm.text = "Seal it  [Enter]"
	confirm.custom_minimum_size = Vector2(0.0, 36.0)
	confirm.pressed.connect(_submit_fields)
	column.add_child(confirm)
	_family_edit.text_submitted.connect(func(_text: String) -> void: _given_edit.grab_focus())
	_given_edit.text_submitted.connect(func(_text: String) -> void: _submit_fields())


func is_open() -> bool:
	return _open


## Opens the panel and waits for the names: [given name, family name].
func ask() -> Array:
	_open = true
	Game.ui_locks += 1
	_family_edit.text = DEFAULT_FAMILY
	_given_edit.text = GIVEN_SUGGESTIONS[randi() % GIVEN_SUGGESTIONS.size()]
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_given_edit.grab_focus()
	_given_edit.select_all()
	var names: Array = await _answered
	return names


## Closes the panel with these names. Empty names fall back to defaults.
func submit(given: String, family: String) -> void:
	if not _open:
		return
	given = _clean(given)
	family = _clean(family)
	if given == "":
		given = GIVEN_SUGGESTIONS[0]
	if family == "":
		family = DEFAULT_FAMILY
	_open = false
	Game.ui_locks = maxi(0, Game.ui_locks - 1)
	_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_answered.emit(given, family)


func _submit_fields() -> void:
	submit(_given_edit.text, _family_edit.text)


func _clean(text: String) -> String:
	return text.strip_edges().replace("\n", " ").left(MAX_LENGTH)


func _field(column: VBoxContainer, caption: String) -> LineEdit:
	var label := UiStyle.label(13, UiStyle.MUTED_COLOR)
	label.text = caption
	column.add_child(label)
	var edit := LineEdit.new()
	edit.max_length = MAX_LENGTH
	edit.custom_minimum_size = Vector2(0.0, 34.0)
	column.add_child(edit)
	return edit
