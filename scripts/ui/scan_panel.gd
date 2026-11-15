extends Control
## The advisor's appraisal readout: a small card on the right that lists what
## a scan found, then fades.

const HOLD_TIME := 9.0

var _panel: PanelContainer
var _title: Label
var _body: Label
var _advisor: Advisor
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.panel_box(UiStyle.ADVISOR_COLOR))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.56
	_panel.anchor_bottom = 0.56
	_panel.offset_left = -20.0
	_panel.offset_right = -20.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_panel.add_child(column)
	_title = UiStyle.label(18, UiStyle.ADVISOR_COLOR)
	_body = UiStyle.label(14)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = 260.0
	column.add_child(_title)
	column.add_child(_body)


func _process(_delta: float) -> void:
	if is_instance_valid(_advisor):
		return
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if player != null and player.advisor != null:
		_advisor = player.advisor
		_advisor.scanned.connect(_on_scanned)


func _on_scanned(info: Dictionary) -> void:
	if info.is_empty():
		return
	_title.text = str(info.get("title", ""))
	_body.text = "\n".join(info.get("lines", PackedStringArray()))
	_panel.visible = true
	_panel.modulate.a = 1.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.8)
	_tween.tween_callback(_panel.hide)
