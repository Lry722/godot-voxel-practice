const Structure := preload("res://generator/Structure.gd")

var library := preload("res://blocks/library.tres")
var log := library.get_model_index_from_resource_name('log')
var leaves := library.get_model_index_from_resource_name('leaves')

var tree := VoxelBuffer.new()

func _init():
	tree.create(5, 6, 5)
	tree.fill_area(leaves, Vector3i(0, 3, 0), Vector3i(5, 4, 5), VoxelBuffer.CHANNEL_TYPE)
	tree.fill_area(leaves, Vector3i(1, 4, 1), Vector3i(4, 5, 4), VoxelBuffer.CHANNEL_TYPE)
	tree.set_voxel(leaves, 2, 5, 2, VoxelBuffer.CHANNEL_TYPE)
	tree.set_voxel(leaves, 1, 5, 2, VoxelBuffer.CHANNEL_TYPE)
	tree.set_voxel(leaves, 2, 5, 1, VoxelBuffer.CHANNEL_TYPE)
	tree.set_voxel(leaves, 3, 5, 2, VoxelBuffer.CHANNEL_TYPE)
	tree.set_voxel(leaves, 2, 5, 3, VoxelBuffer.CHANNEL_TYPE)
	tree.fill_area(log, Vector3i(2, 0, 2), Vector3i(3, 5, 3), VoxelBuffer.CHANNEL_TYPE)

func generate() -> Structure:
	var new_structure := Structure.new()
	new_structure.voxels = tree
	new_structure.local_origin = Vector3i(2, 0, 2)
	
	return new_structure
