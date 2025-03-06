extends Screen

@onready var instance_schematic = preload("res://App/Game/game_instance.tscn")
	
func _enter_tree() -> void:
	UniverseSimulation.set_render_context(get_viewport().find_world_3d().scenario)
	
	UniverseSimulation.start_simulation(UniverseSimulation.THREAD_MODE_MULTI_THREADED)
	
func _exit_tree() -> void:
	UniverseSimulation.stop_simulation()
	
func start_game(save_directory: String) -> void:
	var game_instance = instance_schematic.instantiate()
	
	game_instance.save_directory = save_directory
	
	add_child(game_instance)
