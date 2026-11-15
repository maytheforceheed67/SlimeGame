class_name DeathScreen
extends Control
## The death sequence (design document, section 5).
##
## When a life ends, time slows and the world's colour drains while the Voice
## of the World names the cause and inscribes it on the soul. Then the last
## thoughts are offered as cards: up to three may be chosen, and each shapes
## the next life. What a card leads to is hidden until the soul has seen it
## happen once. After that comes the dark, and a new birth.
##
## Before the very first life, play_prologue() shows the death that came
## before it: the same screen, with its thoughts read out rather than chosen.

signal _confirmed

const CARD_SIZE := Vector2(206.0, 172.0)

var _veil: WorldVeil
var _panel: PanelContainer
var _title: Label
var _summary: Label
var _grid: GridContainer
var _footer: Label
var _confirm: Button

var _cards: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _chosen: Array[int] = []
var _picks := 3
var _choosing := false
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Game.life_ended.connect(_on_life_ended)


func is_open() -> bool:
	return _panel.visible


func is_busy() -> bool:
	return _busy


## The cards currently on offer.
func offered() -> Array[Dictionary]:
	return _cards


## Selects or deselects a card by its position, up to the allowed number.
func toggle(index: int) -> void:
	if not _choosing or index < 0 or index >= _cards.size():
		return
	if _chosen.has(index):
		_chosen.erase(index)
	elif _chosen.size() < _picks:
		_chosen.append(index)
	_refresh()


## Accepts the current selection (which may be empty).
func confirm() -> void:
	if _panel.visible:
		_confirmed.emit()


## The first death, before the first life: the thoughts are read out and
## granted one by one, with no choice to make.
func play_prologue() -> void:
	_busy = true
	_veil = get_tree().get_first_node_in_group(WorldVeil.GROUP) as WorldVeil
	_veil.darkness = 1.0
	Voice.say("prologue_open")
	await _wait(1.6)

	_cards = Wishes.prologue()
	_show("Last thoughts", "Another world, another body. This is how it ended.", "They are read as they come.", false)
	for i in _cards.size():
		await _wait(0.9)
		_chosen.append(i)
		_refresh(true)
		_announce(_cards[i])
	_footer.text = "What was wished for is what the next life is born with."
	_confirm.text = "Be born  [Enter]"
	_confirm.visible = true
	await _confirmed
	_panel.visible = false

	Soul.birth_grants = {"resistances": []}
	Soul.set_wishes(Wishes.grants(_cards))
	Wishes.remember(_cards, 0)
	_busy = false
	# Not awaited: the caller starts the first life at once, and the dark
	# lifts on it.
	_fade(0.0, 1.0, 0.0, 0.0, 1.5)


func _on_life_ended(ended_life: LifeState, damage_type_id: String) -> void:
	if Game.sequences_enabled and not _busy:
		_run(ended_life, damage_type_id)


func _run(ended_life: LifeState, cause: String) -> void:
	_busy = true
	_veil = get_tree().get_first_node_in_group(WorldVeil.GROUP) as WorldVeil
	# 1. Time slows and colour drains.
	Engine.time_scale = Database.tune("death", "slow_motion_scale", 0.25)
	await _fade(0.0, 0.0, 1.0, 0.4, 2.5)
	Engine.time_scale = 1.0
	get_tree().paused = true

	# 2. The imprint of the cause was announced by Game.die(); 3. last thoughts.
	Voice.say("last_thoughts")
	_cards = Wishes.offer(ended_life, cause)
	_picks = int(Database.tune("death", "picks", 3.0))
	var rank := Database.rank_name(Database.rank_for_ep(ended_life.ep))
	var summary := "Life %d ended as a rank %s %s.  Devoured %d,  analysed %d,  slain %d." % [
		ended_life.life_number, rank, Database.stage_name(ended_life.race_id, ended_life.stage_index),
		int(ended_life.stats.get("devours", 0.0)), int(ended_life.stats.get("analyses", 0.0)),
		int(ended_life.stats.get("kills", 0.0)),
	]
	_show("Last thoughts", summary, "", true)
	await _confirmed
	_panel.visible = false
	_choosing = false

	var chosen: Array[Dictionary] = []
	for index in _chosen:
		chosen.append(_cards[index])
		_announce(_cards[index])
	await _fade(1.0, 0.4, 1.0, 1.0, 1.4)

	# 4. Rebirth.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.reincarnate(chosen)
	await _fade(1.0, 1.0, 0.0, 0.0, 1.6)
	_busy = false


