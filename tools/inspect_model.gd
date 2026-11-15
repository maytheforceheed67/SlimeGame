extends SceneTree
## Prints what is inside model files, so the asset manifest can be filled in
## from facts: node names, meshes and materials, animation clip names and
## lengths, and the model's size.
##
##   godot --headless --path . --script tools/inspect_model.gd -- file.glb [more files]
##
## Reads .glb, .gltf and .fbx. Paths may be absolute or relative to the
## project folder. Nothing is imported or changed.


func _init() -> void:
	var files := OS.get_cmdline_user_args()
	if files.is_empty():
		print("usage: godot --headless --path . --script tools/inspect_model.gd -- file.glb [more files]")
	for file in files:
		_inspect(file)
	quit()


func _inspect(path: String) -> void:
	print("\n== ", path)
	var document: GLTFDocument = FBXDocument.new() if path.get_extension().to_lower() == "fbx" else GLTFDocument.new()
	var state: GLTFState = FBXState.new() if document is FBXDocument else GLTFState.new()
	var error := document.append_from_file(path, state)
	if error != OK:
		print("   cannot read (error %d)" % error)
		return
	var scene := document.generate_scene(state)
	if scene == null:
		print("   no scene in file")
		return
	var bounds := _bounds(scene, Transform3D.IDENTITY)
	print("   size (x, y, z) in metres: %.2f, %.2f, %.2f   base at y = %.2f" % [bounds.size.x, bounds.size.y, bounds.size.z, bounds.position.y])
	print("   nodes:")
	_print_tree(scene, 2)
	var clips := PackedStringArray()
	for player: Node in scene.find_children("*", "AnimationPlayer", true, false):
		for clip: String in (player as AnimationPlayer).get_animation_list():
			clips.append("%s (%.2f s)" % [clip, (player as AnimationPlayer).get_animation(clip).length])
	print("   animations: ", ", ".join(clips) if not clips.is_empty() else "none")
	scene.free()


func _print_tree(node: Node, depth: int) -> void:
	var note := ""
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := (node as MeshInstance3D).mesh
		var materials := PackedStringArray()
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface)
			materials.append(material.resource_name if material != null and material.resource_name != "" else "unnamed")
		note = "  [%d surface(s): %s]" % [mesh.get_surface_count(), ", ".join(materials)]
	elif node is Skeleton3D:
		note = "  [%d bones]" % (node as Skeleton3D).get_bone_count()
	print("%s%s (%s)%s" % ["   ".repeat(depth), node.name, node.get_class(), note])
	for child in node.get_children():
		_print_tree(child, depth + 1)


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
