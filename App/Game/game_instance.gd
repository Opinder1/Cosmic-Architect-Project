extends Node

var world: UniverseSimulation

@export var mesh: Mesh

var scenario: RID
	
func _enter_tree() -> void:
	world = UniverseSimulation.new()
	
	scenario = $Layers/GameLayer.world_3d.scenario
	
	for i in range(100):
		var id = world.create_instance(mesh.get_rid(), scenario)
		
		world.set_instance_pos(id, Vector3(randf_range(-100, 100), randf_range(-100, 100), randf_range(-100, 100)))
	
func _exit_tree() -> void:
	world.stop_galaxy()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	world.progress(delta)
	
	$Layers/GameLayer/Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Layers/GameLayer/Camera.transform
	
	$Layers/StarsLayer/Camera.transform.basis = transform.basis
	$Layers/StarsLayer/Stars.position = (-transform.origin / 10000)
	$Layers/StarsLayer/Galaxies.position = ((-transform.origin / 100000) / 100000)

	$Layers/GameLayer/Speed.text = "Speed: " + str($Layers/GameLayer/Camera.accelerator)

func load_galaxy(galaxy_directory: String) -> void:
	world.set_threads(12)
	world.start_rest_server()
	world.start_local_galaxy(galaxy_directory)
