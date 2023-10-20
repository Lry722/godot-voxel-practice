extends Node

var library := preload("res://blocks/library.tres")
var default_script := preload("res://blocks/block.gd").new()
var blocks := []
var variant_to_block = []

var blocks_size : int :
	get:
		return blocks.size()
		
var library_size : int :
	get:
		return library.models.size()

func _init():
	var file := FileAccess.open("res://blocks/blocks.json", FileAccess.READ)
	var data : Array = JSON.parse_string(file.get_as_text())['blocks']
	for block_info in data:
		if (block_info.has_script):
			blocks.append(load('res://blocks/' + block_info.name + '/script.gd').new())
		else:
			blocks.append(Block.new())
		var block : Block = blocks.back()
		block.name = block_info.name
		block.orientation_type = block_info.orientation_type
		block.attributes = block_info.attributes
		add_block(block)
		
	for i in variant_to_block.size():
		if variant_to_block[i] == null:
			variant_to_block[i] = 0

	process_mode = Node.PROCESS_MODE_DISABLED
			
func place(block_index : int, pos : Vector3i, normal : Vector3i, sight_dir : Vector3, tool : VoxelToolTerrain):
	blocks[block_index].place(pos, normal, sight_dir, tool)
	update_around(pos, tool)
	update(pos, Vector3i(), tool)
	Liquids.update_around(pos)

func destroy(pos : Vector3i, tool : VoxelToolTerrain):
	var variant := tool.get_voxel(pos)
	blocks[variant_to_block[variant]].destroy(pos, tool)
	update_around(pos, tool)
	Liquids.update(pos)

func update(pos : Vector3i, from : Vector3i, tool : VoxelToolTerrain):
	var variant_index := tool.get_voxel(pos)
	var block_to_update : Block = blocks[variant_to_block[variant_index]]
	if block_to_update:
		block_to_update.update(pos, from, tool)
		
func update_around(pos : Vector3i, tool : VoxelToolTerrain):
	for offset in [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(0, 0, -1),
				   Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]:
		var pos_to_update = pos + offset
		if not Liquids.is_liquid(pos_to_update):
			update(pos_to_update, -offset,tool)
		
func add_block(block : Block):
	block.index = blocks.size() - 1
	var variants = create_orientations_variants(block)
	for variant in variants:
		if library_size > variant_to_block.size():
			variant_to_block.resize(library_size)
		variant_to_block[variant] = block.index
		
func is_block(variant_index : int) -> bool:
	return variant_index > 0 and variant_index < variant_to_block.size()
		
func add_variant(variant : VoxelBlockyModel):
	library.add_model(variant)

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

func create_orientations_variants(block : Block) -> Array:
	var orientations = []
	match int(block.orientation_type):
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
			assert(false, '未知的朝向 %d' % block.orientation_type)
	
	var attributes_variants := Util.get_attributes_variants(block)
	var result := []
	for variant in attributes_variants:
		result.append(library.get_model_index_from_resource_name(variant))
	for attributes_variant in attributes_variants:
		for orientation in orientations:
			var variant = library.get_model(library.get_model_index_from_resource_name(attributes_variant))
			if not variant:
				continue
			variant = variant.duplicate()
			variant.resource_name += orientation
			result.append(library_size)
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
