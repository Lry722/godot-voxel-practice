extends Node

@export var interval := 0.2
@export var max_process := 50

@onready var terrain : VoxelTerrain = get_node('/root/Game/VoxelTerrain')
@onready var terrain_tool : VoxelTool = terrain.get_voxel_tool()

const height_map := [0.05, 0.3, 0.6, 0.9, 1.0]


var liquid_meshes := []
var liquids := []
var liquid_sources := Dictionary()
var name_to_variant := Dictionary()
var variant_to_liquid := []

var update_queue := []
var height_cache := Dictionary()
var variant_cache := Dictionary()
var source_cache := []
var destroyed_blocks := []
var head := 0
var tail := 0
var cur_tail := 0
var pos_to_update := Dictionary()
var time_elapsed := 0.0

func _init():
	create_liquid_meshes()
	var file := FileAccess.open("res://liquids/liquids.json", FileAccess.READ)
	var data : Array = JSON.parse_string(file.get_as_text())['liquids']
	for liquid_info in data:
		if (liquid_info.has_script):
			liquids.append(load('res://liquids/' + liquid_info.name + '/script.gd').new())
		else:
			liquids.append(Liquid.new())
		var material := load('res://liquids/materials/' + liquid_info.name + '.tres')
		
		var liquid : Liquid = liquids.back()
		liquid.index = liquids.size() - 1
		liquid.name = liquid_info.name
		liquid.orientation_type = 0
		liquid.fluidity = liquid_info.fluidity
		liquid.viscosity = liquid_info.viscosity
		liquid.attributes = [
			[4, 3, 2, 1, 0],
			[4, 3, 2, 1, 0],
			[4, 3, 2, 1, 0],
			[4, 3, 2, 1, 0]
		]
		
		var item := Item.new()
		item.display = load('res://liquids/' + liquid.name + '/' + liquid.name + '_sprite.png')
		item.name = liquid.name
		item.type = Item.Type.LIQUID
		item.id = liquid.index
		item.count = -1
		Items.add(item)
		
		variant_to_liquid.resize(Blocks.library_size + pow(5, 4))
		for lt in 5:
			for rt in 5:
				for rb in 5:
					for lb in 5:
						var variant = VoxelBlockyModelMesh.new()
						variant.resource_name = liquid.name + '_' + str(lt) + str(rt) + str(rb) + str(lb)
						variant.transparency_index = 2
						variant.collision_aabbs = [AABB(Vector3(0, 0, 0), Vector3(1, height_map[max(lt, rt, rb, lb)], 1))]
						variant.collision_mask = 1 << 3
						variant.mesh = liquid_meshes[lt][rt][rb][lb]
						variant.set_material_override(0, material)
						var variant_index = Blocks.library_size
						Blocks.add_variant(variant)
						variant_to_liquid[variant_index] = liquid.index
						name_to_variant[variant.resource_name] = variant_index
						liquid_sources[liquid.name + '_full'] = Blocks.get_variant_by_name(liquid.name + '_4444')
						liquid_sources[liquid.name + '_top'] = Blocks.get_variant_by_name(liquid.name + '_3333')
		
		liquids.append(liquid)
		update_queue.resize(max_process * 10)
		
func _process(delta):
	time_elapsed += delta
	if time_elapsed > interval:
		time_elapsed -= interval
		if head == cur_tail:
			apply_update()
			
	for i in max_process:
		if head == cur_tail:
			break
