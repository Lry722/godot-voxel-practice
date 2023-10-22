class_name Block

var index : int
var name : String
var orientation_type : int
var attributes : Array

func place(pos : Vector3i, normal : Vector3i, sight_dir : Vector3, tool : VoxelToolTerrain) -> int:
	var variant_name := name
	variant_name += Util.get_default_attributes(attributes)
	variant_name += Util.get_orientation(normal, sight_dir, orientation_type)
	var variant = Blocks.get_variant_by_name(variant_name)
	print(variant_name)
	tool.set_voxel_metadata(pos, null)
	tool.set_voxel(pos, variant)
	return variant
	
func update(pos : Vector3i, from : Vector3i, tool : VoxelToolTerrain) -> bool:
	return false
	
func destroy(pos : Vector3i, tool : VoxelToolTerrain):
	tool.set_voxel(pos, 0)
	
