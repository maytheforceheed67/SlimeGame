class_name CreatureVisual
extends Node3D
## Original placeholder bodies assembled from simple shapes, drawn with the
## toon material and an ink line. A creature's "model" record picks the
## builder and its colours; the same visual is reused for the player's
## Mimicry forms. Forward is -Z; the feet are at y = 0.
##
##   kind "blob"       the slime
##   kind "bat"        body, ears, two flapping wings
##   kind "segmented"  a chain of segments: centipede (legs) or serpent (spikes)
##   kind "quadruped"  a low armoured lizard
##   kind "spider"     abdomen, head, eight legs

var _kind := ""
var _size := 1.0
var _time := 0.0
var _segments: Array[Node3D] = []
var _wings: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _flash := 0.0
var _dead := false
var _body_material: ShaderMaterial
var _accent_material: ShaderMaterial
var _accent := Color.WHITE


## Builds the body. `mimic` tints it toward the slime's colour, so a
## mimicked form still reads as the player. `line` is the ink width in pixels.
func build(model: Dictionary, mimic: bool = false, line: float = 0.0) -> void:
	for child in get_children():
		child.queue_free()
	_segments.clear()
	_wings.clear()
	_legs.clear()
	_kind = str(model.get("kind", "blob"))
	_size = float(model.get("size", 1.0))

	var color := Color(str(model.get("color", "5cc7db")))
	_accent = Color(str(model.get("accent", "ffffff")))
	if mimic:
		color = color.lerp(Visual.color("palette.slime.body"), 0.45)
	# Each creature has materials of its own: they flash and change with it.
	_body_material = Toon.make({"color": color, "outline_px": line, "height": _size})
	_accent_material = Toon.make({"color": _accent, "emission": _accent, "emission_energy": "props.accent_glow",
			"outline_px": "outline.detail_px", "height": _size})

	match _kind:
		"bat":
			_build_bat()
		"segmented":
			_build_segmented(int(model.get("segments", 8)), bool(model.get("legs", false)), bool(model.get("spikes", false)))
		"quadruped":
			_build_quadruped(bool(model.get("plates", false)))
		"spider":
			_build_spider()
		_:
			_sphere(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.8, 1.0) * _size, _body_material)


## Animates the body. `speed` is how fast it is moving, 0 to 1.
func animate(delta: float, speed: float) -> void:
	if _dead:
		return
	_time += delta * (2.0 + speed * 8.0)
	match _kind:
		"bat":
			for i in _wings.size():
				_wings[i].rotation.z = (0.5 * sin(_time * 2.2) + 0.1) * (1.0 if i == 0 else -1.0)
		"segmented":
			for i in _segments.size():
				var sway := sin(_time - i * 0.7) * 0.16 * _size * (0.3 + speed)
				_segments[i].position.x = sway * minf(1.0, i * 0.5)
		"quadruped", "spider":
			for i in _legs.size():
				_legs[i].rotation.x = sin(_time * 1.5 + i * 1.7) * 0.35 * speed

	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		Toon.set_flash(_body_material, _flash)


## Brief white flash when struck.
func flash() -> void:
	_flash = 1.0
	Toon.set_flash(_body_material, 1.0)


## Tints the accents while staggered so the devour window is readable.
func set_staggered(staggered: bool) -> void:
	Toon.update(_accent_material, {"emission": Visual.color("palette.ui.accent_ready") if staggered else _accent})


## Collapses the body into remains and drains its colour toward the cave's
## deepest shade: dark in hue, not grey.
func set_dead() -> void:
	_dead = true
	_flash = 0.0
	Toon.set_flash(_body_material, 0.0)
	var crevice := Visual.color("palette.cave.crevice")
	var body: Color = Toon.options_of(_body_material).get("color", Color.WHITE)
	Toon.update(_body_material, {"color": body.lerp(crevice, 0.55)})
	Toon.update(_accent_material, {"color": _accent.lerp(crevice, 0.7), "emission_energy": 0.0})
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 0.45, 1.1), 0.35)


func _build_bat() -> void:
	var s := _size
	_sphere(Vector3(0.0, 0.0, 0.0), Vector3(0.7, 0.6, 0.9) * s, _body_material)
	_sphere(Vector3(0.0, 0.12, -0.5) * s, Vector3(0.42, 0.4, 0.42) * s, _body_material)
	for side: float in [-1.0, 1.0]:
		_cone(Vector3(0.13 * side, 0.4, -0.5) * s, 0.09 * s, 0.28 * s, _body_material)
		_sphere(Vector3(0.1 * side, 0.16, -0.69) * s, Vector3.ONE * 0.08 * s, _accent_material)
		var pivot := Node3D.new()
		pivot.position = Vector3(0.3 * side, 0.1, 0.0) * s
		add_child(pivot)
		var wing := _box(Vector3(0.65 * side, 0.0, 0.05) * s, Vector3(1.3, 0.04, 0.75) * s, _body_material, pivot)
		wing.rotation.y = 0.15 * side
		_wings.append(pivot)