func _announce(card: Dictionary) -> void:
	if str(card.get("result", {}).get("kind", "nothing")) == "nothing":
		Voice.say("wish_nothing")
	else:
		Voice.say("wish_result", {"result": Wishes.describe(card).get_slice("\n", 0)})


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _confirm.visible:
			confirm()
	elif event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < _cards.size():
			get_viewport().set_input_as_handled()
			toggle(index)


# --- Interface -----------------------------------------------------------------

func _build() -> void:
	# Centred in the screen below a strip left clear for the Voice's lines.
	# A CenterContainer re-fits the panel whenever its cards change.
	var frame := CenterContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_top = 120.0
	frame.offset_bottom = -30.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.screen_box())
	_panel.custom_minimum_size.x = 920.0
	_panel.visible = false
	frame.add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	_title = UiStyle.label(22)
	_summary = UiStyle.label(14, UiStyle.MUTED_COLOR)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	column.add_child(_summary)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(_grid)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	_footer = UiStyle.label(14, UiStyle.MUTED_COLOR)
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_footer)
	_confirm = Button.new()
	_confirm.custom_minimum_size = Vector2(180.0, 38.0)
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.pressed.connect(confirm)
	row.add_child(_confirm)


func _show(title: String, summary: String, footer: String, choosing: bool) -> void:
	_title.text = title
	_summary.text = summary
	_footer.text = footer
	_choosing = choosing
	_chosen.clear()
	_buttons.clear()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i in _cards.size():
		var button := Button.new()
		button.custom_minimum_size = CARD_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(toggle.bind(i))
		_grid.add_child(button)
		_buttons.append(button)
	_confirm.text = "Let go  [Enter]"
	_confirm.visible = choosing
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


## Redraws the cards. `reveal_chosen` shows the result of chosen cards even
## when the soul has not seen it before (the prologue reads them aloud).
func _refresh(reveal_chosen: bool = false) -> void:
	for i in _buttons.size():
		var card := _cards[i]
		var picked := _chosen.has(i)
		var result := "?"
		if Wishes.is_known(card) or (reveal_chosen and picked):
			result = Wishes.describe(card)
		_buttons[i].text = "%d.  \"%s\"\n\n%s\n\n%s" % [i + 1, str(card.get("thought", "")), str(card.get("reason", "")), result]
		var box := UiStyle.panel_box(UiStyle.BROADCAST_COLOR if picked else UiStyle.PANEL_BORDER)
		box.bg_color = Color(0.16, 0.13, 0.05, 0.95) if picked else Color(0.05, 0.07, 0.1, 0.95)
		box.set_border_width_all(2 if picked else 1)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			_buttons[i].add_theme_stylebox_override(state, box)
		_buttons[i].add_theme_color_override("font_color", UiStyle.WORLD_COLOR if picked else UiStyle.MUTED_COLOR)
		_buttons[i].add_theme_color_override("font_hover_color", UiStyle.WORLD_COLOR)
	if _choosing:
		_footer.text = "Choose up to %d  (%d chosen).  Press a number or click a card." % [_picks, _chosen.size()]


# --- Timing ------------------------------------------------------------------

## Real-time wait: unaffected by slow motion or by the paused world.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


## Moves the world veil between levels of desaturation and darkness.
func _fade(from_grey: float, from_dark: float, to_grey: float, to_dark: float, seconds: float) -> void:
	var steps := maxi(1, int(seconds / 0.03))
	for i in steps + 1:
		var t := float(i) / float(steps)
		_veil.desaturation = lerpf(from_grey, to_grey, t)
		_veil.darkness = lerpf(from_dark, to_dark, t)
		await _wait(seconds / float(steps))
