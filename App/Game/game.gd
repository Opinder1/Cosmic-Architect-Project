extends Screen

var simulation: UniverseSimulation

@onready var instance_schematic = preload("res://App/Game/game_instance.tscn")

func _enter_tree() -> void:
	simulation = UniverseSimulation.new()
	
	simulation.initialize(ProjectSettings.get_setting("voxel_game/universe/path"), get_viewport().find_world_3d().scenario)
	
	simulation.start_simulation(UniverseSimulation.THREAD_MODE_MULTI_THREADED)
	
func _exit_tree() -> void:
	simulation.stop_simulation()
	
	simulation = null
	
func start_game(save_directory: String) -> void:
	var instance: Node = instance_schematic.instantiate()
	
	instance.simulation = simulation
	
	add_child(instance)
	
	instance.load_galaxy(save_directory)
