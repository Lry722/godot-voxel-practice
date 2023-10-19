extends Node

var liquid_meshes := []
var liquids := []
var liquid_height_map := []
var variant_to_liquid := []
var update_queue := []
var head := 0
var tail := 0

func _init():
	create_liquid_meshes()
	var file := FileAccess.open("res://liquids/liquids.json", FileAccess.READ)
	var data : Array = JSON.parse_string(file.get_as_text())['liquids']
	for liquid_info in data:
		if (liquid_info.has_script):
			liquids.append(load('res://liquids/' + liquid_info.name + '/script.gd').new())
		else:
			liquids.append(Liquid.new())
		var material := load('res://liquids/materials/' + liquid_info.name + '.tres')
		var liquid : Liquid = liquids.back()
		liquid.index = liquids.size() - 1
		liquid.name = liquid_info.name
		liquid.orientation_type = 0
		liquid.fluidity = liquid_info.fluidity
		liquid.viscosity = liquid_info.viscosity
		liquid.attributes = [
			[4, 3, 2, 1, 0],
			[4, 3, 2, 1, 0],
			[4, 3, 2, 1, 0],
			[4, 3, 2, 1, 0]
		]
		variant_to_liquid.resize(Blocks.library_size + pow(5, 4))
		liquid_height_map.resize(Blocks.library_size + pow(5, 4))
		for nz in 5:
			for z in 5:
				for nx in 5:
					for x in 5:
						var variant = VoxelBlockyModelMesh.new()
						variant.resource_name = liquid.name + '_' + str(nz) + str(z) + str(nx) + str(x)
						variant.transparency_index = 2
						variant.collision_aabbs = [AABB(Vector3(0, 0, 0), Vector3(1, max(nz, z, nx, x) / 5, 1))]
						variant.collision_mask = 1 << 3
						variant.mesh = liquid_meshes[min(nx, nz)][min(x,nz)][min(x,z)][min(nx,z)]
						variant.set_material_override(0, material)
						var variant_index = Blocks.library_size
						Blocks.add_variant(variant)
						variant_to_liquid[variant_index] = liquid.index
						liquid_height_map[variant_index] = max(nz, z, nx, x)
		liquids.append(liquid)
		liquid_height_map[0] = 0
		print(liquid_height_map)

func update(pos : Vector3i, tool : VoxelToolTerrain):
	pass

func create_liquid_meshes():
	var normals := [
		Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0), 
		Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), 
		Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1),
		Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), 
		Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), 
		Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), 
	]
	var colors := []
	colors.resize(24)
	colors.fill(Color(255, 255, 255))
	var indices := []
	for i in range(0, 24, 4):
		indices.append_array([
			i, i + 1, i + 2, i, i + 2, i + 3
		])
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[ArrayMesh.ARRAY_COLOR] = PackedColorArray(colors)
	arrays[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(indices)
	liquid_meshes.resize(5)
	
	for lt in 5:
		liquid_meshes[lt] = []
		liquid_meshes[lt].resize(5)
		for rt in 5:
			liquid_meshes[lt][rt] = []
			liquid_meshes[lt][rt].resize(5)
			for rb in 5:
				liquid_meshes[lt][rt][rb] = []
				liquid_meshes[lt][rt][rb].resize(5)
				for lb in 5:
					var vertexs := [
						Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1),
						Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, rt / 4.0, 0), Vector3(0, lt / 4.0, 0),
						Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, rb / 4.0, 1), Vector3(0, lb / 4.0, 1),
						Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, lb / 4.0, 1), Vector3(0, lt / 4.0, 0),
						Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, rb / 4.0, 1), Vector3(1, rt / 4.0, 0),
						Vector3(0, lt / 4.0, 0), Vector3(1, rt / 4.0, 0), Vector3(1, rb / 4.0, 1), Vector3(0, lb / 4.0, 1),
					]
					arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(vertexs)
					var mesh = ArrayMesh.new()
					mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES ,arrays)
					liquid_meshes[lt][rt][rb][lb] = mesh

func get_liquids() -> Dictionary:
	var result : Dictionary
	for liquid in liquids:
		result[liquid.name + '_full'] = Blocks.get_variant_index_by_name(liquid.name + '_4444')
		result[liquid.name + '_top'] = Blocks.get_variant_index_by_name(liquid.name + '_3333')
		
	return result
	
func get_liquid(variant_index : int) -> Liquid:
	return liquids[variant_to_liquid[variant_index]];

func is_liquid(variant_index : int) -> bool:
	return variant_to_liquid[variant_index] != null

func get_height(variant_index : int) -> int:
	return liquid_height_map[variant_index] if liquid_height_map[variant_index] != null else -1
