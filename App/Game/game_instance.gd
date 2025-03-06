extends Node

var save_directory: String

@export var mesh: Mesh

func _enter_tree() -> void:
	UniverseSimulation.connect(&"connected_to_galaxy", connected_to_galaxy)
	
	UniverseSimulation.start_local_galaxy(save_directory, "full_galaxy", UniverseSimulation.SERVER_TYPE_LOCAL)
	
	$Camera.make_current()
	
func _exit_tree() -> void:
	UniverseSimulation.disconnect_from_galaxy()
	
	UniverseSimulation.disconnect(&"connected_to_galaxy", connected_to_galaxy)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!UniverseSimulation.progress(delta)):
		printerr("world progress failed")
	
	$Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Camera.transform
	
	UniverseSimulation.debug_command(&"set_debug_camera_transform", [transform])
	
	$Speed.text = "Speed: " + str($Camera.accelerator)

func connected_to_galaxy() -> void:
	pass
