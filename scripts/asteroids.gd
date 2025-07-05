extends StaticBody3D
class_name Asteroid

# Asteroid size types
enum Size {
	LARGE,
	MEDIUM,
	SMALL
}

# Export variables for configuration
@export var asteroid_size: Size = Size.LARGE
@export var health: int = 1
@export var split_count: int = 3  # How many pieces to split into
@export var split_force: float = 200.0  # Force applied to split pieces
@export var rotation_speed: float = 1.0  # Random rotation speed

# Asteroid meshes for different sizes (assign in editor)
@export var large_mesh: Mesh
@export var medium_mesh: Mesh  
@export var small_mesh: Mesh

# Internal variables
var _angular_velocity: Vector3
var _linear_velocity: Vector3

func _ready():
	# Set up collision detection
	# No body_entered for StaticBody3D - bullets will detect us
	
	# Add random rotation
	_angular_velocity = Vector3(
		randf_range(-rotation_speed, rotation_speed),
		randf_range(-rotation_speed, rotation_speed),
		randf_range(-rotation_speed, rotation_speed)
	)
	
	# Set collision layers
	collision_layer = 2  # Asteroid layer
	collision_mask = 0   # Don't collide with anything
	
	# Set appropriate mesh based on size
	_set_scale_for_size()

func _set_scale_for_size():
	var parent_node = get_parent()
	match asteroid_size:
		Size.LARGE:
			parent_node.scale = Vector3.ONE
		Size.MEDIUM:
			parent_node.scale = Vector3.ONE * 0.6
		Size.SMALL:
			parent_node.scale = Vector3.ONE * 0.3

func _physics_process(delta):
	# Apply rotation
	rotate_x(_angular_velocity.x * delta)
	rotate_y(_angular_velocity.y * delta)
	rotate_z(_angular_velocity.z * delta)
	
	# Apply movement if any
	if _linear_velocity.length() > 0.1:
		global_position += _linear_velocity * delta
		_linear_velocity = _linear_velocity.lerp(Vector3.ZERO, 0.5 * delta)

func take_damage(damage: int):
	print("asteroid hit");
	health -= damage
	if health <= 0:
		_split_asteroid()

func _split_asteroid():
	# Don't split if already small
	if asteroid_size == Size.SMALL:
		_destroy_asteroid()
		return
	
	# Determine next size
	var next_size = Size.MEDIUM if asteroid_size == Size.LARGE else Size.SMALL
	
	# Create split pieces
	for i in range(split_count):
		_create_split_piece(next_size, i)
	
	# Destroy original
	_destroy_asteroid()

func _create_split_piece(size: Size, index: int):
	# Get the parent asteroid node (MeshInstance3D level)
	var parent_asteroid = get_parent()
	var new_asteroid_node = parent_asteroid.duplicate()
	parent_asteroid.get_parent().add_child(new_asteroid_node)
	
	# Get the StaticBody3D from the new asteroid
	var new_asteroid_body = new_asteroid_node.get_node("StaticBody3D")
	
	# Set new size
	new_asteroid_body.asteroid_size = size
	new_asteroid_body._set_scale_for_size()
	
	# Random position offset
	var offset = Vector3(
		randf_range(-2.0, 2.0),
		randf_range(-2.0, 2.0),
		randf_range(-2.0, 2.0)
	)
	new_asteroid_node.global_position = global_position + offset
	
	# Add splitting force
	var direction = offset.normalized()
	new_asteroid_body._linear_velocity = direction * split_force * randf_range(0.5, 1.5)
	
	# Random rotation
	new_asteroid_body._angular_velocity = Vector3(
		randf_range(-rotation_speed * 2, rotation_speed * 2),
		randf_range(-rotation_speed * 2, rotation_speed * 2),
		randf_range(-rotation_speed * 2, rotation_speed * 2)
	)

func _destroy_asteroid():
	# Optional: Create destruction effects here
	_create_debris_particles()
	get_parent().queue_free()  # Remove the whole asteroid node

func _create_debris_particles():
	# Simple debris effect
	for i in range(5):
		var debris = preload("res://scenes/star.tscn").instantiate()
		get_parent().get_parent().add_child(debris)
		debris.global_position = global_position + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		# Make debris fade out
		var tween = create_tween()
		tween.tween_property(debris, "modulate:a", 0.0, 2.0)
		tween.tween_callback(debris.queue_free)
