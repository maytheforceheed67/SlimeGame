extends CanvasLayer
## HUD root. The panels are separate scripts on the child nodes; this script
## owns the controls hint, and the plain fade used when the death sequence is
## switched off (tests).

@onready var _veil: WorldVeil = $Veil

var _veil_tween: Tween


func _ready() -> void:
	_build_controls_hint()
	Game.life_ended.connect(_on_life_ended)
	Game.life_began.connect(_on_life_began)


func _on_life_ended(_ended_life: LifeState, _damage_type_id: String) -> void:
	if not Game.sequences_enabled:
		_fade_veil(0.8, Game.REBIRTH_DELAY * 0.6)


func _on_life_began(_new_life: LifeState) -> void:
	if not Game.sequences_enabled:
		_fade_veil(0.0, 1.2)


func _fade_veil(darkness: float, duration: float) -> void:
	if _veil_tween != null:
		_veil_tween.kill()
	_veil_tween = create_tween()
	_veil_tween.tween_property(_veil, "darkness", darkness, duration)


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