#		print('head: %d cur_tail: %d tail: %d' % [head, cur_tail, tail])
		var pos : Vector3i = update_queue[head]
		var variant = get_variant_at(pos)
		head = (head + 1) % update_queue.size()
		var height := get_height(pos)
		if (not pos in pos_to_update) and ((not Blocks.is_block(variant)) or Blocks.variant_has_flag(variant, 'fragile')):
			var y := get_variant_at(pos + Vector3i(0, 1, 0))
			var ny := get_variant_at(pos + Vector3i(0, -1, 0))
			var new_height := -1
			var new_variant := -1
			if is_liquid(y):
				if get_height(pos, variant) != 4:
					new_height = 4
					new_variant = name_to_variant[liquids[variant_to_liquid[y]].name + '_4444']
					terrain_tool.set_voxel_metadata(pos, {'height': new_height, 'flowable': Blocks.is_block(ny)})
			else:
				var heights = []
				heights.resize(8)
				var source_count := 0
				var can_flow_here := false
				var tallest_neighbor := 0
				var max_neighbor_height := 0
				var j := 0
				for offset in [Vector3i(-1, 0, 0), Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1)]:
					var neighbor_pos = pos + offset
					var neighbor := get_variant_at(neighbor_pos)
					if is_liquid(neighbor):
						var neighbor_height := get_height(neighbor_pos, neighbor)	
						if neighbor_height > max_neighbor_height:
							max_neighbor_height = neighbor_height
							tallest_neighbor = neighbor
						heights[j] = neighbor_height
						if is_source(neighbor_pos):
							source_count += 1
						can_flow_here = is_flowable(neighbor_pos) or can_flow_here
					else:
						heights[j] = -1
					j += 1

				new_height = height - 1 if max_neighbor_height <= height else max_neighbor_height - 1
				if source_count >= 2:
					new_height = 4
					new_variant = name_to_variant[liquids[variant_to_liquid[tallest_neighbor]].name + '_3333']
					source_cache.append(pos)
					terrain_tool.set_voxel_metadata(pos, null)
				elif can_flow_here and new_height > 0:
					terrain_tool.set_voxel_metadata(pos, {'height': new_height, 'flowable': Blocks.is_block(ny)})
					for offset in [Vector3i(-1, 0, -1), Vector3i(1, 0, -1), Vector3i(1, 0, 1), Vector3i(-1, 0, 1)]:
						heights[j] = max(get_height(pos + offset), heights[j - 4], heights[(j - 3) % 4])
						if heights[j] < new_height:
							heights[j] = new_height - 1
						else:
							heights[j] = heights[j] - 1
						j += 1
					var from_variant = tallest_neighbor if is_liquid(tallest_neighbor) else variant
					new_variant = name_to_variant[liquids[variant_to_liquid[from_variant]].name + '_' + 
													  str(heights[4]) + str(heights[5]) + str(heights[6]) + str(heights[7])]
					if Blocks.variant_has_flag(variant, 'fragile'):
						destroyed_blocks.append(pos)
				elif is_liquid(variant):
					new_height = 0
					new_variant = 0
					
			if new_variant != -1 and new_height != -1 and variant != new_variant and (is_liquid(variant) or new_variant != 0):
#				print('height: %d new_height: %d variant: %d new_variant: %d' % [height, new_height, variant, new_variant])
#				print('variant: %d new_variant: %d' % [variant, new_variant])
				modify_variant_at(pos, new_variant)
				if height != new_height:
					update_around(pos)
					update(pos)

func place(liquid_index : int, pos : Vector3i):
	var variant : int
	if is_liquid_at(pos + Vector3i(0, 1, 0)):
		variant = Blocks.get_variant_by_name(liquids[liquid_index].name + '_4444')
	else:
		variant = Blocks.get_variant_by_name(liquids[liquid_index].name + '_3333')
	terrain_tool.set_voxel_metadata(pos, null)
	terrain_tool.set_voxel(pos, variant)
	modify_variant_at(pos, variant, true)
	update_around(pos)

func update(pos : Vector3i):
	var variant = terrain_tool.get_voxel(pos)
	if (variant == 0 or (is_liquid(variant) and not is_source(pos)) or Blocks.variant_has_flag(variant, 'fragile')) and (tail + 1) % update_queue.size() != head:
		update_queue[tail] = pos
		tail = (tail + 1) % update_queue.size()
		
func update_around(pos : Vector3i):
	for offset in [Vector3i(0, 0, -1), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, -1, 0)]:
		var pos_to_flow = pos + offset
		update(pos_to_flow)

func get_liquid_sources() -> Dictionary:
	return liquid_sources
	
