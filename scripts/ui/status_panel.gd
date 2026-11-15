extends Control
## Top-left nameplate for the player: form, letter rank, danger class, life.
##
## Numeric EP is deliberately absent. The design shows it only once the player
## has an appraisal skill or the capital's analysis facility; until then the
## number is visible in the debug overlay only.

var _form_label: Label
var _rank_label: Label
var _life_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_box())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(20.0, 20.0)
	add_child(panel)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)

	_form_label = UiStyle.label(22)
	_rank_label = UiStyle.label(17)
	_life_label = UiStyle.label(14, UiStyle.MUTED_COLOR)
	column.add_child(_form_label)
	column.add_child(_rank_label)
	column.add_child(_life_label)

	Game.life_began.connect(_on_life_began)
	Game.ep_changed.connect(_on_ep_changed)
	_refresh()


func _on_life_began(_new_life: LifeState) -> void:
	_refresh()


func _on_ep_changed(_ep: int, _delta: int) -> void:
	_refresh()


func _refresh() -> void:
	var life := Game.life
	if life == null:
		_form_label.text = "—"
		_rank_label.text = ""
		_life_label.text = ""
		return

	var rank := Database.rank_for_ep(life.ep)
	var parts := PackedStringArray(["Rank " + Database.rank_name(rank)])
	var danger := Database.danger_class_name(str(rank.get("danger_class", "")))
	if danger != "":
		parts.append(danger)
	var informal := Database.informal_label_for_ep(life.ep)
	if informal != "":
		parts.append(informal)

	_form_label.text = Database.stage_name(life.race_id, life.stage_index)
	_rank_label.text = "  ·  ".join(parts)
	_life_label.text = "Life %d" % life.life_number
