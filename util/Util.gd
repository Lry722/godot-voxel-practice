class_name Util

const opposite = {
	'X': 'NX',
	'Y': 'NY',
	'Z': 'NZ',
	'NX': 'X',
	'NY': 'Y',
	'NZ': 'Z',
	'DX': 'DNX',
	'DY': 'DNY',
	'DZ': 'DNZ',
	'DNX': 'DX',
	'DNY': 'DY',
	'DNZ': 'DZ',
}

const orientation_to_vector = {
	'X': Vector3i(1, 0, 0),
	'Y': Vector3i(0, 1, 0),
	'Z': Vector3i(0, 0, 1),
	'NX': Vector3i(-1, 0, 0),
	'NY': Vector3i(0, -1, 0),
	'NZ': Vector3i(0, 0, -1),
	'DX': Vector3i(1, 0, 0),
	'DY': Vector3i(0, 1, 0),
	'DZ': Vector3i(0, 0, 1),
	'DNX': Vector3i(-1, 0, 0),
	'DNY': Vector3i(0, -1, 0),
	'DNZ': Vector3i(0, 0, -1),
}

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
	
static func get_attributes_variants(block : Block) -> Array:
	var attributes = block.attributes

	var result = [block.name]
	if block.attributes.is_empty():
		return result
	
	var stack := []
	stack.resize(attributes.size())
	stack.fill(-1)
	var top := 0
	
	while top >= 0:
		if top == attributes.size():
			var comb = ''
			for i in stack.size():
				comb += block.name + '_' + str(attributes[i][stack[i]])
			result.append(comb)
			top -= 1
		elif attributes[top].size() > stack[top]:
			stack[top] += 1
			if attributes[top].size() == stack[top]:
				stack[top] = -1
				top -= 1
			else:
				top += 1
		else:
			assert(false)
	
	return result
	
static func get_orientation(normal : Vector3i, sight_dir : Vector3, orientation_type : int) -> String:
	if orientation_type == 0:
		return ''
		
	var result := ''
	
	if orientation_type == 2:
		sight_dir.y = 0
		match sight_dir.abs().max_axis_index():
			Vector3.AXIS_X:
				result = '_X'
			Vector3i.AXIS_Z:
				result = '_Z'
	elif orientation_type == 3:
		match normal.abs().max_axis_index():
			Vector3.AXIS_X:
				result = '_X'
			Vector3.AXIS_Y:
				result = '_Y'
			Vector3i.AXIS_Z:
				result = '_Z'
	elif orientation_type == 4:
		sight_dir.y = 0
		match sight_dir.abs().max_axis_index():
			Vector3.AXIS_X:
				if sight_dir.x < 0:
					result = '_NX'
				else:
					result = '_X'
			Vector3.AXIS_Z:
				if sight_dir.z < 0:
					result = '_NZ'
				else:
					result = '_Z'
	elif orientation_type == 6:
		match normal.max_axis_index():
			Vector3.AXIS_X:
				if normal.x < 0:
					result = '_NX'
				else:
					result = '_X'
			Vector3.AXIS_Y:
				if normal.y < 0:
					result = '_NY'
				else:
					result = '_Y'
			Vector3.AXIS_Z:
				if normal.z < 0:
					result = '_NZ'
				else:
					result = '_Z'
	elif orientation_type == 8:
		if normal.y == 1:
			result = '_'
		else:
			result = '_D'
		sight_dir.y = 0
		match sight_dir.abs().max_axis_index():
			Vector3.AXIS_X:
				if sight_dir.x < 0:
					result += 'NX'
				else:
					result += 'X'
			Vector3.AXIS_Z:
				if sight_dir.z < 0:
					result += 'NZ'
				else:
					result += 'Z'
		
	else:
		assert(false, '未知的orientation type %d' % orientation_type)
	
	return result
	
static func get_orientation_by_name(name : String) -> String:
	var temp := name.split('_')
	return temp[temp.size() - 1]
	
static func get_default_attributes(attributes : Array) -> String:
	var result = ''
	
	for attribute in attributes:
		result += '_' + attribute[0]
	
	return result
