extends Node3D

@export var sky_texture: Texture2D = preload("res://textures/hdr/default_sky.hdr")
@export var ship_scene: PackedScene
@export var camera_start_position: Vector3 = Vector3(0, 3, 8)

func _ready():
	_setup_skybox()
	_setup_camera()
	_spawn_player_ship()

func _setup_skybox():
	# Create a WorldEnvironment with a PanoramaSky using the provided texture.
	var skybox := Skybox.new()
	skybox.setup(sky_texture)
	add_child(skybox)

func _setup_camera():
	var cam := Camera3D.new()
	cam.transform.origin = camera_start_position
	cam.look_at(Vector3.ZERO, Vector3.UP)
	cam.current = true
	add_child(cam)

func _spawn_player_ship():
	if ship_scene:
		var ship := ship_scene.instantiate()
		add_child(ship)