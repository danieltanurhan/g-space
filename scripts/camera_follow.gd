extends Camera3D
class_name CameraFollow

@export var lerp_speed: float = 3.0
@export var target_path: NodePath
@export var offset: Vector3 = Vector3.ZERO

var _target: Node3D

func _ready() -> void:
	if target_path != NodePath():
		_target = get_node_or_null(target_path)

func _physics_process(delta: float) -> void:
	if _target == null:
		return

	var target_pos: Vector3 = _target.global_transform.translated_local(offset).origin
	global_transform.origin = global_transform.origin.lerp(target_pos, lerp_speed * delta)

	var new_basis = global_transform.looking_at(_target.global_transform.origin, _target.transform.basis.y)
	global_transform = global_transform.interpolate_with(new_basis, lerp_speed * delta)