extends Control
## The status sheet (Tab): who this body is, what it can do and what it
## carries. Opening it pauses the world.
##
## Left: identity and vitals. Middle: skills by tier, resistances and Arts.
## Right: the Stomach, analysis, Mimicry forms, recipes and what the soul
## remembers. Underlined words are actions (discard a skill, make the link).

const TIER_ORDER: Array[String] = ["manas", "ultimate", "ultimate_gift", "unique", "extra", "common", "intrinsic"]

var _panel: PanelContainer
var _columns: Array[RichTextLabel] = []
var _open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.screen_box())
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 48.0
	_panel.offset_top = 40.0
	_panel.offset_right = -48.0
	_panel.offset_bottom = -40.0
	_panel.visible = false
	add_child(_panel)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	_panel.add_child(rows)
	var title := UiStyle.label(22)
	title.text = "Status"
	rows.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_child(row)
	for i in 3:
		var column := RichTextLabel.new()
		column.bbcode_enabled = true
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_stretch_ratio = 1.0 if i != 1 else 1.4
		column.add_theme_font_size_override("normal_font_size", 14)
		column.add_theme_font_size_override("bold_font_size", 15)
		column.add_theme_color_override("default_color", UiStyle.WORLD_COLOR)
		column.meta_clicked.connect(_on_action)
		row.add_child(column)
		_columns.append(column)

	var hint := UiStyle.label(13, UiStyle.MUTED_COLOR)
	hint.text = "Tab or Esc to close"
	rows.add_child(hint)

	Game.skills_changed.connect(_refresh_if_open)
	Game.stomach_changed.connect(_refresh_if_open)
	Game.life_ended.connect(func(_life: LifeState, _cause: String) -> void: close())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("status_sheet"):
		get_viewport().set_input_as_handled()
		if _open:
			close()
		elif Game.can_control():
			open()
	elif _open and event.is_action_pressed("toggle_mouse"):
		get_viewport().set_input_as_handled()
		close()


func is_open() -> bool:
	return _open


func open() -> void:
	if _open or Game.life == null:
		return
	_open = true
	Game.lock_ui(true)
	get_tree().paused = true
	_panel.visible = true
	refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	Game.unlock_ui(true)
	get_tree().paused = false
	_panel.visible = false


func refresh() -> void:
	var life := Game.life
	if life == null:
		return
	_columns[0].text = _identity(life)
	_columns[1].text = _abilities(life)
	_columns[2].text = _belongings(life)


func _refresh_if_open() -> void:
	if _open:
		refresh()


func _on_action(meta: Variant) -> void:
	var parts := str(meta).split(":")
	if parts.size() == 2 and parts[0] == "discard":
		Game.discard_skill(parts[1])
	elif str(meta) == "link":
		var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
		if player != null:
			player.advisor.link_analysis()
	refresh()


# --- Text ----------------------------------------------------------------------

func _heading(text: String) -> String:
	return "[b][color=#%s]%s[/color][/b]\n" % [UiStyle.ADVISOR_COLOR.to_html(false), text]


func _muted(text: String) -> String:
	return "[color=#%s]%s[/color]" % [UiStyle.MUTED_COLOR.to_html(false), text]


func _identity(life: LifeState) -> String:
	var rank := Database.rank_for_ep(life.ep)
	var danger := Database.danger_class_name(str(rank.get("danger_class", "")))
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var can_appraise := player != null and player.advisor.level() > 0
	var text := _heading("Identity")
	text += "Name: %s\n" % (life.full_name() if life.full_name() != "" else _muted("unnamed"))
	text += "Race: %s\n" % Database.stage_name(life.race_id, life.stage_index)
	if life.form_id != "":
		text += "Form: %s\n" % str(Database.get_creature(life.form_id).get("name", life.form_id))
	text += "Origin: %s\n" % _origin_name(life.origin_id)
	text += "Rank: %s%s\n" % [Database.rank_name(rank), "" if danger == "" else "  ·  " + danger]
	if can_appraise:
		text += "Existence points: %s\n" % UiStyle.format_int(life.ep)
	else:
		text += "Existence points: %s\n" % _muted("unmeasured (needs an appraisal skill)")
	text += "Life: %d\n\n" % life.life_number

	text += _heading("Vitals")
	text += "Health: %d / %d\n" % [ceili(life.vitals.hp), ceili(life.vitals.max_hp)]
	text += "Magicules: %d / %d\n" % [floori(life.magicules), floori(life.max_magicules)]
	var reserved := 0
	for skill_id in life.skills:
		if not life.birth_skills.has(skill_id):
			reserved += Database.capacity_cost(skill_id)
	text += "%s\n" % _muted("%d capacity reserved by skills acquired in this life" % reserved)
	for status_id: String in life.vitals.statuses:
		text += "%s\n" % str(Database.get_status(status_id).get("name", status_id))

	text += "\n" + _heading("The soul remembers")
	text += "Lives lived: %d\n" % Soul.lives_lived
	text += "Species analysed: %d\n" % (Soul.codex.get("species", {}) as Dictionary).size()
	text += "Materials analysed: %d\n" % (Soul.codex.get("materials", {}) as Dictionary).size()
	text += "Arts: %d\n" % Soul.arts.size()
	return text


