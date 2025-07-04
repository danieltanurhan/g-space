extends CharacterBody3D

@export var max_speed: float = 50.0
@export var acceleration: float = 0.6
@export var pitch_speed: float = 1.5
@export var roll_speed: float = 1.9
@export var yaw_speed: float = 1.25 # linked to roll
@export var input_response: float = 8.0

var forward_speed: float = 0.0
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	_get_input(delta)
	# Apply rotations
	transform.basis = transform.basis.rotated(transform.basis.z, roll_input * roll_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.orthonormalized()

	# Forward movement
	velocity = -transform.basis.z * forward_speed
	move_and_collide(velocity * delta)

func _get_input(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		forward_speed = lerp(forward_speed, max_speed, acceleration * delta)
	elif Input.is_action_pressed("throttle_down"):
		forward_speed = lerp(forward_speed, 0.0, acceleration * delta)

	pitch_input = lerp(pitch_input, Input.get_axis("pitch_down", "pitch_up"), input_response * delta)
	roll_input = lerp(roll_input, Input.get_axis("roll_right", "roll_left"), input_response * delta)
	# Link yaw to roll for atmospheric style handling; could be separate Input axis
	yaw_input = roll_input

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
