extends GridMap

# Export variables for configuration
@export var field_size: Vector3i = Vector3i(50, 10, 50)  # Size of asteroid field
@export var asteroid_density: float = 0.1  # Percentage of cells to fill (0.0 to 1.0)
@export var min_distance_from_center: float = 10.0  # Keep area around spawn clear
@export var use_random_seed: bool = true
@export var random_seed: int = 12345

# Asteroid types from mesh library (0-based indices)
@export var large_asteroid_indices: Array[int] = [0, 1, 2]  # Large asteroids
@export var medium_asteroid_indices: Array[int] = [3, 4, 5]  # Medium asteroids  
@export var small_asteroid_indices: Array[int] = [6, 7, 8]  # Small asteroids

# Internal tracking
var asteroid_health: Dictionary = {}  # Track health of each cell
var asteroid_sizes: Dictionary = {}   # Track size of each cell

func _ready():
	if use_random_seed:
		seed(random_seed)
	
	populate_asteroid_field()

func populate_asteroid_field():
	print("Populating asteroid field...")
	
	# Clear existing asteroids
	clear()
	asteroid_health.clear()
	asteroid_sizes.clear()
	
	var asteroids_placed = 0
	var total_attempts = 0
	var max_attempts = field_size.x * field_size.y * field_size.z
	
	while asteroids_placed < (max_attempts * asteroid_density) and total_attempts < max_attempts * 2:
		total_attempts += 1
		
		# Generate random position
		var x = randi_range(-field_size.x/2, field_size.x/2)
		var y = randi_range(-field_size.y/2, field_size.y/2)
		var z = randi_range(-field_size.z/2, field_size.z/2)
		
		var cell_pos = Vector3i(x, y, z)
		
		# Skip if too close to center (spawn area)
		if Vector3(x, y, z).length() < min_distance_from_center:
			continue
		
		# Skip if cell already occupied
		if get_cell_item(cell_pos) != -1:
			continue
		
		# Choose random asteroid type and size
		var asteroid_data = _choose_random_asteroid()
		var mesh_index = asteroid_data.mesh_index
		var size = asteroid_data.size
		
		# Place asteroid with random rotation (Godot 4 style)
		var rotation = randi_range(0, 23)  # GridMap has 24 possible rotations
		set_cell_item(cell_pos, mesh_index, rotation)
		
		# Store asteroid data
		asteroid_health[cell_pos] = _get_health_for_size(size)
		asteroid_sizes[cell_pos] = size
		
		asteroids_placed += 1
	
	print("Placed ", asteroids_placed, " asteroids in ", total_attempts, " attempts")

func _choose_random_asteroid() -> Dictionary:
	var rand_val = randf()
	
	# 60% large, 30% medium, 10% small
	if rand_val < 0.6:
		return {
			"mesh_index": large_asteroid_indices[randi() % large_asteroid_indices.size()],
			"size": "large"
		}
	elif rand_val < 0.9:
		return {
			"mesh_index": medium_asteroid_indices[randi() % medium_asteroid_indices.size()],
			"size": "medium"
		}
	else:
		return {
			"mesh_index": small_asteroid_indices[randi() % small_asteroid_indices.size()],
			"size": "small"
		}

func _get_health_for_size(size: String) -> int:
	match size:
		"large": return 3
		"medium": return 2
		"small": return 1
		_: return 1

func hit_asteroid_at_position(world_pos: Vector3, damage: int = 1):
	# Convert world position to grid coordinates
	var local_pos = to_local(world_pos)
	var cell_pos = local_to_map(local_pos)
	
	# Check if there's an asteroid at this position
	if get_cell_item(cell_pos) == -1:
		return false  # No asteroid here
	
	print("Hit asteroid at cell: ", cell_pos)
	
	# Reduce health
	if asteroid_health.has(cell_pos):
		asteroid_health[cell_pos] -= damage
		
		if asteroid_health[cell_pos] <= 0:
			_split_or_destroy_asteroid(cell_pos)
		
		return true
	
	return false

func _split_or_destroy_asteroid(cell_pos: Vector3i):
	var size = asteroid_sizes.get(cell_pos, "small")
	
	# Remove original asteroid
	set_cell_item(cell_pos, -1)
	asteroid_health.erase(cell_pos)
	asteroid_sizes.erase(cell_pos)
	
	# Create split pieces if not small
	if size == "large":
		_create_split_pieces(cell_pos, "medium", 3)
	elif size == "medium":
		_create_split_pieces(cell_pos, "small", 2)
	else:
		# Small asteroid - just destroy with particle effect
		_create_destruction_effect(cell_pos)

func _create_split_pieces(original_pos: Vector3i, new_size: String, count: int):
	var mesh_indices = []
	match new_size:
		"medium": mesh_indices = medium_asteroid_indices
		"small": mesh_indices = small_asteroid_indices
	
	for i in range(count):
		# Find nearby empty cell
		var offset = Vector3i(
			randi_range(-2, 2),
			randi_range(-1, 1),
			randi_range(-2, 2)
		)
		var new_pos = original_pos + offset
		
		# Make sure cell is empty
		if get_cell_item(new_pos) != -1:
			continue
		
		# Place new asteroid piece with random rotation
		var mesh_index = mesh_indices[randi() % mesh_indices.size()]
		var rotation = randi_range(0, 23)
		set_cell_item(new_pos, mesh_index, rotation)
		
		# Store data
		asteroid_health[new_pos] = _get_health_for_size(new_size)
		asteroid_sizes[new_pos] = new_size
	
	_create_destruction_effect(original_pos)

func _create_destruction_effect(cell_pos: Vector3i):
	# Convert cell position to world position
	var world_pos = map_to_local(cell_pos)
	
	# Create simple particle effect (you can enhance this)
	print("Asteroid destroyed at: ", world_pos)
	
	# Optional: Spawn debris particles here
	# You could instantiate a particle system or debris objects
