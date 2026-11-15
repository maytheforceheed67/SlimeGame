extends Control
## Draws what floats over the 3D world: creature nameplates with their health,
## and damage numbers.
##
## A nameplate shows what any onlooker can judge: the name, the letter rank and
## the danger class. Numeric EP appears only for species the advisor has
## appraised in this life (design document, section 7).

const PLATE_RANGE := 30.0
const NUMBER_LIFETIME := 0.9
const BAR_SIZE := Vector2(72.0, 6.0)

## Set false to hide every plate (the sightless opening).
var plates_visible := true

var _numbers: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	Game.hit_landed.connect(_on_hit_landed)


func _process(delta: float) -> void:
	for number in _numbers:
		number["age"] = float(number["age"]) + delta
		number["position"] = (number["position"] as Vector3) + Vector3(0.0, delta * 1.4, 0.0)
	_numbers = _numbers.filter(func(number: Dictionary) -> bool: return float(number["age"]) < NUMBER_LIFETIME)
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if plates_visible and Game.is_sighted():
		for node in get_tree().get_nodes_in_group(Creature.NAMEPLATE_GROUP):
			var creature := node as Creature
			if creature != null:
				_draw_plate(camera, creature)
	for number in _numbers:
		var world: Vector3 = number["position"]
		if camera.is_position_behind(world):
			continue
		var color: Color = number["color"]
		color.a = 1.0 - float(number["age"]) / NUMBER_LIFETIME
		_text(camera.unproject_position(world), str(number["text"]), 18, color)


## How clearly a creature's plate shows: 0 hidden, 1 in plain view. A
## creature behind rock is hidden unless the body senses heat (Heat Source
## Perception), which shows living things through walls, dimly.
func plate_visibility(camera: Camera3D, creature: Creature) -> float:
	var world := creature.global_position + Vector3(0.0, creature.nameplate_height(), 0.0)
	var distance := camera.global_position.distance_to(world)
	if distance > PLATE_RANGE:
		return 0.0
	var fade := clampf((PLATE_RANGE - distance) / 6.0, 0.0, 1.0)
	if Combat.has_line_of_sight(creature, camera.global_position, creature.get_aim_origin()):
		return fade
	if creature.is_corpse() or distance > _heat_sense_range():
		return 0.0
	return fade * 0.55


## Range of the body's heat sense, or 0 without one.
func _heat_sense_range() -> float:
	var reach := 0.0
	if Game.life == null:
		return reach
	for skill_id in Game.life.skills:
		var passive: Variant = Database.get_skill(skill_id).get("passive")
		if passive is Dictionary and str(passive.get("sense", "")) == "heat":
			reach = maxf(reach, float(passive.get("sense_range", 0.0)))
	return reach


func _draw_plate(camera: Camera3D, creature: Creature) -> void:
	var world := creature.global_position + Vector3(0.0, creature.nameplate_height(), 0.0)
	if camera.is_position_behind(world):
		return
	var alpha := plate_visibility(camera, creature)
	if alpha <= 0.0:
		return
	var at := camera.unproject_position(world)

	if creature.is_corpse():
		_text(at, "%s (remains)" % creature.display_name(), 13, Color(UiStyle.MUTED_COLOR, alpha))
		return

	var rank := creature.get_rank()
	var parts := PackedStringArray(["Rank " + Database.rank_name(rank)])
	var danger := Database.danger_class_name(str(rank.get("danger_class", "")))
	if danger != "":
		parts.append(danger)
	# EP is shown for species the advisor appraised in this life, and for
	# species the soul's codex already holds from an earlier one.
	if Game.life != null and (Game.life.appraised.has(creature.creature_id) \
			or Soul.knows("species", creature.creature_id)):
		parts.append("%s EP" % UiStyle.format_int(creature.get_ep()))

	_text(at - Vector2(0.0, 34.0), creature.display_name(), 15, Color(UiStyle.WORLD_COLOR, alpha))
	_text(at - Vector2(0.0, 17.0), "  ·  ".join(parts), 12, Color(UiStyle.MUTED_COLOR, alpha))
	if creature.is_staggered():
		_text(at - Vector2(0.0, 52.0), "Staggered", 13, Color(UiStyle.BROADCAST_COLOR, alpha))

	var vitals := creature.get_vitals()
	if vitals.hp < vitals.max_hp:
		var corner := at - Vector2(BAR_SIZE.x * 0.5, 8.0)
		draw_rect(Rect2(corner - Vector2.ONE, BAR_SIZE + Vector2.ONE * 2.0), Color(0.0, 0.0, 0.0, 0.7 * alpha))
		draw_rect(Rect2(corner, Vector2(BAR_SIZE.x * vitals.fraction(), BAR_SIZE.y)), Color(0.85, 0.3, 0.3, alpha))


## Draws outlined text centred on `at`.
func _text(at: Vector2, text: String, font_size: int, color: Color) -> void:
	var width := 360.0
	var corner := at - Vector2(width * 0.5, 0.0)
	draw_string_outline(_font, corner, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color(0.0, 0.0, 0.0, color.a * 0.85))
	draw_string(_font, corner, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


func _on_hit_landed(world_position: Vector3, amount: float, _damage_type_id: String, on_player: bool) -> void:
	var text := str(int(round(amount))) if amount >= 0.5 else "no effect"
	_numbers.append({
		"position": world_position + Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3)),
		"text": text,
		"color": UiStyle.WARNING_COLOR if on_player else UiStyle.WORLD_COLOR,
		"age": 0.0,
	})
