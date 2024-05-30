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
	
	$Layers/GameLayer/Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Layers/GameLayer/Camera.transform
	
	$Layers/StarsLayer/Camera.transform.basis = transform.basis
	$Layers/StarsLayer/Stars.position = (-transform.origin / 10000)
	$Layers/StarsLayer/Galaxies.position = ((-transform.origin / 100000) / 100000)
	
	$Layers/GameLayer/Speed.text = "Speed: " + str($Layers/GameLayer/Camera.accelerator)

func load_galaxy(galaxy_directory: String) -> void:
	simulation = universe.initialize_local_galaxy(galaxy_directory)
	
	var render_info: UniverseRenderInfo = UniverseRenderInfo.new()
	
	var game_scenario: RID = $Layers/GameLayer.find_world_3d().scenario
	render_info.main_scenario = game_scenario
	
	var star_scenario: RID = $Layers/StarsLayer.find_world_3d().scenario
	render_info.star_scenario = star_scenario
	render_info.galaxy_scenario = game_scenario
	
	simulation.start_renderer(render_info)
	
	render_info.free()
	
	simulation.start_simulation(UniverseSimulation.THREAD_MODE_MULTI_THREADED)
