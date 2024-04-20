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
	
	simulation.start_simulation(UniverseSimulation.THREAD_MODE_SINGLE_THREADED)
	
	var scenario: RID = $Layers/GameLayer.find_world_3d().scenario
	
	for i in range(100):
		var id: int = simulation.create_instance(mesh.get_rid(), scenario)
		
		simulation.set_instance_pos(id, Vector3(randf_range(-100, 100), randf_range(-100, 100), randf_range(-100, 100)))
