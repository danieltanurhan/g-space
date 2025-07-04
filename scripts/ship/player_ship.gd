extends CharacterBody3D

const ACCELERATION = 20.0         # units/s²
const MAX_SPEED = 60.0          # units/s
const ROT_SPEED = 1.5           # radians/s
const MOUSE_SENSITIVITY = 0.002

# Input actions expected:
#   move_forward  (e.g. W)
#   move_backward (S)
#   move_left     (A)
#   move_right    (D)
#   move_up       (Space)
#   move_down     (Ctrl)
#   turn_left     (Q)
#   turn_right    (E)
#   pitch_up      (Up)
#   pitch_down    (Down)
#   roll_left     (Z)
#   roll_right    (C)

func _ready():
	# Disable built-in gravity so the ship behaves in zero-G.
	# CharacterBody3D has no gravity_scale property; world handles zero-G via Area3D.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	_handle_translation(delta)
	_handle_rotation(delta)
	# Apply the computed velocity in a kinematic-friendly way.
	move_and_slide()

func _handle_translation(delta: float) -> void:
	var thrust := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		thrust -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		thrust += transform.basis.z
	if Input.is_action_pressed("move_left"):
		thrust -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		thrust += transform.basis.x
	if Input.is_action_pressed("move_up"):
		thrust += transform.basis.y
	if Input.is_action_pressed("move_down"):
		thrust -= transform.basis.y

	if thrust != Vector3.ZERO:
		thrust = thrust.normalized() * ACCELERATION * delta
		velocity += thrust
		velocity = velocity.limit_length(MAX_SPEED)

	# Optional micro-damping so the ship slowly drifts to a stop if no input.
	velocity *= 0.999

func _handle_rotation(delta: float) -> void:
	var yaw   := 0.0
	var pitch := 0.0
	var roll  := 0.0

	if Input.is_action_pressed("turn_left"):
		yaw += 1.0
	if Input.is_action_pressed("turn_right"):
		yaw -= 1.0
	if Input.is_action_pressed("pitch_up"):
		pitch += 1.0
	if Input.is_action_pressed("pitch_down"):
		pitch -= 1.0
	if Input.is_action_pressed("roll_left"):
		roll += 1.0
	if Input.is_action_pressed("roll_right"):
		roll -= 1.0

	if yaw != 0.0:
		rotate_y(yaw * ROT_SPEED * delta)
	if pitch != 0.0:
		rotate_object_local(Vector3.RIGHT, pitch * ROT_SPEED * delta)
	if roll != 0.0:
		rotate_object_local(Vector3.FORWARD, roll * ROT_SPEED * delta) 

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var rel: Vector2 = event.relative
		rotate_y(-rel.x * MOUSE_SENSITIVITY)
		rotate_object_local(Vector3.RIGHT, -rel.y * MOUSE_SENSITIVITY) 
