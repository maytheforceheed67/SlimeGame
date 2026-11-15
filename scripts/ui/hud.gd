extends CanvasLayer
## HUD root. The panels are separate scripts on the child nodes; this script
## owns the veil that darkens the world between death and rebirth, and the
## controls hint.

const VEIL_ALPHA := 0.82

var _veil_tween: Tween

@onready var _veil: ColorRect = $Veil


func _ready() -> void:
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(0.0, 0.0, 0.0, 0.0)
	_build_controls_hint()
	Game.life_ended.connect(_on_life_ended)
	Game.life_began.connect(_on_life_began)


func _on_life_ended(_ended_life: LifeState, _damage_type_id: String) -> void:
	_fade_veil(VEIL_ALPHA, Game.REBIRTH_DELAY * 0.6)


func _on_life_began(_new_life: LifeState) -> void:
	_fade_veil(0.0, 1.2)


func _fade_veil(alpha: float, duration: float) -> void:
	if _veil_tween != null:
		_veil_tween.kill()
	_veil_tween = create_tween()
	_veil_tween.tween_property(_veil, "color:a", alpha, duration)


func _build_controls_hint() -> void:
	var hint := UiStyle.label(14, UiStyle.MUTED_COLOR)
	hint.text = "WASD move  ·  Space hop  ·  LMB tackle  ·  RMB skill (Q next)  ·  F devour  ·  E speak  ·  R scan  ·  Z form  ·  H potion  ·  Tab status"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -20.0
	hint.offset_right = -20.0
	hint.offset_top = -16.0
	hint.offset_bottom = -16.0
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint)
