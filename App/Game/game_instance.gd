extends Node

var simulation: UniverseSimulation

@export var mesh: Mesh

func _enter_tree() -> void:
	pass
	
func _exit_tree() -> void:
	if simulation != null:
		simulation.stop_simulation()
		
		simulation = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!simulation.progress(delta)):
		printerr("world progress failed")
	
	$Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Camera.transform
	
	simulation.debug_command(&"set_debug_camera_transform", [transform])
	
	$Speed.text = "Speed: " + str($Camera.accelerator)

func load_galaxy(galaxy_directory: String) -> void:
	simulation = UniverseSimulation.new()
	
	simulation.initialize(galaxy_directory, "full_galaxy", UniverseSimulation.SERVER_TYPE_LOCAL, get_viewport().find_world_3d().scenario)
	
	$Camera.make_current()
	
	simulation.start_simulation(UniverseSimulation.THREAD_MODE_MULTI_THREADED)
