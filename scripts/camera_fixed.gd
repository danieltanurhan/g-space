extends Camera3D
class_name FixedCamera

@export var target_path: NodePath
var _target: Node3D

func _ready() -> void:
	_target = get_node_or_null(target_path) if target_path != NodePath() else null

func _process(delta: float) -> void:
	if _target:
		look_at(_target.global_transform.origin, Vector3.UP)