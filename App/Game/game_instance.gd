extends Node

var universe : Universe
var simulation: UniverseSimulation

@export var mesh: Mesh

func _enter_tree() -> void:
	universe = Universe.new()
	
func _exit_tree() -> void:
	if simulation != null:
		simulation.stop_simulation()
		
		simulation.finished_unloading()
		
		simulation = null
		
	universe = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!simulation.progress(delta)):
		printerr("world progress failed")
	
	$Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Camera.transform
	
	$Speed.text = "Speed: " + str($Camera.accelerator)

func load_galaxy(galaxy_directory: String) -> void:
	simulation = UniverseSimulation.new()
	
	simulation.initialize(universe, galaxy_directory, "full_galaxy", UniverseSimulation.SERVER_TYPE_LOCAL, get_viewport().find_world_3d().scenario)
	
	$Camera.make_current()
	
	simulation.start_simulation(UniverseSimulation.THREAD_MODE_MULTI_THREADED)
	
	simulation.finished_loading()
