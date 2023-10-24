extends Node3D

@export var _speed := 5.0
@export var _max_speed := 40.0
@export var _gravity := -40.0
@export var _jump_force := 10.0
@export var _terrain : VoxelTerrain

@onready var _camera = $Eyes
@onready var _body = $Body

var _velocity = Vector3()
var _grounded := false
var _box_mover = VoxelBoxMover.new()

var _size = Vector3(0.8, 1.8, 0.8)
var _AABB = AABB(_size * 0.5 * -1, _size)

func _ready():
	_body.custom_aabb = _AABB
	_box_mover.set_step_climbing_enabled(1)
	_box_mover.set_collision_mask(1)

func _physics_process(delta):
	var forward = _camera.basis.z * -1
	forward = Plane(Vector3(0, 1, 0), 0).project(forward).normalized()
	var right = _camera.basis.x
	
	var direction = Vector3()
	
	if Input.is_key_pressed(KEY_W):
		direction += forward
	if Input.is_key_pressed(KEY_S):
		direction -= forward
	if Input.is_key_pressed(KEY_D):
		direction += right
	if Input.is_key_pressed(KEY_A):
		direction -= right
	
	direction = direction.normalized()
	_velocity = Vector3(direction.x * _speed, _velocity.y + _gravity * delta, direction.z * _speed)
	if _velocity.length() > _max_speed:
		_velocity.y -= _gravity * delta
	
	if _grounded :
		if Input.is_key_pressed(KEY_SPACE) :
			_velocity.y = _jump_force
			_grounded = false

	var expect_movement = _velocity * delta
	var actual_movement = _box_mover.get_motion(position, expect_movement, _AABB, _terrain)
	translate(actual_movement)
	
	_velocity = actual_movement / delta
	
	if expect_movement.y < actual_movement.y :
		_grounded = true
	elif _velocity.y != 0 :
		_grounded = false
		
	if _box_mover.has_stepped_up() :
		_velocity.y = _jump_force / 4
		_grounded = true
