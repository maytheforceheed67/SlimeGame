class_name CreatureVisual
extends Node3D
## Original placeholder bodies assembled from primitives. A creature's
## "model" record picks the builder and its colours; the same visual is reused
## for the player's Mimicry forms. Forward is -Z; the feet are at y = 0.
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
var _materials: Array[StandardMaterial3D] = []
var _flash := 0.0
var _dead := false
var _body_material: StandardMaterial3D
var _accent_material: StandardMaterial3D


## Builds the body. `mimic` tints it toward the slime's colour and makes it
## slightly translucent, so a mimicked form still reads as the player.
func build(model: Dictionary, mimic: bool = false) -> void:
	for child in get_children():
		child.queue_free()
	_segments.clear()
	_wings.clear()
	_legs.clear()
	_materials.clear()
	_kind = str(model.get("kind", "blob"))
	_size = float(model.get("size", 1.0))

	var color := Color(str(model.get("color", "5cc7db")))
	var accent := Color(str(model.get("accent", "ffffff")))
	if mimic:
		color = color.lerp(Color(0.36, 0.78, 0.86), 0.45)
	_body_material = _material(color, mimic)
	_accent_material = _material(accent, false)
	_accent_material.emission_enabled = true
	_accent_material.emission = accent
	_accent_material.emission_energy_multiplier = 1.6

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
		_body_material.emission_energy_multiplier = _flash * 3.0
		if _flash == 0.0:
			_body_material.emission_enabled = false


## Brief white flash when struck.
func flash() -> void:
	_flash = 1.0
	_body_material.emission_enabled = true
	_body_material.emission = Color(1.0, 1.0, 1.0)


## Tints the body while staggered so the devour window is readable.
func set_staggered(staggered: bool) -> void:
	_accent_material.emission = Color(1.0, 0.9, 0.3) if staggered else _accent_material.albedo_color


## Collapses and darkens the body into remains.
func set_dead() -> void:
	_dead = true
	_body_material.emission_enabled = false
	_body_material.albedo_color = _body_material.albedo_color.darkened(0.55)
	_accent_material.emission_enabled = false
	_accent_material.albedo_color = _accent_material.albedo_color.darkened(0.7)
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


func _material(color: Color, translucent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.85 if translucent else 1.0)
	material.roughness = 0.75
	if translucent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials.append(material)
	return material


func _add(mesh: Mesh, at: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	(parent if parent != null else self).add_child(instance)
	return instance


func _sphere(at: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := _add(mesh, at, material, parent)
	instance.scale = size
	return instance


func _box(at: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size.abs()
	return _add(mesh, at, material, parent)


func _cone(at: Vector3, radius: float, height: float, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return _add(mesh, at, material, parent)
