extends Control
## Top-left nameplate for the player: name and form, letter rank, danger
## class, health, magicules, lingering statuses and the bound skill.
##
## Numeric EP is deliberately absent. The design shows it only once the player
## has an appraisal skill or the capital's analysis facility; the status sheet
## and the debug overlay show the number when that is allowed.

const BAR_WIDTH := 230.0

var _form_label: Label
var _rank_label: Label
var _health_bar: ProgressBar
var _health_label: Label
var _magicule_bar: ProgressBar
var _magicule_label: Label
var _stamina_bar: ProgressBar
var _stamina_label: Label
var _status_label: Label
var _skill_label: Label
var _item_label: Label


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
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)

	_form_label = UiStyle.label(21)
	_rank_label = UiStyle.label(15, UiStyle.MUTED_COLOR)
	column.add_child(_form_label)
	column.add_child(_rank_label)
	_health_bar = _bar(Color(0.82, 0.3, 0.3))
	_health_label = _bar_caption(column, _health_bar)
	_magicule_bar = _bar(Color(0.45, 0.6, 0.95))
	_magicule_label = _bar_caption(column, _magicule_bar)
	_stamina_bar = _bar(Color(0.55, 0.85, 0.45))
	_stamina_label = _bar_caption(column, _stamina_bar)
	_stamina_label.text = "Stamina"
	_status_label = UiStyle.label(13, UiStyle.WARNING_COLOR)
	_skill_label = UiStyle.label(13, UiStyle.MUTED_COLOR)
	_item_label = UiStyle.label(13, UiStyle.MUTED_COLOR)
	column.add_child(_status_label)
	column.add_child(_skill_label)
	column.add_child(_item_label)


func _process(_delta: float) -> void:
	var life := Game.life
	if life == null:
		return
	var rank := Database.rank_for_ep(life.ep)
	var parts := PackedStringArray(["Rank " + Database.rank_name(rank)])
	var danger := Database.danger_class_name(str(rank.get("danger_class", "")))
	if danger != "":
		parts.append(danger)
	var informal := Database.informal_label_for_ep(life.ep)
	if informal != "":
		parts.append(informal)
	parts.append("Life %d" % life.life_number)

	var form := Database.stage_name(life.race_id, life.stage_index)
	if life.form_id != "":
		form = "%s (as %s)" % [form, str(Database.get_creature(life.form_id).get("name", life.form_id))]
	_form_label.text = form if life.full_name() == "" else "%s  ·  %s" % [life.full_name(), form]
	_rank_label.text = "  ·  ".join(parts)

	var vitals := life.vitals
	_health_bar.value = vitals.fraction()
	_health_label.text = "Health  %d / %d" % [ceili(vitals.hp), ceili(vitals.max_hp)]
	_magicule_bar.value = life.magicules / maxf(1.0, life.max_magicules)
	_magicule_label.text = "Magicules  %d / %d" % [floori(life.magicules), floori(life.max_magicules)]

	var stamina_max := Database.tune("vitals", "stamina_max", 100.0)
	_stamina_bar.value = life.stamina / stamina_max
	_stamina_bar.visible = life.stamina < stamina_max - 0.5
	_stamina_label.visible = _stamina_bar.visible

	var afflictions := PackedStringArray()
	for status_id: String in vitals.statuses:
		afflictions.append("%s %ds" % [str(Database.get_status(status_id).get("name", status_id)),
				ceili(float(vitals.statuses[status_id]["remaining"]))])
	_status_label.text = "   ".join(afflictions)
	_status_label.visible = not afflictions.is_empty()

	_skill_label.visible = life.selected_skill != ""
	if life.selected_skill != "":
		_skill_label.text = "Skill: %s" % Database.skill_name(life.selected_skill)

	var carried := PackedStringArray()
	if Game.potions_available() > 0:
		carried.append("Potions %d" % Game.potions_available())
	if life.item_count("water") > 0:
		carried.append("Water %d" % life.item_count("water"))
	_item_label.text = "   ".join(carried)
	_item_label.visible = not carried.is_empty()


func _bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(BAR_WIDTH, 9.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Adds a small caption and the bar under it; returns the caption label.
func _bar_caption(column: VBoxContainer, bar: ProgressBar) -> Label:
	var caption := UiStyle.label(12, UiStyle.MUTED_COLOR)
	column.add_child(caption)
	column.add_child(bar)
	return caption
