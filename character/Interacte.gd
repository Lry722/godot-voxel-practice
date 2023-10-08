extends Node

var Util := preload("res://util/Util.gd")

@export var eye : Camera3D
@onready var terrain : VoxelTerrain = get_node('/root/Game/VoxelTerrain')
@onready var terrain_tool : VoxelTool = terrain.get_voxel_tool()

var operation_range := 5.0
var cursor_voxel_id := 0
var cursor := MeshInstance3D.new()
var cursor_margin := 0.004

func _ready():
	cursor.scale = Vector3(1, 1, 1) * (1 + cursor_margin * 2)
	add_child(cursor)

func _physics_process(delta):
	var pointed_voxel = get_pointed_voxel()
	if pointed_voxel:
		update_cursor(pointed_voxel)
		cursor.show()
	else:
		cursor.hide()
	
func get_pointed_voxel():
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = eye.project_ray_origin(mouse_pos) 
	var forward = eye.basis.z.normalized() * -1
	
	var hit := terrain_tool.raycast(origin, forward, operation_range, 3)
	if hit :
		return hit.position
	else:
		return null

func update_cursor(pointed_voxel: Vector3i):
	var pointed_voxel_id := terrain_tool.get_voxel(pointed_voxel)
	if pointed_voxel_id != cursor_voxel_id:
		var model := Blocks.get_model_by_index(pointed_voxel_id)
		cursor.mesh = Util.create_wireframe_mesh(model)
		cursor_voxel_id = pointed_voxel_id
	cursor.global_position = Vector3(pointed_voxel) - Vector3(1, 1, 1) * cursor_margin
