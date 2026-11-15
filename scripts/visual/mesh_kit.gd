class_name MeshKit
extends RefCounted
## Meshes prepared for the ink line (docs/VISUAL_STYLE.md, section 3.3).
##
## The outline is a hull pushed outward along each vertex's normal. On a
## mesh with hard edges the faces at a corner have different normals, so the
## hull would split there. with_smooth_normals() stores one averaged normal
## per position in the CUSTOM0 channel, and the outline shader pushes along
## that instead.
##
## The unit shapes below are shared by every stand-in: a part is one of them
## scaled by its node, so the whole game draws from a handful of meshes.

static var _cache: Dictionary = {}


## A sphere of diameter 1.
static func sphere(segments: int = 24) -> ArrayMesh:
	var key := "sphere:%d" % segments
	if not _cache.has(key):
		var source := SphereMesh.new()
		source.radius = 0.5
		source.height = 1.0
		source.radial_segments = segments
		source.rings = maxi(4, segments / 2)
		_cache[key] = with_smooth_normals(source)
	return _cache[key]


## A cube of side 1.
static func cube() -> ArrayMesh:
	if not _cache.has("cube"):
		var source := BoxMesh.new()
		source.size = Vector3.ONE
		_cache["cube"] = with_smooth_normals(source)
	return _cache["cube"]


## A cone of base diameter 1 and height 1, centred on its middle.
static func cone(sides: int = 8) -> ArrayMesh:
	var key := "cone:%d" % sides
	if not _cache.has(key):
		var source := CylinderMesh.new()
		source.top_radius = 0.0
		source.bottom_radius = 0.5
		source.height = 1.0
		source.radial_segments = sides
		source.rings = 1
		_cache[key] = with_smooth_normals(source)
	return _cache[key]


## One mesh made of placed copies of others, so a model built from many
## shapes is a single draw. `parts` is a list of [mesh, transform] pairs
## whose meshes came from this class. The result is kept under `key`: ask
## again with the same key and the parts are not even looked at.
static func merged(key: String, parts: Array) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var smoothed := PackedFloat32Array()
	var indices := PackedInt32Array()
	for part: Array in parts:
		var arrays := (part[0] as Mesh).surface_get_arrays(0)
		var placed: Transform3D = part[1]
		var for_normals := placed.basis.inverse().transposed()
		# The outline pushes along the smoothed normal turned, not stretched.
		var turned := placed.basis.orthonormalized()
		var first := positions.size()
		var part_positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var part_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var part_smoothed: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM0]
		for i in part_positions.size():
			positions.append(placed * part_positions[i])
			normals.append((for_normals * part_normals[i]).normalized())
			var outward := turned * Vector3(part_smoothed[i * 3], part_smoothed[i * 3 + 1], part_smoothed[i * 3 + 2])
			smoothed.append_array([outward.x, outward.y, outward.z])
		if arrays[Mesh.ARRAY_INDEX] != null:
			for index: int in arrays[Mesh.ARRAY_INDEX]:
				indices.append(first + index)
		else:
			for i in part_positions.size():
				indices.append(first + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_CUSTOM0] = smoothed
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
			Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	_cache[key] = result
	return result


## A copy of `mesh` carrying, in CUSTOM0, the average normal of every vertex
## that shares its position. Meshes with a skeleton or blend shapes are
## returned as they are: their outline follows the ordinary normals.
static func with_smooth_normals(mesh: Mesh) -> Mesh:
	if mesh == null or mesh.get_surface_count() == 0:
		return mesh
	var source := mesh as ArrayMesh
	if source != null and source.get_blend_shape_count() > 0:
		return mesh
	var surfaces: Array = []
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if arrays[Mesh.ARRAY_NORMAL] == null or arrays[Mesh.ARRAY_BONES] != null:
			return mesh
		if source != null and source.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			return mesh
		surfaces.append(arrays)

	var result := ArrayMesh.new()
	for surface in surfaces.size():
		var arrays: Array = surfaces[surface]
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var sums: Dictionary = {}
		var keys: Array[Vector3i] = []
		keys.resize(positions.size())
		for i in positions.size():
			var key := Vector3i((positions[i] * 4096.0).round())
			keys[i] = key
			sums[key] = (sums.get(key, Vector3.ZERO) as Vector3) + normals[i]
		var smoothed := PackedFloat32Array()
		smoothed.resize(positions.size() * 3)
		for i in positions.size():
			var average: Vector3 = sums[keys[i]]
			average = average.normalized() if average.length_squared() > 0.000001 else normals[i]
			smoothed[i * 3] = average.x
			smoothed[i * 3 + 1] = average.y
			smoothed[i * 3 + 2] = average.z
		arrays[Mesh.ARRAY_CUSTOM0] = smoothed
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
				Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		result.surface_set_material(surface, mesh.surface_get_material(surface))
	return result
