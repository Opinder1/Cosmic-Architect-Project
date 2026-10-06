extends Node

@export var mesh: Mesh

@export var save_directory: String

func _enter_tree() -> void:
	$Camera.make_current()
	
func _exit_tree() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Camera.do_camera_controls(delta)

func connected_to_universe() -> void:
	pass
