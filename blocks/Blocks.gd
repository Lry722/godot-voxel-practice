extends Node

var library := preload("res://blocks/library.tres")
var default_script := preload("res://blocks/Block.gd").new()
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
		block.with = block_info.with
		block.attributes = block_info.attributes
		var variants = Util.get_variants(block_info)
		for variant in variants:
			var variant_index = library.get_model_index_from_resource_name(variant)
			if variant_index >= variant_to_block.size():
				variant_to_block.resize(variant_index + 1)
			variant_to_block[variant_index] = block.index
			
	for i in variant_to_block.size():
		if variant_to_block[i] == null:
			variant_to_block[i] = 0
			
func place(block_index : int, orientation : Vector3, pos : Vector3i, tool : VoxelToolTerrain):
	blocks[block_index].place(pos, orientation, tool)
	for pos_to_update in [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(0, 0, -1),
						  Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1), ]:
		var variant_index := tool.get_voxel(pos + pos_to_update)
		var block_to_update = blocks[variant_to_block[variant_index]]
		if block_to_update:
			block_to_update.update(pos + pos_to_update, tool)

func destroy(pos : Vector3i, tool : VoxelToolTerrain):
	var variant := tool.get_voxel(pos)
	blocks[variant_to_block[variant]].destroy(pos, tool)
	for pos_to_update in [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(0, 0, -1),
						  Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1), ]:
		var variant_index := tool.get_voxel(pos + pos_to_update)
		var block_to_update = blocks[variant_to_block[variant_index]]
		if block_to_update:
			block_to_update.update(pos + pos_to_update, tool)

func get_model_index_by_resource_name(name : String) -> int:
	return library.get_model_index_from_resource_name(name)

func get_model_by_index(index: int) -> VoxelBlockyModel:
	return library.get_model(index)
