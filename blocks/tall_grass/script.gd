extends Block

func update(pos : Vector3i, from : Vector3i, tool : VoxelToolTerrain):
	if from == Vector3i(0, -1, 0) and not Blocks.is_block(tool.get_voxel(pos + Vector3i(0, -1, 0))):
		tool.set_voxel(pos, 0)
