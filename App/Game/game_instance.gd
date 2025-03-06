extends Node

var save_directory: String

@export var mesh: Mesh

func _enter_tree() -> void:
	UniverseServer.connect(&"connected_to_galaxy", connected_to_galaxy)
	
	UniverseServer.start_local_galaxy(save_directory, "full_galaxy", UniverseServer.SERVER_TYPE_LOCAL)
	
	$Camera.make_current()
	
func _exit_tree() -> void:
	UniverseServer.disconnect_from_galaxy()
	
	UniverseServer.disconnect(&"connected_to_galaxy", connected_to_galaxy)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!UniverseServer.progress(delta)):
		printerr("world progress failed")
	
	$Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Camera.transform
	
	UniverseServer.debug_command(&"set_debug_camera_transform", [transform])
	
	$Speed.text = "Speed: " + str($Camera.accelerator)

func connected_to_galaxy() -> void:
	pass
