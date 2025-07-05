extends Area3D

@export var speed: float = 1200.0
@export var lifetime: float = 2.0

var _velocity: Vector3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2
	_velocity = transform.basis.z * speed
	set_as_top_level(true)

func _physics_process(delta: float) -> void:
	translate(_velocity * delta)
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	print("Bullet hit: ", body.name)
	
	if body is GridMap:
		handle_gridmap_hit(body)
	elif body.has_method("take_damage"):
		body.take_damage(10)
	
	queue_free()

func handle_gridmap_hit(gridmap: GridMap) -> void:
	# Get the hit position in world coordinates
	var hit_pos = global_position
	
	# Convert world position to GridMap local coordinates
	var local_pos = gridmap.to_local(hit_pos)
	
	# Get the GridMap cell coordinates
	var cell_coords = gridmap.local_to_map(local_pos)
	
	# Get the current cell item (asteroid type)
	var cell_item = gridmap.get_cell_item(cell_coords)
	
	if cell_item != GridMap.INVALID_CELL_ITEM:
		print("Hit asteroid at cell: ", cell_coords, " Item ID: ", cell_item)
		
		# Remove the hit asteroid
		gridmap.set_cell_item(cell_coords, GridMap.INVALID_CELL_ITEM)
		
		# Spawn smaller asteroid pieces
		spawn_asteroid_debris(gridmap, cell_coords, cell_item)

func spawn_asteroid_debris(gridmap: GridMap, cell_coords: Vector3i, original_item: int) -> void:
	# Define asteroid sizes (you'll need to match these to your mesh library)
	# Assuming: 0 = Large, 1 = Medium, 2 = Small
	
	match original_item:
		0: # Large asteroid hit - spawn 2-3 medium asteroids
			spawn_debris_pieces(gridmap, cell_coords, 1, 3)
		1: # Medium asteroid hit - spawn 2-3 small asteroids  
			spawn_debris_pieces(gridmap, cell_coords, 2, 3)
		2: # Small asteroid hit - just destroy it
			print("Small asteroid destroyed!")
		_:
			print("Unknown asteroid type: ", original_item)

func spawn_debris_pieces(gridmap: GridMap, center_coords: Vector3i, new_item_id: int, count: int) -> void:
	# Spawn pieces around the original position
	var offsets = [
		Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), 
		Vector3i(0, 0, 1), Vector3i(-1, 0, -1), Vector3i(1, 0, 1)
	]
	
	for i in range(min(count, offsets.size())):
		var new_coords = center_coords + offsets[i]
		
		# Check if the position is empty
		if gridmap.get_cell_item(new_coords) == GridMap.INVALID_CELL_ITEM:
			gridmap.set_cell_item(new_coords, new_item_id)
