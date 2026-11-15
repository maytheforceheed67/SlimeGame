extends Control
## Predator's part of the HUD: the devour prompt with its progress (bottom
## centre) and the analysis queue (right edge).

const QUEUE_ROWS := 5

var _prompt: Label
var _progress: ProgressBar
var _queue_box: VBoxContainer
var _queue_title: Label
var _queue_rows: Array[Label] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.anchor_left = 0.5
	column.anchor_right = 0.5
	column.anchor_top = 0.78
	column.anchor_bottom = 0.78
	column.offset_left = -220.0
	column.offset_right = 220.0
	column.add_theme_constant_override("separation", 4)
	add_child(column)

	_prompt = UiStyle.label(17)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_prompt)
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.step = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0.0, 6.0)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.85, 0.95)
	_progress.add_theme_stylebox_override("background", back)
	_progress.add_theme_stylebox_override("fill", fill)
	column.add_child(_progress)

	_queue_box = VBoxContainer.new()
	_queue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_box.anchor_left = 1.0
	_queue_box.anchor_right = 1.0
	_queue_box.anchor_top = 0.3
	_queue_box.anchor_bottom = 0.3
	_queue_box.offset_left = -20.0
	_queue_box.offset_right = -20.0
	_queue_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_queue_box.add_theme_constant_override("separation", 2)
	add_child(_queue_box)
	_queue_title = UiStyle.label(13, UiStyle.MUTED_COLOR)
	_queue_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_queue_box.add_child(_queue_title)
	for i in QUEUE_ROWS:
		var row := UiStyle.label(13)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_queue_box.add_child(row)
		_queue_rows.append(row)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player == null or Game.life == null or not Game.is_alive():
		_prompt.visible = false
		_progress.visible = false
		_queue_box.visible = false
		return
	_show_prompt(player.predator)
	_show_queue(player.predator)


func _show_prompt(predator: Predator) -> void:
	var thing := predator.candidate
	_prompt.visible = thing != null and Game.can_control()
	_progress.visible = predator.is_devouring()
	if thing == null:
		return
	var verb := "Devour" if predator.has_predator() else "Absorb"
	if thing is Creature and not thing.is_corpse():
		_prompt.text = "Hold [F]  %s alive: %s  (%d%%)" % [verb, thing.display_name(), roundi(predator.living_chance(thing) * 100.0)]
	elif thing is Creature:
		_prompt.text = "Hold [F]  %s: %s (remains)" % [verb, thing.display_name()]
	else:
		_prompt.text = "Hold [F]  %s: %s" % [verb, thing.display_name()]
	_progress.value = predator.progress / maxf(0.01, predator.needed)


func _show_queue(predator: Predator) -> void:
	var queue := Game.life.analysis_queue
	_queue_box.visible = not queue.is_empty()
	if queue.is_empty():
		return
	var slots := predator.analysis_slots()
	_queue_title.text = "Analysis%s" % ("  (linked)" if Game.life.analysis_linked else "")
	for i in QUEUE_ROWS:
		var row := _queue_rows[i]
		row.visible = i < queue.size()
		if i >= queue.size():
			continue
		var entry := queue[i]
		var subject := Database.subject_name(str(entry["kind"]), str(entry["id"]))
		if i < slots:
			row.text = "%s  %s" % [subject, _duration(predator.time_left(entry))]
			row.add_theme_color_override("font_color", UiStyle.ADVISOR_COLOR)
		else:
			row.text = "%s  waiting" % subject
			row.add_theme_color_override("font_color", UiStyle.MUTED_COLOR)


func _duration(seconds: float) -> String:
	if seconds >= 60.0:
		return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	return "%.0fs" % ceilf(seconds)
