extends CharacterBody3D

@export var max_speed = 150.0
@export var max_reverse_speed = 75.0  # Reverse is usually slower
@export var acceleration = 2.0
@export var pitch_speed = 3.0
@export var roll_speed = 2.5
@export var yaw_speed = 3.0
@export var input_response = 12.0
@export var mouse_sensitivity = 0.004
# Bullet system exports
@export var BulletScene: PackedScene
@export var fire_rate_hz: float = 10.0
var _cooldown: float = 0.0
@onready var gun_mount: Node3D = $GunMount

var forward_speed = 0.0
var pitch_input = 0.0
var roll_input = 0.0
var yaw_input = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Mouse X controls yaw (left/right)
		yaw_input += -event.relative.x * mouse_sensitivity
		# Mouse Y controls pitch (up/down) - Fixed: not inverted
		pitch_input += event.relative.y * mouse_sensitivity
		
		# Clamp the inputs to reasonable values
		yaw_input = clamp(yaw_input, -1.0, 1.0)
		pitch_input = clamp(pitch_input, -1.0, 1.0)
	
	# NEW: Shooting input
	# shooting handled in _physics_process using cooldown
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_input(delta):
	# Forward and reverse controls
	if Input.is_action_pressed("throttle_up"):
		forward_speed = lerp(forward_speed, max_speed, acceleration * delta)
	elif Input.is_action_pressed("throttle_down"):
		forward_speed = lerp(forward_speed, -max_reverse_speed, acceleration * delta)
	else:
		# Gradually slow down to stop when no input
		forward_speed = lerp(forward_speed, 0.0, acceleration * delta)

	# Roll controls
	var keyboard_roll = Input.get_axis("roll_left", "roll_right")
	roll_input = lerp(roll_input, keyboard_roll, input_response * delta)
	
	# Optional keyboard backup controls
	var keyboard_pitch = Input.get_axis("pitch_down", "pitch_up")
	var keyboard_yaw = Input.get_axis("yaw_left", "yaw_right")
	
	# Gradually return to center when no input
	if abs(keyboard_pitch) < 0.1:
		pitch_input = lerp(pitch_input, 0.0, input_response * 0.8 * delta)
	else:
		pitch_input = lerp(pitch_input, keyboard_pitch, input_response * delta)
		
	if abs(keyboard_yaw) < 0.1:
		yaw_input = lerp(yaw_input, 0.0, input_response * 0.8 * delta)
	else:
		yaw_input = lerp(yaw_input, keyboard_yaw, input_response * delta)

# Bullet firing function
func shoot():
	if not BulletScene:
		print("BulletScene not assigned!")
		return
	
	if not has_node("GunMount"):
		print("GunMount node not found!")
		return
	
	var new_bullet = BulletScene.instantiate()
	
	# Add bullet to the scene tree FIRST
	get_tree().current_scene.add_child(new_bullet)
	
	# THEN set its transform
	new_bullet.global_transform = gun_mount.global_transform

func _physics_process(delta):
	# bullet firing cooldown
	_cooldown = max(_cooldown - delta, 0.0)
	if Input.is_action_pressed("shoot") and _cooldown == 0.0:
		shoot()
		_cooldown = 1.0 / fire_rate_hz

	get_input(delta)
	
	# Apply rotations - FIX: normalize the axis vectors
	transform.basis = transform.basis.rotated(transform.basis.z.normalized(),
			roll_input * roll_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.x.normalized(),
			pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y.normalized(),
			yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.orthonormalized()
	
	# Move forward or backward based on speed
	velocity = transform.basis.z * forward_speed
	move_and_collide(velocity * delta)
