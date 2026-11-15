extends Control
## Developer overlay and cheat keys. Debug builds only; a release export hides
## the overlay and ignores the keys.
##
##   F3  show / hide          1  +500 EP          2  double EP
##   3   Voice test           4  die (next cause) 5  erase the soul's memory

const REFRESH_INTERVAL := 0.25

var _panel: PanelContainer
var _label: Label
var _refresh_in := 0.0
var _next_cause := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not OS.is_debug_build():
		visible = false
		set_process(false)
		set_process_unhandled_input(false)
		return

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.panel_box())
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -20.0
	_panel.offset_right = -20.0
	_panel.offset_top = 20.0
	_panel.offset_bottom = 20.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)

	_label = UiStyle.label(13)
	_panel.add_child(_label)


func _process(delta: float) -> void:
	_refresh_in -= delta
	if _refresh_in > 0.0 or not _panel.visible:
		return
	_refresh_in = REFRESH_INTERVAL
	_label.text = _build_text()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		_panel.visible = not _panel.visible
	elif event.is_action_pressed("debug_add_ep"):
		Game.add_ep(500, "debug")
	elif event.is_action_pressed("debug_double_ep"):
		if Game.life != null:
			Game.add_ep(maxi(Game.life.ep, 1), "debug")
	elif event.is_action_pressed("debug_voice_test"):
		_voice_test()
	elif event.is_action_pressed("debug_die"):
		_die()
	elif event.is_action_pressed("debug_erase_soul"):
		_erase_soul()


## One key exercises all three channels: a Yes/No prompt, then a world
## broadcast on Yes or an advisor line on No.
func _voice_test() -> void:
	if Voice.is_confirm_open():
		return
	if await Voice.confirm("debug_confirm"):
		Voice.broadcast("debug_broadcast")
	else:
		Voice.advise("debug_advisor")


func _die() -> void:
	var causes: Array = Database.damage_types.keys()
	if causes.is_empty() or not Game.is_alive():
		return
	Game.die(str(causes[_next_cause % causes.size()]))
	_next_cause += 1


func _erase_soul() -> void:
	if Voice.is_confirm_open():
		return
	if await Voice.confirm("debug_erase_confirm"):
		Soul.erase()
		Voice.say("debug_soul_erased")


func _build_text() -> String:
	var lines := PackedStringArray()
	lines.append("DEBUG   F3 hide   %d fps" % int(Engine.get_frames_per_second()))

	var life := Game.life
	if life != null:
		var rank := Database.rank_for_ep(life.ep)
		lines.append("")
		lines.append("Life %d   seed %d   %s" % [life.life_number, life.world_seed, "alive" if life.alive else "dead"])
		lines.append("Race %s   stage %d   origin %s" % [life.race_id, life.stage_index, life.origin_id])
		lines.append("Region %s" % life.region_id)
		lines.append("EP %s   rank %s" % [UiStyle.format_int(life.ep), Database.rank_name(rank)])
		lines.append("Skills: %s" % _joined(life.skills))
		lines.append("Resistances: %s" % _joined(life.resistances))

	lines.append("")
	lines.append("Soul: %d lives lived, %d arts, next birth grants %s" % [
		Soul.lives_lived, Soul.arts.size(), _joined(Soul.birth_grants.get("resistances", [])),
	])
	lines.append("Data: " + Database.summary())
	for message in Database.problems:
		lines.append("DATA PROBLEM  " + message)

	var causes: Array = Database.damage_types.keys()
	var next_cause := "-" if causes.is_empty() else str(causes[_next_cause % causes.size()])
	lines.append("")
	lines.append("1  +500 EP        2  double EP")
	lines.append("3  Voice test     4  die (%s)" % next_cause)
	lines.append("5  erase the soul's memory")
	return "\n".join(lines)


func _joined(ids: Array) -> String:
	if ids.is_empty():
		return "none"
	return ", ".join(PackedStringArray(ids))
