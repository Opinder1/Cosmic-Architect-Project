extends Screen

@onready var instance_schematic = preload("res://App/Game/game_instance.tscn")
	
func _enter_tree() -> void:
	UniverseServer.set_render_context(get_viewport().find_world_3d().scenario)
	
	UniverseServer.start_simulation(UniverseServer.THREAD_MODE_MULTI_THREADED)
	
func _exit_tree() -> void:
	UniverseServer.stop_simulation()
	
func start_game(save_directory: String) -> void:
	var game_instance = instance_schematic.instantiate()
	
	game_instance.save_directory = save_directory
	
	add_child(game_instance)
