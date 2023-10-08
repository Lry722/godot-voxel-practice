static var wireframe_material := preload("res://util/wireframe.tres")

static func create_wireframe_mesh(model: VoxelBlockyModel) -> Mesh:
	var collision_aabbs := model.collision_aabbs
	
	var positions = []
	for aabb in collision_aabbs:
		for x in 2:
			for y in 2:
				for z in 2:
					positions.append(aabb.position + aabb.size * Vector3(x, y, z))
					
	var colors = []
	colors.resize(collision_aabbs.size() * 8)
	colors.fill(Color(1, 1, 1))
	
	var indices = []
	for i in collision_aabbs.size():
		indices.append_array([
		0, 1, 0, 4, 1, 5, 4, 5,
		0, 2, 1, 3, 4, 6, 5, 7,
		2, 3, 2, 6, 7, 3, 7, 6
	].map(func(number): return number + 8 * i))
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(positions)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh
