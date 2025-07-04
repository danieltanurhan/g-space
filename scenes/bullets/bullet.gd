extends Area3D

@export var speed: float = 1200.0 # units per second
@export var lifetime: float = 2.0 # seconds before self-destruct

var _velocity: Vector3

func _ready() -> void:
	# Assuming forward direction is -Z for the mesh/scene
	_velocity = -transform.basis.z * speed
	set_as_top_level(true) # Detach from parent transform so it moves independently

func _physics_process(delta: float) -> void:
	translate(_velocity * delta)
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_Bullet_body_entered(body: Node) -> void:
	# Placeholder: apply damage if target has appropriate method
	if body.has_method("take_damage"):
		body.take_damage(10)
	queue_free()