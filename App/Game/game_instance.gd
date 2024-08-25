extends Node

var universe : Universe
var simulation: UniverseSimulation

@export var mesh: Mesh

func _enter_tree() -> void:
	universe = Universe.new()
	
func _exit_tree() -> void:
	if simulation != null:
		simulation.stop_simulation()
		
		universe.uninitialize(simulation)
		
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
	simulation = universe.initialize_local_galaxy(galaxy_directory)
	
	$Camera.make_current()
	
	var render_info := UniverseRenderInfo.new()
	
	render_info.scenario = get_viewport().find_world_3d().scenario
	
	simulation.start_renderer(render_info)
	
	render_info.free()
	
	simulation.start_simulation(UniverseSimulation.THREAD_MODE_MULTI_THREADED)
