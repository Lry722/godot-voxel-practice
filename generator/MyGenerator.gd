extends VoxelGeneratorScript

var noise := FastNoiseLite.new()
var heightmap := preload("res://generator/heightmap.tres")
var rand := RandomNumberGenerator.new()
var tree_generator := preload("res://generator/tree_generator.gd").new()

var library := preload("res://blocks/library.tres")
var air = library.get_model_index_from_resource_name('air')
var dirt = library.get_model_index_from_resource_name('dirt')
var grass = library.get_model_index_from_resource_name('grass')
var tall_grass = library.get_model_index_from_resource_name('tall_grass')
var water_top = library.get_model_index_from_resource_name('water_top')
var water_full = library.get_model_index_from_resource_name('water_full')

func _init() :
	noise.frequency = 1.0 / 256.0
	noise.fractal_octaves = 16.0
	heightmap.bake()

func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
	var origin_height := origin_in_voxels.y
	var chunk_pos := origin_in_voxels / 16
	
	for x in 16:
		for z in 16:
			var relative_height = get_height(x + origin_in_voxels.x, z + origin_in_voxels.z) - origin_height
			
			#泥土，草方块，草
			if relative_height >= 16 :
				out_buffer.fill_area(dirt, Vector3i(x, 0, z), Vector3i(x + 1, 16, z + 1), VoxelBuffer.CHANNEL_TYPE)
			elif relative_height >= 0 :
				out_buffer.fill_area(dirt, Vector3i(x, 0, z), Vector3i(x + 1, relative_height + 1, z + 1), VoxelBuffer.CHANNEL_TYPE)
				if origin_height >= 0:
					out_buffer.set_voxel(grass, x, relative_height, z, VoxelBuffer.CHANNEL_TYPE)
					if rand.randf() < 0.1 and relative_height + 1 < 16 :
						out_buffer.set_voxel(tall_grass, x, relative_height + 1, z, VoxelBuffer.CHANNEL_TYPE)

			#水	
			if origin_height < 0:
				if relative_height < 0 :
					out_buffer.fill_area(water_full, Vector3i(x, 0, z), Vector3i(x + 1, 16, z + 1), VoxelBuffer.CHANNEL_TYPE)
				elif relative_height < 16 :
					out_buffer.fill_area(water_full, Vector3i(x, relative_height + 1, z), Vector3i(x + 1, 16, z + 1), VoxelBuffer.CHANNEL_TYPE)
			
			#水面
			if origin_height == 0 and relative_height < 0:
				out_buffer.set_voxel(water_top, x, 0, z, VoxelBuffer.CHANNEL_TYPE)
	
	var chunk_AABB := AABB(Vector3i(), out_buffer.get_size())
	var voxel_tool := out_buffer.get_voxel_tool()
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				for tree in get_trees_in(chunk_pos + Vector3i(x, y, z)):
					var pos = tree.pos + Vector3i(x, y, z) * 16
					var tree_AABB = AABB(pos, tree.voxels.get_size())
					if tree_AABB.intersects(chunk_AABB):
						voxel_tool.paste_masked(pos, tree.voxels, 1 << VoxelBuffer.CHANNEL_TYPE, VoxelBuffer.CHANNEL_TYPE, air)
						
	out_buffer.compress_uniform_channels()
						
	
func get_height(x, z):
	return heightmap.sample(noise.get_noise_2d(x, z) / 2 + 0.5)

func get_seed_in(chunk_pos: Vector3i):
	return chunk_pos.x + (chunk_pos.y << 20) + (chunk_pos.z << 40)

func get_trees_in(chunk_pos: Vector3i) -> Array:
	if chunk_pos.y < 0:
		return []
	
	var chunk_rand := RandomNumberGenerator.new()
	chunk_rand.seed = get_seed_in(chunk_pos)
	
	var result = []
	
	var num := chunk_rand.randi_range(0, 4)
	for i in num:
		var new_structure := tree_generator.generate()
		new_structure.pos.x = chunk_rand.randi_range(0, 15)
		new_structure.pos.z = chunk_rand.randi_range(0, 15)
		var global_pos := chunk_pos * 16
		new_structure.pos.y = get_height(global_pos.x + new_structure.pos.x, global_pos.z + new_structure.pos.z) - global_pos.y
		new_structure.pos -= new_structure.local_origin
		if new_structure.pos.y >= 0 and new_structure.pos.y <= 15 and not (chunk_pos.y == 0 and new_structure.pos.y == 0):
			result.append(new_structure)
		
	return result
