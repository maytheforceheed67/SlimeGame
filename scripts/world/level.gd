class_name Level
extends Node3D
## A region's scene: fixed geography plus what one life finds in it.
##
## Geography never changes. Creatures, harvestables and magicule motes are
## placed fresh for each life from that life's seed, so every reincarnation
## is a new branch of the timeline (design document, section 3). The markers
## under Spawns, Harvest and Motes say where things may appear; a marker's
## name up to "__" is the creature or item id.

const MOTE_SCENE: PackedScene = preload("res://scenes/world/magicule_orb.tscn")

## Tests turn this off to get an empty cave.
static var populate_enabled := true

@export var region_id := ""

## How each tagged piece of the cave is drawn ("look" metadata written by
## tools/build_sealed_cave.py).
const LOOKS := {
	"rock": {"kind": "environment", "color": "palette.cave.rock_lit", "shade": "palette.cave.rock_shade", "cap": "palette.cave.rock_cap"},
	"lake_bed": {"kind": "environment", "color": "palette.cave.rock_shade", "shade": "palette.cave.crevice", "cap": "palette.cave.lake_deep"},
}

var _environment: Environment
var _key_light: DirectionalLight3D
var _sighted := true

@onready var _spawned: Node3D = $Spawned


func _ready() -> void:
	# This level's own copy, so darkening it never touches the saved scene.
	_environment = ($WorldEnvironment.environment as Environment).duplicate()
	$WorldEnvironment.environment = _environment
	_key_light = DirectionalLight3D.new()
	_key_light.name = "KeyLight"
	add_child(_key_light)
	var blobs := BlobShadows.new()
	blobs.name = "BlobShadows"
	add_child(blobs)
	_dress()
	Visual.changed.connect(_apply_look)
	_apply_look("")


## Takes tone mapping, bloom, grade, fog and fill light from the visual
## config, now and whenever a value is edited.
func _apply_look(_path: String) -> void:
	WorldLook.apply(_environment, get_viewport())
	WorldLook.apply_key_light(_key_light)
	_sighted = true
	# Applied at once, not on the next frame: the level may be paused.
	_apply_sight()


## Gives the cave's fixed geometry its materials. The scene holds only
## shapes and tags; every colour comes from the visual config.
func _dress() -> void:
	for node in $Rock.get_children():
		var part := node as MeshInstance3D
		if part != null:
			part.material_override = Toon.shared(LOOKS.get(str(part.get_meta("look", "rock")), LOOKS["rock"]))
	var water := Toon.veil({"face": "palette.cave.lake_shallow", "face_alpha": "water.near_alpha",
			"edge": "palette.cave.lake_deep", "edge_alpha": "water.far_alpha", "edge_start": "water.edge_start"})
	for lake in $Water.get_children():
		var surface := lake.get_node_or_null("Surface") as MeshInstance3D
		if surface != null:
			surface.material_override = water
			surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for lamp in $Lights.get_children():
		var crystal := lamp.get_node_or_null("Crystal") as MeshInstance3D
		if crystal == null:
			continue
		var color: Color = (lamp as Light3D).light_color
		crystal.mesh = MeshKit.cube()
		crystal.scale = Vector3(0.5, 1.8, 0.5)
		crystal.material_override = Toon.shared({"color": color, "emission": color,
				"emission_energy": "props.crystal_glow", "outline_px": "outline.detail_px", "height": 1.8})


## A sightless body perceives only what is close enough to touch: the world
## beyond a few metres of it is swallowed by darkness.
func _process(_delta: float) -> void:
	_apply_sight()


func _apply_sight() -> void:
	var sighted := Game.is_sighted()
	if sighted and not _sighted:
		WorldLook.apply_fog(_environment)
	elif not sighted:
		var camera := get_viewport().get_camera_3d()
		var player := get_tree().get_first_node_in_group(Player.GROUP) as Node3D
		if camera != null and player != null:
			var reach := camera.global_position.distance_to(player.global_position)
			WorldLook.apply_fog(_environment, reach + 1.0)
	_sighted = sighted


func spawn_position() -> Vector3:
	return point("SpawnPoint")


## World position of a named marker under Points.
func point(marker_name: String) -> Vector3:
	var marker := get_node_or_null("Points/" + marker_name) as Node3D
	return marker.global_position if marker != null else global_position


## Removes everything placed for the previous life.
func clear() -> void:
	for child in _spawned.get_children():
		child.queue_free()


## Places this life's creatures, harvestables and motes.
func populate(life: LifeState) -> void:
	clear()
	if not populate_enabled:
		return
	_place_fixtures()
	var region := Database.get_region(region_id)
	var rules: Dictionary = region.get("spawn", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = life.world_seed

	for marker in $Spawns.get_children():
		var creature_id := str(marker.name).get_slice("__", 0)
		var certain: bool = Database.get_creature(creature_id).get("boss", false)
		if certain or rng.randf() < float(rules.get("creature_chance", 1.0)):
			_place(Creature.create(creature_id), marker)

	for marker in $Harvest.get_children():
		if rng.randf() < float(rules.get("harvest_chance", 1.0)):
			_place(Harvestable.create(str(marker.name).get_slice("__", 0)), marker)

	var motes: Array[Node] = $Motes.get_children()
	for i in range(motes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := motes[i]
		motes[i] = motes[j]
		motes[j] = held
	var density := Database.density_level(int(region.get("magicule_density", 0)))
	for i in mini(int(rules.get("mote_count", 0)), motes.size()):
		var mote := MOTE_SCENE.instantiate() as MagiculeOrb
		mote.ep_value = int(density.get("ambient_ep", 0))
		_place(mote, motes[i])


## Characters and sounds that belong to the place itself, the same in every
## life: geography and major characters are fixed.
func _place_fixtures() -> void:
	if has_node("Points/VeldoraSpot"):
		var veldora := Veldora.new()
		_spawned.add_child(veldora)
		veldora.global_position = point("VeldoraSpot") - Vector3(0.0, 0.6, 0.0)
		veldora.rotation.y = -PI * 0.5
		var index := 1
		while has_node("Points/VoicePath%d" % index):
			veldora.voice_path.append(point("VoicePath%d" % index))
			index += 1
	if has_node("Points/LakeSound"):
		var drip := SoundSource.new()
		drip.label = "dripping water"
		drip.audible_range = 30.0
		_spawned.add_child(drip)
		drip.global_position = point("LakeSound")


func _place(node: Node3D, marker: Node) -> void:
	_spawned.add_child(node)
	node.global_position = (marker as Node3D).global_position
	if node is Creature:
		node.home = node.global_position
