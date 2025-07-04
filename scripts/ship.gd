extends CharacterBody3D

@export var max_speed = 150.0
@export var max_reverse_speed = 75.0  # Reverse is usually slower
@export var acceleration = 2.0
@export var pitch_speed = 3.0
@export var roll_speed = 2.5
@export var yaw_speed = 3.0
@export var input_response = 12.0
@export var mouse_sensitivity = 0.004

# NEW: Shooting properties
@export var laser_range = 1000.0
@export var laser_damage = 25.0

# Add these variables at the top with the others
@export var laser_color = Color.RED
@export var laser_width = 2.0
@export var laser_duration = 0.1

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
	if event.is_action_pressed("shoot"):
		shoot()
	
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

# NEW: Shooting function
func shoot():
	var space = get_world_3d().direct_space_state
	
	# Cast a ray from the ship's position forward
	var start_pos = global_position
	var end_pos = global_position + transform.basis.z * laser_range
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	var collision = space.intersect_ray(query)
	
	var laser_end = end_pos
	if collision:
		laser_end = collision.position
		print("Hit: ", collision.collider.name)
		# Optional: Update UI label if you added one
		if has_node("CanvasLayer/Label"):
			$CanvasLayer/Label.text = "Hit: " + collision.collider.name
		
		# Here you could add damage to the hit object
		if collision.collider.has_method("take_damage"):
			collision.collider.take_damage(laser_damage)
	else:
		print("Miss")
		if has_node("CanvasLayer/Label"):
			$CanvasLayer/Label.text = ""
	
	# Draw laser line (you'll need to implement this)
	draw_laser_line(start_pos, laser_end)

func draw_laser_line(start: Vector3, end: Vector3):
	# This is a simple approach - you can make this fancier
	var laser_line = Line3D.new()  # You'll need to create this or use a different approach
	get_parent().add_child(laser_line)
	laser_line.add_point(start)
	laser_line.add_point(end)
	laser_line.modulate = laser_color
	
	# Remove the line after a short duration
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = laser_duration
	timer.one_shot = true
	timer.timeout.connect(func(): laser_line.queue_free(); timer.queue_free())
	timer.start()

func _physics_process(delta):
	get_input(delta)
	
	# Apply rotations
	transform.basis = transform.basis.rotated(transform.basis.z,
			roll_input * roll_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.x,
			pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y,
			yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.orthonormalized()
	
	# Move forward or backward based on speed
	velocity = transform.basis.z * forward_speed
	move_and_collide(velocity * delta)