func get_liquid(variant_index : int) -> Liquid:
	return liquids[variant_to_liquid[variant_index]];

func is_liquid_at(pos : Vector3i) -> bool:
	return is_liquid(get_variant_at(pos))

func is_liquid(variant : int) -> bool:
	return variant >= Blocks.blocks_size and variant < variant_to_liquid.size()
	
func is_source(pos : Vector3i) -> bool:
	if pos in source_cache:
		return true
	var metadata = terrain_tool.get_voxel_metadata(pos)
	var result : bool
	if not is_liquid_at(pos):
		result = false
	else:
		result = (metadata == null)
	if result:
		source_cache.append(pos)
	return result
	
func is_flowable(pos : Vector3i) -> bool:
	var metadata = terrain_tool.get_voxel_metadata(pos)
	if is_liquid_at(pos):
		if metadata:
			return metadata.flowable
		else:
			return true
	else:
		return false

func get_height(pos : Vector3i, variant := -1) -> int:
	if pos in height_cache:
		return height_cache[pos]
		
	variant = variant if variant != -1 else terrain_tool.get_voxel(pos)
	var metadata = terrain_tool.get_voxel_metadata(pos)
	var result := 0
	if is_liquid(variant):
		if metadata:
			result = metadata.height
		else:
			result = 4
	elif variant != 0:
		result = -1
	height_cache[pos] = result
	
	return result

func get_variant_at(pos : Vector3i) -> int:
	if pos in variant_cache:
		return variant_cache[pos]
	var result = terrain_tool.get_voxel(pos)
	variant_cache[pos] = result
	return result
	
func modify_variant_at(pos : Vector3i, new_variant : int, source := false):
	if is_liquid(new_variant) or new_variant == 0:
		pos_to_update[pos] = new_variant
	else:
		pos_to_update.erase(pos)

	height_cache.erase(pos)
	variant_cache[pos] = new_variant
	
	if source and pos not in source_cache:
		source_cache.append(pos)
	if (not source) and (pos in source_cache):
		source_cache.erase(pos)
	
func apply_update():
	cur_tail = tail
	for pos in pos_to_update:
		if pos in destroyed_blocks:
			Blocks.destroy(pos, terrain_tool)
		terrain_tool.set_voxel(pos, pos_to_update[pos])
		if pos_to_update[pos] == 0:
			terrain_tool.set_voxel_metadata(pos, null)
	pos_to_update.clear()
	height_cache.clear()
	variant_cache.clear()
	source_cache.clear()
	destroyed_blocks.clear()

func create_liquid_meshes():
	var normals := [
		Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0), 
		Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), 
		Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1),
		Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), 
		Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), 
		Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), 
	]
	var colors := []
	colors.resize(24)
	colors.fill(Color(255, 255, 255))
	var indices := []
	for i in range(0, 24, 4):
		indices.append_array([
			i, i + 1, i + 2, i, i + 2, i + 3
		])
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[ArrayMesh.ARRAY_COLOR] = PackedColorArray(colors)
	arrays[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(indices)
	liquid_meshes.resize(5)

	for a in 5:
		liquid_meshes[a] = []
		liquid_meshes[a].resize(5)
		for b in 5:
			liquid_meshes[a][b] = []
			liquid_meshes[a][b].resize(5)
			for c in 5:
				liquid_meshes[a][b][c] = []
				liquid_meshes[a][b][c].resize(5)
				for d in 5:
					var lt = height_map[a]
					var rt = height_map[b]
					var rb = height_map[c]
					var lb = height_map[d]
					var vertexs := [
						Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1),
						Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, rt, 0), Vector3(0, lt, 0),
						Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, rb, 1), Vector3(0, lb, 1),
						Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, lb, 1), Vector3(0, lt, 0),
						Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, rb, 1), Vector3(1, rt, 0),
						Vector3(0, lt, 0), Vector3(1, rt, 0), Vector3(1, rb, 1), Vector3(0, lb, 1),
					]
					arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(vertexs)
					var mesh = ArrayMesh.new()
					mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES ,arrays)
					liquid_meshes[a][b][c][d] = mesh
