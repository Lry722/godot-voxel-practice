extends Camera3D

@export var _seneitive = 0.1
@export var _max_angle = 89.0
@export var _min_angle = -89.0

var _pitch := 0.0
var _yaw := 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion :
		var motion = event.relative * _seneitive
		_pitch -= motion.y
		_pitch = clamp(_pitch, _min_angle, _max_angle)
		_yaw -= motion.x
		
		rotation = Vector3()
		rotate_x(deg_to_rad(_pitch))
		rotate_y(deg_to_rad(_yaw))
		
		
