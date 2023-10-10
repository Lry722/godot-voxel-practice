class_name Block

var index : int
var name : String
var with : String
var attributes : Array

func place(pos : Vector3i, orientation : Vector3, tool : VoxelToolTerrain):
	var variant := name
	print(orientation)
	variant += Util.get_axis(orientation, with)
	variant += Util.get_default_attributes(attributes)
	print(variant)
	tool.set_voxel(pos, Blocks.get_model_index_by_resource_name(variant))
	
func update(pos : Vector3i, tool : VoxelToolTerrain):
	pass
	
func destroy(pos : Vector3i, tool : VoxelToolTerrain):
	tool.set_voxel(pos, 0)
	
