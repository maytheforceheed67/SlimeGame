extends Node
## The asset manager (autoload "Assets"). Every model the game shows is asked
## for here by id; data/asset_manifest.json says where it comes from.
##
##   var body := Assets.instantiate("giant_bat")
##
## If the manifest names a file and the file is there, a copy of it is
## returned, scaled to the manifest's height and, unless its entry says
## "toonify": false, given the toon material and an ink line of the entry's
## "outline_px". Otherwise the entry's procedural stand-in is built, so the
## game never shows a hole. A file that is named but missing logs one
## warning, once. "cast_shadow" applies to both.

const MANIFEST_PATH := "res://data/asset_manifest.json"

## id -> manifest entry
var manifest: Dictionary = {}
## One line per asset that fell back to its stand-in.
var warnings: PackedStringArray = PackedStringArray()

var _warned: Dictionary = {}


func _enter_tree() -> void:
	reload()


func reload() -> void:
	manifest = {}
	warnings = PackedStringArray()
	_warned = {}
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("[Assets] %s not found" % MANIFEST_PATH)
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(MANIFEST_PATH)) != OK or not (json.data is Dictionary):
		push_error("[Assets] %s: line %d: %s" % [MANIFEST_PATH, json.get_error_line(), json.get_error_message()])
		return
	for entry: Variant in json.data.get("assets", []):
		if entry is Dictionary and entry.has("id"):
			manifest[str(entry["id"])] = entry


func has_asset(id: String) -> bool:
	return manifest.has(id)


func entry(id: String) -> Dictionary:
	return manifest.get(id, {})


## A fresh copy of an asset. `params` are passed to a procedural stand-in
## (for example {"mimic": true} or {"color": Color}).
func instantiate(id: String, params: Dictionary = {}) -> Node3D:
	var record := entry(id)
	if record.is_empty():
		_warn(id, "'%s' is not in the asset manifest; showing a marker" % id)
		return StandIns.build("missing", id, params)

	var file := str(record.get("file", ""))
	if file != "":
		var loaded := _load_file("res://" + file)
		if loaded != null:
			# The file sits under a holder: the fit is applied to the file's
			# own root, and callers are free to move and scale the holder.
			var holder := Node3D.new()
			holder.name = str(loaded.name)
			holder.add_child(loaded)
			fit_height(loaded, float(record.get("target_height", 0.0)))
			if bool(record.get("toonify", true)):
				Toon.dress_model(loaded, {"outline_px": float(record.get("outline_px", 0.0)),
						"height": maxf(float(record.get("target_height", 1.0)), 0.1)})
			_set_cast_shadow(holder, bool(record.get("cast_shadow", true)))
			return holder
		_warn(id, "'%s': %s is missing or unreadable; using its stand-in" % [id, file])

	var placeholder: Dictionary = record.get("placeholder", {})
	var stand_in_params := params.duplicate()
	stand_in_params["outline_px"] = float(record.get("outline_px", 0.0))
	var stand_in := StandIns.build(str(placeholder.get("builder", "missing")), id, stand_in_params)
	if not bool(record.get("cast_shadow", true)):
		_set_cast_shadow(stand_in, false)
	return stand_in


## Scales a model so it stands `target_height` metres tall and rests on
## y = 0. Does nothing for a height of zero or a model with no meshes.
func fit_height(model: Node3D, target_height: float) -> void:
	if target_height <= 0.0:
		return
	var bounds := _bounds(model, Transform3D.IDENTITY)
	if bounds.size.y <= 0.0001:
		return
	var factor := target_height / bounds.size.y
	model.scale *= factor
	model.position.y -= bounds.position.y * factor


func _set_cast_shadow(node: Node, casts: bool) -> void:
	var geometry := node as GeometryInstance3D
	if geometry != null:
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_set_cast_shadow(child, casts)


func _load_file(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	return scene.instantiate() as Node3D


## Bounding box of every mesh under `node`, in the space of the model root.
func _bounds(node: Node, to_root: Transform3D) -> AABB:
	var total := AABB()
	var found := false
	if node is VisualInstance3D:
		total = to_root * (node as VisualInstance3D).get_aabb()
		found = true
	for child in node.get_children():
		var child_to_root := to_root
		if child is Node3D:
			child_to_root = to_root * (child as Node3D).transform
		var child_bounds := _bounds(child, child_to_root)
		if child_bounds.size == Vector3.ZERO and child_bounds.position == Vector3.ZERO:
			continue
		total = child_bounds if not found else total.merge(child_bounds)
		found = true
	return total


func _warn(id: String, message: String) -> void:
	if _warned.has(id):
		return
	_warned[id] = true
	warnings.append(message)
	push_warning("[Assets] " + message)
