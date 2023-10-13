class_name Block

var index : int
var name : String
var orientation_type : int
var attributes : Array

func place(pos : Vector3i, normal : Vector3i, sight_dir : Vector3, tool : VoxelToolTerrain):
	var variant := name
	variant += Util.get_default_attributes(attributes)
	variant += Util.get_orientation(normal, sight_dir, orientation_type)
	print(variant)
	tool.set_voxel(pos, Blocks.get_variant_index_by_name(variant))
	
func update(pos : Vector3i, from : Vector3i, tool : VoxelToolTerrain):
	pass
	
func destroy(pos : Vector3i, tool : VoxelToolTerrain):
	tool.set_voxel(pos, 0)
	