func _build_segmented(count: int, legs: bool, spikes: bool) -> void:
	var s := _size
	var spacing := 0.62 * s
	for i in count:
		var taper := 1.0 - 0.55 * float(i) / float(maxi(1, count - 1))
		var radius := (0.5 if i > 0 else 0.62) * s * taper
		var holder := Node3D.new()
		holder.position = Vector3(0.0, radius, i * spacing)
		add_child(holder)
		_sphere(Vector3.ZERO, Vector3.ONE * radius * 2.0, _body_material, holder)
		if i == 0:
			for side: float in [-1.0, 1.0]:
				_sphere(Vector3(0.24 * side * s, 0.18 * s, -0.5 * s), Vector3.ONE * 0.16 * s, _accent_material, holder)
		if legs and i > 0:
			for side: float in [-1.0, 1.0]:
				_box(Vector3(radius * 1.2 * side, -radius * 0.4, 0.0), Vector3(radius * 1.1, 0.06 * s, 0.08 * s), _accent_material, holder)
		if spikes and i > 0 and i % 2 == 0:
			_cone(Vector3(0.0, radius * 1.1, 0.0), 0.12 * s * taper, 0.5 * s * taper, _accent_material, holder)
		_segments.append(holder)


func _build_quadruped(plates: bool) -> void:
	var s := _size
	_box(Vector3(0.0, 0.62, 0.1) * s, Vector3(1.15, 0.7, 1.9) * s, _body_material)
	_box(Vector3(0.0, 0.62, -1.15) * s, Vector3(0.7, 0.5, 0.7) * s, _body_material)
	_box(Vector3(0.0, 0.5, 1.45) * s, Vector3(0.45, 0.35, 1.0) * s, _body_material)
	_box(Vector3(0.0, 0.42, 2.2) * s, Vector3(0.25, 0.22, 0.7) * s, _body_material)
	for side: float in [-1.0, 1.0]:
		_sphere(Vector3(0.24 * side, 0.74, -1.48) * s, Vector3.ONE * 0.1 * s, _accent_material)
		for z: float in [-0.55, 0.75]:
			var pivot := Node3D.new()
			pivot.position = Vector3(0.6 * side, 0.45, z) * s
			add_child(pivot)
			_box(Vector3(0.0, -0.22, 0.0) * s, Vector3(0.3, 0.5, 0.34) * s, _body_material, pivot)
			_legs.append(pivot)
	if plates:
		for i in 4:
			_box(Vector3(0.0, 1.04, -0.55 + i * 0.5) * s, Vector3(0.9 - i * 0.08, 0.16, 0.36) * s, _accent_material)


func _build_spider() -> void:
	var s := _size
	_sphere(Vector3(0.0, 0.75, 0.55) * s, Vector3(1.25, 1.0, 1.45) * s, _body_material)
	_sphere(Vector3(0.0, 0.62, -0.5) * s, Vector3(0.8, 0.6, 0.8) * s, _body_material)
	for side: float in [-1.0, 1.0]:
		_sphere(Vector3(0.14 * side, 0.74, -0.86) * s, Vector3.ONE * 0.12 * s, _accent_material)
		_sphere(Vector3(0.3 * side, 0.68, -0.78) * s, Vector3.ONE * 0.08 * s, _accent_material)
		for i in 4:
			var pivot := Node3D.new()
			pivot.position = Vector3(0.3 * side, 0.6, -0.45 + i * 0.3) * s
			pivot.rotation.y = (0.5 - i * 0.33) * side
			add_child(pivot)
			var upper := _box(Vector3(0.5 * side, 0.2, 0.0) * s, Vector3(1.0, 0.09, 0.09) * s, _body_material, pivot)
			upper.rotation.z = 0.5 * side
			var lower := _box(Vector3(1.15 * side, 0.05, 0.0) * s, Vector3(0.09, 0.9, 0.09) * s, _body_material, pivot)
			lower.rotation.z = -0.25 * side
			_legs.append(pivot)


func _add(mesh: Mesh, at: Vector3, size: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.scale = size
	# Eyes, plates, spikes and thin limbs stay out of the shadow map: their
	# shadows are too fine to draw cleanly and each would cost a draw.
	var sides := [size.x, size.y, size.z]
	sides.sort()
	if material == _accent_material or sides[1] < Visual.number("lights.shadow_min_part_size", 0.12):
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent != null else self).add_child(instance)
	return instance


func _sphere(at: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	return _add(MeshKit.sphere(16), at, size, material, parent)


func _box(at: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	return _add(MeshKit.cube(), at, size.abs(), material, parent)


func _cone(at: Vector3, radius: float, height: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	return _add(MeshKit.cone(8), at, Vector3(radius * 2.0, height, radius * 2.0), material, parent)
