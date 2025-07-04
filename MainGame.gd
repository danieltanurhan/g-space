extends Node

@export var player_ship_scene: PackedScene = preload("res://Game/Ship/player_ship.tscn")

@onready var main_menu: Control = $MainMenu
@onready var space_world: Node3D = $SpaceWorld

func _ready():
	main_menu.connect("host_requested", Callable(self, "_on_host_requested"))
	main_menu.connect("join_requested", Callable(self, "_on_join_requested"))
	space_world.visible = false

func _on_host_requested():
	main_menu.hide()
	_start_game(true)

func _on_join_requested():
	main_menu.hide()
	_start_game(false)

func _start_game(host: bool):
	space_world.visible = true
	var ship := player_ship_scene.instantiate()
	space_world.add_child(ship)
	ship.global_transform.origin = Vector3.ZERO
	if host:
		print("Hosting game – world and ship spawned.")
	else:
		print("Joining game – placeholder, networking logic pending.")
