extends Control

signal host_requested
signal join_requested

func _on_host_button_pressed():
	print("Host Game pressed")
	host_requested.emit()

func _on_join_button_pressed():
	print("Join Game pressed")
	join_requested.emit()

func _on_exit_button_pressed():
	get_tree().quit() 
