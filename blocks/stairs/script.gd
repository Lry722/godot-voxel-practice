extends Block

func update(pos : Vector3i, from : Vector3i, tool : VoxelToolTerrain):
	var variant_index := tool.get_voxel(pos)
	var orientation := Util.get_orientation_by_name(Blocks.get_variant_by_index(variant_index).resource_name)
	var from_variant_index := tool.get_voxel(pos + from)
	var from_block_index := Blocks.get_block_index_by_variant_index(from_variant_index)
	if from_block_index != index:
		tool.set_voxel(pos, Blocks.get_variant_index_by_name('stairs_default_' + orientation))
		return
	
	var from_variant_orientation := Util.get_orientation_by_name(Blocks.get_variant_by_index(from_variant_index).resource_name)
	if orientation.contains('D') != from_variant_orientation.contains('D'):
		return
	
	var from_variant_orientation_vector : Vector3i = Util.orientation_to_vector[from_variant_orientation]
	var orientation_vector : Vector3i = Util.orientation_to_vector[orientation]
	
	print(-orientation_vector, from)
	if -orientation_vector == from:
		var cross = Vector3(orientation_vector).cross(from_variant_orientation_vector)
		if orientation.contains('D'):
			cross.y *= -1
		if cross.y > 0:
			tool.set_voxel(pos, Blocks.get_variant_index_by_name('stairs_leftDot_' + orientation))
		elif cross.y < 0:
			tool.set_voxel(pos, Blocks.get_variant_index_by_name('stairs_rightDot_' + orientation))

