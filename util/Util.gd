class_name Util

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

static func get_variants(block_info : Dictionary) -> Array:
	var result = []
	
	var block_name = block_info.name
	if block_info.with == 'None':
		result = [block_name]
	elif block_info.with == '3Axis':
		result = [block_name + '_X', block_name + '_Y', block_name + '_Z']
	elif block_info.with == '6Axis':
		result = [block_name + '_X', block_name + '_Y', block_name + '_Z', 
				  block_name + '_NX', block_name + '_NY', block_name + '_NZ']
	elif block_info.with == '2Axis':
		result= [block_name + '_X', block_name + '_Z']
	elif block_info.with == '4Axis':
		result= [block_name + '_X', block_name + '_Z', 
				 block_name + '_NX', block_name + '_NZ']
				
	
	
	return result
	
static func get_default_attributes(attributes : Array) -> String:
	var result = ''
	
	for attribute in attributes:
		result += '_' + attribute[0]
	
	return result
	
#static func get_all_attributes(attributes : Array) -> Array:
	#var result = []
	#
	#var stack := [0]
	#stack.resize(attributes.size())
	#var top = 0
	#var cur_combination = ''
	#
	#while top >= 0:
		#
	#
	#return result
	
static func get_axis(orientation : Vector3, type : String) -> String:
	if type == 'None':
		return ''
	
	var longest_axis := 'X'
	var longest_length := orientation.x
	if type != '2Axis' and type != '4Axis' and abs(orientation.y) > abs(longest_length):
		longest_axis = 'Y'
		longest_length = orientation.y
	if abs(orientation.z) > abs(longest_length):
		longest_axis = 'Z'
		longest_length = orientation.z
	
	if type != '2Axis' and type != '3Axis' and longest_length < 0:
		return '_N' + longest_axis
	else:
		return '_' + longest_axis