func _abilities(life: LifeState) -> String:
	var text := ""
	for tier in TIER_ORDER:
		var owned: Array[String] = []
		for skill_id in life.skills:
			if str(Database.get_skill(skill_id).get("category", "")) == tier:
				owned.append(skill_id)
		if owned.is_empty():
			continue
		text += _heading(str(Database.skill_categories.get(tier, {}).get("name", tier)) + "s")
		for skill_id in owned:
			text += _skill_entry(life, skill_id)
		text += "\n"

	text += _heading("Resistances")
	if life.resistances.is_empty():
		text += _muted("none") + "\n"
	for resistance_id in life.resistances:
		text += "%s\n" % Database.resistance_name(resistance_id)

	text += "\n" + _heading("Arts")
	text += _muted("none performed yet") + "\n" if Soul.arts.is_empty() else ""
	for art_id: String in Soul.arts:
		text += "%s\n" % art_id
	return text


func _skill_entry(life: LifeState, skill_id: String) -> String:
	var skill := Database.get_skill(skill_id)
	var text := "[b]%s[/b]" % str(skill.get("name", skill_id))
	if skill_id == life.selected_skill:
		text += "  " + _muted("(bound)")
	if not life.birth_skills.has(skill_id):
		text += "  " + _muted("%d capacity" % Database.capacity_cost(skill_id))
		if str(skill.get("category", "")) != "intrinsic":
			text += "  [url=discard:%s]discard[/url]" % skill_id
	text += "\n"
	if skill.has("summary"):
		text += "%s\n" % _muted(str(skill["summary"]))
	for function: Dictionary in skill.get("sub_functions", []):
		text += "    %s  %s\n" % [str(function.get("name", "")), _muted(str(function.get("game", "")))]
	if skill_id == "great_sage":
		if life.analysis_linked:
			text += "    %s\n" % _muted("Analysis is linked to Parallel Processing.")
		else:
			text += "    [url=link]Link Analysis to Parallel Processing[/url]\n"
	return text


func _belongings(life: LifeState) -> String:
	var text := _heading("Stomach")
	if not life.has_skill("predator"):
		text += _muted("This body has no Stomach.") + "\n"
	elif life.stomach.is_empty() and life.sealed.is_empty():
		text += _muted("empty") + "\n"
	for item_id: String in life.stomach:
		text += "%s  x%d\n" % [Database.item_name(item_id), life.item_count(item_id)]
	for being: String in life.sealed:
		text += "%s  %s\n" % [being, _muted("(held by agreement)")]

	text += "\n" + _heading("Analysis")
	if life.analysis_queue.is_empty():
		text += _muted("nothing queued") + "\n"
	for entry in life.analysis_queue:
		text += "%s\n" % Database.subject_name(str(entry["kind"]), str(entry["id"]))

	text += "\n" + _heading("Mimicry forms")
	if life.forms.is_empty():
		text += _muted("none recorded") + "\n"
	for form_id in life.forms:
		text += "%s\n" % str(Database.get_creature(form_id).get("name", form_id))

	text += "\n" + _heading("Recipes")
	if life.recipes.is_empty():
		text += _muted("none known") + "\n"
	for recipe_id in life.recipes:
		text += "%s\n" % str(Database.get_recipe(recipe_id).get("name", recipe_id))
	return text


func _origin_name(origin_id: String) -> String:
	for origin: Variant in Database.spin.get("origins", []):
		if origin is Dictionary and str(origin.get("id", "")) == origin_id:
			return str(origin.get("name", origin_id))
	return origin_id
