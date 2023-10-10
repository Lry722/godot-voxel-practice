extends Block

func update(pos : Vector3i, tool : VoxelToolTerrain):
	if tool.get_voxel(pos - Vector3i(0, 1, 0)) == 0:
		tool.set_voxel(pos, 0)
	
