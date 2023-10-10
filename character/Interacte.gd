extends Node

var Util := preload("res://util/Util.gd")

@export var eyes : Camera3D
@export var body : MeshInstance3D
@export var operation_range := 5.0
@export var cursor_margin := 0.005

@onready var terrain : VoxelTerrain = get_node('/root/Game/VoxelTerrain')
@onready var terrain_tool : VoxelTool = terrain.get_voxel_tool()

var cursor_voxel_id := 0
var cursor := MeshInstance3D.new()

func _ready():
	cursor.scale = Vector3(1, 1, 1) * (1 + cursor_margin * 2)
	terrain.add_child(cursor)

func _physics_process(delta):
	var pointed_voxel = get_pointed_voxel()
	if pointed_voxel:
		update_cursor(pointed_voxel)
		cursor.show()
	else:
		cursor.hide()
		
	if Input.is_action_just_pressed('destroy') and pointed_voxel:
		Blocks.destroy(pointed_voxel, terrain_tool)
	elif Input.is_action_just_pressed("place"):
		var placeable_voxel_and_normal = get_placeable_voxel()
		if placeable_voxel_and_normal:
			Blocks.place(4, placeable_voxel_and_normal[0], placeable_voxel_and_normal[1], terrain_tool)
	
func get_pointed_voxel():
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = eyes.project_ray_origin(mouse_pos)
	var forward = eyes.basis.z.normalized() * -1
	
	var hit := terrain_tool.raycast(origin, forward, operation_range, 7)
	if hit :
		return hit.position
	else:
		return null
		
func get_placeable_voxel():
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = eyes.project_ray_origin(mouse_pos) 
	var forward = eyes.basis.z.normalized() * -1
	
	var hit := terrain_tool.raycast(origin, forward, operation_range, 3)
	if hit and not AABB(body.custom_aabb.position + get_parent().position, body.custom_aabb.size).intersects(
				   AABB(hit.previous_position, Vector3(1, 1, 1))):
		return [hit.previous_position - hit.position, hit.previous_position]
	else:
		return null

func update_cursor(pointed_voxel: Vector3i):
	var pointed_voxel_id := terrain_tool.get_voxel(pointed_voxel)
	if pointed_voxel_id != cursor_voxel_id:
		var model := Blocks.get_model_by_index(pointed_voxel_id)
		cursor.mesh = Util.create_wireframe_mesh(model)
		cursor_voxel_id = pointed_voxel_id
	cursor.position = Vector3(pointed_voxel) - Vector3(1, 1, 1) * cursor_margin
