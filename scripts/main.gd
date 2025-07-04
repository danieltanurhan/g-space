extends Node3D

@export var sky_texture: Texture2D = preload("res://textures/hdr/default_sky.jpg")
@export var ship_scene: PackedScene = preload("res://scenes/player_ship.tscn")
var cameras: Array[Camera3D] = []
var current_camera_index: int = 0

func _ready():
	_setup_skybox()
	_spawn_player_ship()
	_setup_cameras()

func _setup_skybox():
	# Create a WorldEnvironment with a PanoramaSky using the provided texture.
	var skybox := Skybox.new()
	skybox.setup(sky_texture)
	add_child(skybox)

func _setup_cameras():
	var ship = $PlayerShip if has_node("PlayerShip") else null
	if ship == null:
		push_warning("PlayerShip not found, cameras not created")
		return

	# Chase camera with smooth follow
	var chase_cam := Camera3D.new()
	chase_cam.name = "ChaseCamera"
	chase_cam.current = true
	chase_cam.transform.origin = Vector3(0, 5, 10)
	var follow_script := load("res://scripts/camera_follow.gd")
	chase_cam.set_script(follow_script)
	chase_cam.target_path = ship.get_path()
	chase_cam.offset = Vector3(0, 5, 10)
	add_child(chase_cam)
	cameras.append(chase_cam)

	# Fixed camera looking at ship
	var fixed_cam := Camera3D.new()
	fixed_cam.name = "FixedCamera"
	fixed_cam.transform.origin = Vector3(0, 0, 25)
	var fixed_script := load("res://scripts/camera_fixed.gd")
	fixed_cam.set_script(fixed_script)
	fixed_cam.target_path = ship.get_path()
	add_child(fixed_cam)
	cameras.append(fixed_cam)

func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next") and cameras.size() > 1:
		current_camera_index = wrapi(current_camera_index + 1, 0, cameras.size())
		for i in range(cameras.size()):
			cameras[i].current = i == current_camera_index

func _spawn_player_ship():
	if ship_scene:
		var ship := ship_scene.instantiate()
		ship.name = "PlayerShip"
		add_child(ship)