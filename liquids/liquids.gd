extends Node

@export var interval := .2
@export var max_process := 10

@onready var terrain : VoxelTerrain = get_node('/root/Game/VoxelTerrain')
@onready var terrain_tool : VoxelTool = terrain.get_voxel_tool()

const height_map := [0.05, 0.3, 0.6, 0.9, 1.0]


var liquid_meshes := []
var liquids := []
var liquid_sources := Dictionary()
var name_to_variant := Dictionary()
var variant_to_liquid := []

var update_queue := []
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
						liquid_sources[liquid.name + '_full'] = Blocks.get_variant_index_by_name(liquid.name + '_4444')
						liquid_sources[liquid.name + '_top'] = Blocks.get_variant_index_by_name(liquid.name + '_3333')
		
		liquids.append(liquid)
		update_queue.resize(max_process * 10)
		
func _process(delta):
	time_elapsed += delta
	if time_elapsed > interval:
		time_elapsed -= interval
		if head == cur_tail:
			cur_tail = tail
			for pos in pos_to_update:
				terrain_tool.set_voxel(pos, pos_to_update[pos])
			pos_to_update.clear()
	
	for i in max_process:
		if head == cur_tail:
			break
		var pos : Vector3i = update_queue[head]
		var variant = terrain_tool.get_voxel(pos)
		print('head: ', head, ' cur_tail: ', cur_tail, ' tail: ', tail)
#		print('head pos: ', pos,' head variant: ', variant)
		head = (head + 1) % update_queue.size()
		var height := get_height(pos)
		if not pos in pos_to_update:
			var y := terrain_tool.get_voxel(pos + Vector3i(0, 1, 0))
			var ny := terrain_tool.get_voxel(pos + Vector3i(0, -1, 0))
			if is_liquid(pos + Vector3i(0, 1, 0), y):
				if get_height(pos, variant) != 4:
					pos_to_update[pos] = name_to_variant[liquids[variant_to_liquid[y]].name + '_4444']
					terrain_tool.set_voxel_metadata(pos, {'height': 4, 'flowable': Blocks.is_block(ny)})
					update_around(pos)
			else:
				var heights = []
				heights.resize(8)
				var tallest_neighbor := 0
				var source_count := 0
				var exist := false
				var max_neighbor_height := 0
				var j := 0
				for offset in [Vector3i(-1, 0, 0), Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1)]:
					var neighbor_pos = pos + offset
					var neighbor := terrain_tool.get_voxel(neighbor_pos)
					var neighbor_height := get_height(neighbor_pos, neighbor)
						
					if neighbor_height > max_neighbor_height:
						max_neighbor_height = neighbor_height
						tallest_neighbor = neighbor
					heights[j] = neighbor_height
					
					if is_source(neighbor_pos, neighbor):
						source_count += 1
						
					exist = true if is_flowable(neighbor_pos) else exist
					
					j += 1

				if source_count >= 2:
					pos_to_update[pos] = name_to_variant[liquids[variant_to_liquid[tallest_neighbor]].name + '_3333']
					terrain_tool.set_voxel_metadata(pos, null)
					update_around(pos)
				elif exist:
					var new_height := height - 1 if max_neighbor_height <= height else max_neighbor_height - 1
					if new_height > 0:
						terrain_tool.set_voxel_metadata(pos, {'height': new_height, 'flowable': Blocks.is_block(ny)})
						for offset in [Vector3i(-1, 0, -1), Vector3i(1, 0, -1), Vector3i(1, 0, 1), Vector3i(-1, 0, 1)]:
							heights[j] = max(get_height(pos + offset), heights[j - 4], heights[(j - 3) % 4])
							if heights[j] < new_height:
								heights[j] = new_height - 1
							else:
								heights[j] = heights[j] - 1
							j += 1
						var new_variant = name_to_variant[liquids[variant_to_liquid[tallest_neighbor]].name + '_' + 
														  str(heights[4]) + str(heights[5]) + str(heights[6]) + str(heights[7])]
						pos_to_update[pos] = new_variant
						if height != new_height:
							update_around(pos)
					else:
						pos_to_update[pos] = 0
						terrain_tool.set_voxel_metadata(pos, null)

func place(liquid_index : int, pos : Vector3i):
	if is_liquid(pos + Vector3i(0, 1, 0)):
		terrain_tool.set_voxel(pos, Blocks.get_variant_index_by_name(liquids[liquid_index].name + '_4444')) 
	else:
		terrain_tool.set_voxel(pos, Blocks.get_variant_index_by_name(liquids[liquid_index].name + '_3333')) 
	terrain_tool.set_voxel_metadata(pos, null)
	update_around(pos)

func update(pos : Vector3i):
	var variant = terrain_tool.get_voxel(pos)
	if (not pos in pos_to_update) and (variant == 0 or (is_liquid(pos, variant) and not is_source(pos, variant))) and (tail + 1) % update_queue.size() != head:
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

func is_liquid(pos : Vector3i, variant := -1) -> bool:
	variant = variant if variant != -1 else terrain_tool.get_voxel(pos)
	return variant_to_liquid[variant] != null
	
func is_source(pos : Vector3i, variant := -1) -> bool:
	var metadata = terrain_tool.get_voxel_metadata(pos)
	variant = variant if variant != -1 else terrain_tool.get_voxel(pos)
	if not is_liquid(pos, variant):
		return false
	return metadata == null
	
func is_flowable(pos : Vector3i, variant := -1) -> bool:
	var metadata = terrain_tool.get_voxel_metadata(pos)
	variant = variant if variant != -1 else terrain_tool.get_voxel(pos)
	if is_liquid(pos, variant):
		if metadata:
			return metadata.flowable
		else:
			return true
	else:
		return false
	
func get_height(pos : Vector3i, variant := -1) -> int:
	var metadata = terrain_tool.get_voxel_metadata(pos)
	variant = variant if variant != -1 else terrain_tool.get_voxel(pos)
	if is_liquid(pos, variant):
		if metadata:
			return metadata.height
		else:
			return 4
	elif variant == 0:
		return 0
	else:
		return -1

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
