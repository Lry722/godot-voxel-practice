extends Node

var library := preload("res://blocks/library.tres")
var default_script := preload("res://blocks/block.gd").new()
var blocks := []
var variant_to_block = []

func _init():
	var file := FileAccess.open("res://blocks/blocks.json", FileAccess.READ)
	var data : Array = JSON.parse_string(file.get_as_text())['blocks']
	for block_info in data:
		if (block_info.has_script):
			blocks.append(load('res://blocks/' + block_info.name + '/script.gd').new())
		else:
			blocks.append(Block.new())
		var block : Block = blocks.back()
		block.index = blocks.size() - 1	
		block.name = block_info.name
		block.orientation_type = block_info.orientation_type
		block.attributes = block_info.attributes
		var variants = create_orientations_variants(block_info)
		for variant in variants:
			var variant_index = library.get_model_index_from_resource_name(variant)
			if variant_index >= variant_to_block.size():
				variant_to_block.resize(variant_index + 1)
			variant_to_block[variant_index] = block.index
			
	for i in variant_to_block.size():
		if variant_to_block[i] == null:
			variant_to_block[i] = 0
			
func place(block_index : int, pos : Vector3i, normal : Vector3i, sight_dir : Vector3, tool : VoxelToolTerrain):
	blocks[block_index].place(pos, normal, sight_dir, tool)
	update_around(pos, tool)

func destroy(pos : Vector3i, tool : VoxelToolTerrain):
	var variant := tool.get_voxel(pos)
	blocks[variant_to_block[variant]].destroy(pos, tool)
	update_around(pos, tool)
			
func update_around(pos : Vector3i, tool : VoxelToolTerrain):
	for pos_to_update in [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(0, 0, -1),
						  Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1), ]:
		var variant_index := tool.get_voxel(pos + pos_to_update)
		var block_to_update = blocks[variant_to_block[variant_index]]
		if block_to_update:
			block_to_update.update(pos + pos_to_update, -pos_to_update, tool)

func get_variant_index_by_name(name : String) -> int:
	return library.get_model_index_from_resource_name(name)

func get_variant_by_index(index : int) -> VoxelBlockyModel:
	return library.get_model(index)

func get_variant_by_name(name : String) -> VoxelBlockyModel:
	return library.get_model(library.get_model_index_from_resource_name(name))

func get_block_index_by_variant_index(index : int) -> int:
	return variant_to_block[index]

func get_default_blocks() -> Dictionary:
	var result = {
		"air": 0
	}
	for block in blocks:
		result[block.name] = library.get_model_index_from_resource_name(block.name + Util.get_default_attributes(block.attributes))
	return result

func create_orientations_variants(block_info : Dictionary) -> Array:
	var orientations = []
	match int(block_info.orientation_type):
		0:
			orientations = []
		3:
			orientations = ['_X', '_Y', '_Z']
		6:
			orientations = ['_X', '_Y', '_Z', '_NX', '_NY', '_NZ']
		2:
			orientations = ['_X', '_Z']
		4:
			orientations = ['_X', "_Z", '_NX', '_NZ']
		8:
			orientations = ['_X', '_Z', '_NX', '_NZ', '_DX', '_DZ', '_DNX', '_DNZ']
		_:
			assert(false, '未知的朝向 %d' % block_info.orientation_type)
	
	var attributes_variants := Util.get_attributes_variants(block_info)
	var result := attributes_variants.duplicate()
	for attributes_variant in attributes_variants:
		for orientation in orientations:
			var variant = library.get_model(library.get_model_index_from_resource_name(attributes_variant))
			if not variant:
				continue
			variant = variant.duplicate()
			variant.resource_name += orientation
			result.append(variant.resource_name)
			match orientation:
				'_X':
					variant.rotate_90(Vector3i.AXIS_Y, false)
				'_Y':
					variant.rotate_90(Vector3i.AXIS_X, true)
				'_NX':
					variant.rotate_90(Vector3i.AXIS_Y, true)
				'_NY':
					variant.rotate_90(Vector3i.AXIS_X, false)
				'_NZ':
					variant.rotate_90(Vector3i.AXIS_Y, true)
					variant.rotate_90(Vector3i.AXIS_Y, true)
				'_DX':
					variant.rotate_90(Vector3i.AXIS_Y, false)
					variant.rotate_90(Vector3i.AXIS_X, true)
					variant.rotate_90(Vector3i.AXIS_X, true)
				'_DZ':
					variant.rotate_90(Vector3i.AXIS_Z, true)
					variant.rotate_90(Vector3i.AXIS_Z, true)
				'_DNX':
					variant.rotate_90(Vector3i.AXIS_Y, true)
					variant.rotate_90(Vector3i.AXIS_X, true)
					variant.rotate_90(Vector3i.AXIS_X, true)
				'_DNZ':
					variant.rotate_90(Vector3i.AXIS_Y, true)
					variant.rotate_90(Vector3i.AXIS_Y, true)
					variant.rotate_90(Vector3i.AXIS_Z, true)
					variant.rotate_90(Vector3i.AXIS_Z, true)
					
			library.add_model(variant)
			
	return result
