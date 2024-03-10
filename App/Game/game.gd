extends Screen

@onready var instance_schematic = preload("res://App/Game/game_instance.tscn")

func start_game(save_directory: String) -> void:
	var instance: Node = instance_schematic.instantiate()
	
	add_child(instance)
	
	instance.load_galaxy(save_directory)
