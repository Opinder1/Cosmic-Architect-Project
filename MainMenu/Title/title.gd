extends Node


func _ready():
	get_child(0).pressed.connect(_on_singleplayer_pressed)
	get_child(1).pressed.connect(_on_multiplayer_pressed)
	get_child(2).pressed.connect(_on_options_pressed)
	get_child(3).pressed.connect(_on_exit_pressed)


func _on_singleplayer_pressed():
	get_parent().set_menu("GameList")


func _on_multiplayer_pressed():
	pass


func _on_options_pressed():
	pass


func _on_exit_pressed():
	get_tree().quit()
