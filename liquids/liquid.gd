extends Block
class_name Liquid

var fluidity : int
var viscosity : int

func update(pos : Vector3i, from : Vector3i, tool : VoxelToolTerrain):
	if tool.get_voxel_metadata(pos) == null:
		return
	var nz := Liquids.get_height(tool.get_voxel(pos + Vector3i(0, 0, -1)))
	var z := Liquids.get_height(tool.get_voxel(pos + Vector3i(0, 0, 1)))
	var nx := Liquids.get_height(tool.get_voxel(pos + Vector3i(-1, 0, 0)))
	var x := Liquids.get_height(tool.get_voxel(pos + Vector3i(1, 0, 0)))
	
	var height = max(nz, z, nx, x) - 1
	nz = nz if nz != -1 else height
	z = z if z != -1 else height
	nx = nx if nx != -1 else height
	x = x if x != -1 else height
	
	
	if height > 0:
		print(name + '_' + str(nz) + str(z) + str(nx) + str(x))
		tool.set_voxel(pos, Blocks.get_variant_index_by_name(name + '_' + str(nz) + str(z) + str(nx) + str(x)))
	else:
		tool.set_voxel(pos, 0)
	
#func flow(from : Vector3i, to : Vector3i, tool : VoxelToolTerrain):
#
