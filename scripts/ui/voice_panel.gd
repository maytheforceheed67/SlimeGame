extends Control
## Shows what the Voice autoload speaks.
##
## The Voice of the World and its broadcasts share the top-centre column. The
## advisor is a different voice, so it gets its own colour and its own corner
## (bottom left). Yes/No questions open a small prompt answered with Y / N, the
## gamepad, or the buttons when the cursor is free.

const MAX_WORLD_LINES := 6
const MAX_ADVISOR_LINES := 4
const REVEAL_TIME := 0.25
const HOLD_TIME := 5.0
const FADE_TIME := 0.8

var _world_column: VBoxContainer
var _advisor_column: VBoxContainer
var _confirm_panel: PanelContainer
var _confirm_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_world_column()
	_build_advisor_column()
	_build_confirm_panel()
	Voice.line_spoken.connect(_on_line_spoken)
	Voice.confirm_opened.connect(_on_confirm_opened)
	Voice.confirm_closed.connect(_on_confirm_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not _confirm_panel.visible:
		return
	if event.is_action_pressed("voice_yes"):
		get_viewport().set_input_as_handled()
		Voice.answer(true)
	elif event.is_action_pressed("voice_no"):
		get_viewport().set_input_as_handled()
		Voice.answer(false)


func _on_line_spoken(line: Dictionary) -> void:
	var channel: int = line.get("channel", Voice.Channel.WORLD)
	var text := str(line.get("text", ""))
	if channel == Voice.Channel.ADVISOR:
		_push(_advisor_column, "›  " + text, UiStyle.ADVISOR_COLOR, 17, HORIZONTAL_ALIGNMENT_LEFT, MAX_ADVISOR_LINES)
	elif channel == Voice.Channel.BROADCAST:
		_push(_world_column, "«  " + text + "  »", UiStyle.BROADCAST_COLOR, 24, HORIZONTAL_ALIGNMENT_CENTER, MAX_WORLD_LINES)
	else:
		_push(_world_column, text, UiStyle.WORLD_COLOR, 19, HORIZONTAL_ALIGNMENT_CENTER, MAX_WORLD_LINES)


func _on_confirm_opened(question: String) -> void:
	_confirm_label.text = question
	_confirm_panel.visible = true


func _on_confirm_closed(_accepted: bool) -> void:
	_confirm_panel.visible = false


## Adds a line to a column: typed out, held, then faded and removed.
func _push(column: VBoxContainer, text: String, color: Color, font_size: int,
		alignment: HorizontalAlignment, limit: int) -> void:
	var label := UiStyle.label(font_size, color)
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.visible_ratio = 0.0
	column.add_child(label)
	while column.get_child_count() > limit:
		var oldest := column.get_child(0)
		column.remove_child(oldest)
		oldest.queue_free()

	var tween := label.create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, REVEAL_TIME)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(label, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(label.queue_free)


func _build_world_column() -> void:
	_world_column = VBoxContainer.new()
	_world_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_column.add_theme_constant_override("separation", 6)
	_world_column.anchor_left = 0.5
	_world_column.anchor_right = 0.5
	_world_column.offset_left = -330.0
	_world_column.offset_right = 330.0
	_world_column.offset_top = 36.0
	_world_column.offset_bottom = 36.0
	add_child(_world_column)


func _build_advisor_column() -> void:
	_advisor_column = VBoxContainer.new()
	_advisor_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_advisor_column.add_theme_constant_override("separation", 4)
	_advisor_column.anchor_top = 1.0
	_advisor_column.anchor_bottom = 1.0
	_advisor_column.offset_left = 24.0
	_advisor_column.offset_right = 544.0
	_advisor_column.offset_top = -48.0
	_advisor_column.offset_bottom = -48.0
	_advisor_column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_advisor_column)


func _build_confirm_panel() -> void:
	_confirm_panel = PanelContainer.new()
	_confirm_panel.add_theme_stylebox_override("panel", UiStyle.panel_box(UiStyle.WORLD_COLOR))
	_confirm_panel.anchor_left = 0.5
	_confirm_panel.anchor_right = 0.5
	_confirm_panel.anchor_top = 0.62
	_confirm_panel.anchor_bottom = 0.62
	_confirm_panel.offset_left = -260.0
	_confirm_panel.offset_right = 260.0
	_confirm_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_confirm_panel.visible = false
	add_child(_confirm_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_confirm_panel.add_child(column)

	_confirm_label = UiStyle.label(20)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_confirm_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	row.add_child(_answer_button("Yes  [Y]", true))
	row.add_child(_answer_button("No  [N]", false))


func _answer_button(caption: String, accepted: bool) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(120.0, 36.0)
	button.pressed.connect(Voice.answer.bind(accepted))
	return button
