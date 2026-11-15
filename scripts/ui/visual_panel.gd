extends Control
## Live editor for the visual config (debug builds, F4). Every setting in
## data/visual_config.json appears with an editor for its kind; changes apply
## at once. "Save" writes them to user://visual_overrides.json, which is laid
## over the shipped file at start-up; "Reset all" returns to the shipped values.
## While it is open the cursor is free and the body does not take input, so
## typing in the filter cannot walk the slime about; the world keeps running.
## It also works while the world is paused.

const STATS_INTERVAL := 0.5

var _panel: PanelContainer
var _stats: Label
var _filter: LineEdit
var _rows: VBoxContainer
var _row_by_path: Dictionary = {}
var _built := false
var _stats_in := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.screen_box())
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -470.0
	_panel.offset_right = -12.0
	_panel.offset_top = 12.0
	_panel.offset_bottom = -12.0
	_panel.visible = false
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)
	var title := UiStyle.label(18)
	title.text = "Visual settings  (F4)"
	column.add_child(title)
	_stats = UiStyle.label(12, UiStyle.MUTED_COLOR)
	column.add_child(_stats)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	_filter = LineEdit.new()
	_filter.placeholder_text = "filter, e.g. bloom or palette.slime"
	_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter.text_changed.connect(_apply_filter)
	buttons.add_child(_filter)
	buttons.add_child(_button("Save", _save))
	buttons.add_child(_button("Reset all", _reset_all))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 2)
	scroll.add_child(_rows)


func is_open() -> bool:
	return _panel != null and _panel.visible


func open() -> void:
	if _panel == null or _panel.visible:
		return
	if not _built:
		_build_rows()
	_panel.visible = true
	Game.lock_ui(true)


func close() -> void:
	if _panel == null or not _panel.visible:
		return
	_panel.visible = false
	Game.unlock_ui(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_visual_panel"):
		get_viewport().set_input_as_handled()
		if is_open():
			close()
		else:
			open()


func _process(delta: float) -> void:
	if not is_open():
		return
	_stats_in -= delta
	if _stats_in > 0.0:
		return
	_stats_in = STATS_INTERVAL
	_stats.text = "%d fps   %.1f ms   draw calls %d   primitives %s   objects %d" % [
		int(Engine.get_frames_per_second()),
		1000.0 / maxf(1.0, Engine.get_frames_per_second()),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		UiStyle.format_int(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
	]


func _build_rows() -> void:
	_built = true
	for entry in Visual.entries():
		var path := str(entry["path"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var caption := UiStyle.label(13)
		caption.text = path
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.clip_text = true
		row.add_child(caption)
		row.add_child(_editor(path, str(entry["kind"]), entry["value"]))
		row.set_meta("caption", caption)
		_rows.add_child(row)
		_row_by_path[path] = row
	_mark_overrides()


func _editor(path: String, kind: String, current: Variant) -> Control:
	match kind:
		"number":
			var spin := SpinBox.new()
			spin.min_value = -100000.0
			spin.max_value = 10000000.0
			spin.step = 0.001
			spin.allow_greater = true
			spin.allow_lesser = true
			spin.custom_minimum_size.x = 120.0
			spin.value = float(current)
			spin.value_changed.connect(func(new_value: float) -> void: _changed(path, new_value))
			return spin
		"flag":
			var box := CheckBox.new()
			box.button_pressed = bool(current)
			box.toggled.connect(func(pressed: bool) -> void: _changed(path, pressed))
			return box
		"color":
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size = Vector2(120.0, 26.0)
			picker.edit_alpha = false
			picker.color = Color.html(str(current))
			picker.color_changed.connect(func(new_color: Color) -> void:
				_changed(path, "#" + new_color.to_html(false).to_upper()))
			return picker
	var line := LineEdit.new()
	line.custom_minimum_size.x = 120.0
	line.text = str(current)
	line.text_submitted.connect(func(new_text: String) -> void: _changed(path, new_text))
	return line


func _changed(path: String, new_value: Variant) -> void:
	Visual.set_value(path, new_value)
	_mark_overrides()


## Settings that differ from the shipped file are shown in the accent colour.
func _mark_overrides() -> void:
	for path: String in _row_by_path:
		var caption: Label = _row_by_path[path].get_meta("caption")
		caption.add_theme_color_override("font_color",
				UiStyle.BROADCAST_COLOR if Visual.is_overridden(path) else UiStyle.WORLD_COLOR)


func _apply_filter(needle: String) -> void:
	for path: String in _row_by_path:
		_row_by_path[path].visible = needle == "" or path.contains(needle.to_lower())


func _save() -> void:
	Visual.save_overrides()


func _reset_all() -> void:
	Visual.reset()
	for row: Node in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	_row_by_path.clear()
	_build_rows()
	_apply_filter(_filter.text)


func _button(caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
