extends Node

var cube_mesh = load("res://blocks/cube.obj")
var library := preload("res://blocks/library.tres")

func get_model_by_index(index: int) -> VoxelBlockyModel:
	return library.get_model(index)

func get_mesh_by_index(index: int) -> Mesh:
	var model = library.get_model(index)
	var mesh_path = String('res://blocks/' + model.resource_name + '/' + model.resource_name + '.obj')
	var mesh = cube_mesh
	if FileAccess.file_exists(mesh_path):
		mesh = load(mesh_path)
	
	return mesh
