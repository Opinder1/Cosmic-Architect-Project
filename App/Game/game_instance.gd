extends Node

var simulation: UniverseSimulation

@export var mesh: Mesh

func _enter_tree() -> void:
	simulation.connect(&"connected_to_galaxy", connected_to_galaxy)
	
func _exit_tree() -> void:
	simulation.disconnect_from_galaxy()
	
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
	$Camera.make_current()
	
	simulation.start_local_galaxy(galaxy_directory, &"full_galaxy", UniverseSimulation.SERVER_TYPE_LOCAL)

func connected_to_galaxy() -> void:
	pass
