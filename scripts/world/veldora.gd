class_name Veldora
extends Node3D
## Veldora the Storm Dragon, sealed in the cave (design document, sections
## 9.3 and 18, act 1). He calls out to the sightless slime, teaches it Mana
## Perception, exchanges names with it as an equal, and can be carried away,
## seal and all, by agreement.
##
## What happens here is canon; his words (data/dialogues.json) and this
## placeholder body are original to this project. Every life meets him anew:
## the world does not remember the player, though the player may remember him.

const INTERACT_GROUP := "interactable"
const SOUND_GROUP := "sound_source"
const BARRIER_RADIUS := 8.0

## Points his voice seems to come from, leading through the cave to him.
var voice_path: Array[Vector3] = []

var _path_index := 0
var _busy := false
var _taken := false
var _body: Node3D
var _eye_material: StandardMaterial3D


func _ready() -> void:
	add_to_group(INTERACT_GROUP)
	add_to_group(SOUND_GROUP)
	_build_body()
	_build_barrier()


# --- Interactable contract ---------------------------------------------------

func interact_range() -> float:
	return BARRIER_RADIUS + 6.0


func interact_label() -> String:
	return "Speak with Veldora" if Game.is_sighted() else "Answer the voice"


func can_interact() -> bool:
	return not _busy and not _taken


## Opens the conversation that fits how far this life has come with him.
func interact(_player: Player) -> void:
	var panel := get_tree().get_first_node_in_group(DialoguePanel.GROUP) as DialoguePanel
	if panel == null or not can_interact():
		return
	var flags := Game.life.flags
	var dialogue := "veldora_second"
	if not Game.is_sighted():
		dialogue = "veldora_waiting" if flags.has("mana_perception_taught") else "veldora_first"
	elif flags.has("veldora_named"):
		dialogue = "veldora_named"
	Game.count("talks")
	panel.start(dialogue, _on_effect)


# --- Sound source contract ---------------------------------------------------

func sound_label() -> String:
	return "a voice"


func sound_range() -> float:
	return 200.0


func is_audible() -> bool:
	return not _taken


## Where the voice seems to come from for a listener: the next point along
## the way to him, so that following the sound follows the passages.
func sound_position(listener: Vector3) -> Vector3:
	while _path_index < voice_path.size() and listener.distance_to(voice_path[_path_index]) < 5.0:
		_path_index += 1
	if _path_index < voice_path.size():
		return voice_path[_path_index]
	return global_position


# --- Story hooks -------------------------------------------------------------

func _on_effect(effect: String) -> void:
	match effect:
		"teach_mana_perception":
			Game.life.flags["mana_perception_taught"] = true
			Voice.advise("advisor_sense")
		"ask_names":
			_exchange_names()
		"offer_swallow":
			_offer_swallow()


func _exchange_names() -> void:
	var panel := get_tree().get_first_node_in_group(NamePanel.GROUP) as NamePanel
	if panel == null:
		return
	_busy = true
	var life := Game.life
	var names: Array = await panel.ask()
	_busy = false
	if Game.life != life or not life.alive:
		return
	life.given_name = str(names[0])
	life.family_name = str(names[1])
	life.flags["veldora_named"] = true
	Soul.remember("named_with_veldora", life.life_number)
	Game.count("names_received")
	Voice.say("named", {"name": life.full_name()})
	Game.add_ep(int(Database.tune("naming", "veldora_ep_gift", 200.0)), "naming")
	var dialogue := get_tree().get_first_node_in_group(DialoguePanel.GROUP) as DialoguePanel
	if dialogue != null:
		dialogue.start("veldora_named", _on_effect)


func _offer_swallow() -> void:
	_busy = true
	var life := Game.life
	var accepted: bool = await Voice.confirm("veldora_swallow_confirm")
	_busy = false
	if not accepted or Game.life != life or not life.alive or not life.has_skill("predator"):
		return
	_taken = true
	life.sealed.append("Veldora")
	life.flags["veldora_swallowed"] = true
	Soul.remember("carried_veldora", life.life_number)
	Game.count("swallowed_by_agreement")
	Voice.say("veldora_swallowed")
	remove_from_group(INTERACT_GROUP)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Node3D
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE * 0.02, 1.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if player != null:
		tween.tween_property(self, "global_position", player.global_position, 1.4).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


# --- Placeholder body ----------------------------------------------------------

func _build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	var scales := StandardMaterial3D.new()
	scales.albedo_color = Color(0.07, 0.06, 0.1)
	scales.roughness = 0.55
	scales.metallic = 0.3
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.75, 0.6, 0.2)
	trim.emission_enabled = true
	trim.emission = Color(0.9, 0.7, 0.2)
	trim.emission_energy_multiplier = 0.6
	_eye_material = StandardMaterial3D.new()
	_eye_material.albedo_color = Color(1.0, 0.85, 0.3)
	_eye_material.emission_enabled = true
	_eye_material.emission = Color(1.0, 0.8, 0.25)
	_eye_material.emission_energy_multiplier = 4.0

	# Lying coiled, head raised toward whoever stands in front (-Z).
	_sphere(Vector3(0.0, 2.2, 1.5), Vector3(5.5, 4.2, 8.0), scales)
	_sphere(Vector3(0.0, 3.6, -2.6), Vector3(2.6, 2.8, 3.6), scales)
	_sphere(Vector3(0.0, 5.0, -4.4), Vector3(2.0, 2.0, 3.0), scales)
	_box(Vector3(0.0, 5.3, -6.0), Vector3(1.7, 1.3, 2.6), scales)
	_box(Vector3(0.0, 4.9, -7.4), Vector3(1.2, 0.8, 1.2), scales)
	for side: float in [-1.0, 1.0]:
		_sphere(Vector3(0.88 * side, 5.75, -6.6), Vector3(0.3, 0.5, 0.7), _eye_material)
		_cone(Vector3(0.6 * side, 6.6, -5.2), 0.28, 1.8, trim).rotation = Vector3(-0.7, 0.0, 0.25 * side)
		var wing := _box(Vector3(3.6 * side, 4.6, 1.6), Vector3(4.4, 0.16, 5.6), scales)
		wing.rotation = Vector3(0.1, 0.0, 0.9 * side)
		_box(Vector3(2.4 * side, 0.7, -1.6), Vector3(1.1, 1.4, 2.2), scales)
	for i in 5:
		_cone(Vector3(0.0, 4.9 - i * 0.25, -1.6 + i * 1.5), 0.3, 1.2, trim)
	for i in 4:
		var taper := 1.0 - i * 0.2
		_sphere(Vector3(1.4 + i * 1.3, 0.9 * taper, 5.4 + i * 0.4), Vector3(2.0, 1.7, 2.2) * taper, scales)

	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.8, 0.35)
	glow.light_energy = 1.4
	glow.omni_range = 12.0
	glow.position = Vector3(0.0, 5.6, -7.6)
	add_child(glow)


## The Infinity Prison: a shell nothing passes, drawn as a faint sphere.
func _build_barrier() -> void:
	var shell := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = BARRIER_RADIUS
	shape.shape = sphere
	shell.add_child(shape)
	shell.position.y = 1.0
	add_child(shell)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0, 0.1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.4, 0.65, 1.0)
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.rim_enabled = true
	material.rim = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = BARRIER_RADIUS
	mesh.height = BARRIER_RADIUS * 2.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.add_child(instance)


func _add(mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	_body.add_child(instance)
	return instance


func _sphere(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := _add(mesh, at, material)
	instance.scale = size
	return instance


func _box(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(mesh, at, material)


func _cone(at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return _add(mesh, at, material)
