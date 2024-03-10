extends WorldNode
	
func _enter_tree() -> void:
	world = World.new()
	world.start_rest()
	
func _exit_tree() -> void:
	world = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if world:
		world.progress(delta)
	
	$Layers/GameLayer/Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $Layers/GameLayer/Camera.transform
	
	$Layers/StarsLayer/Camera.transform.basis = transform.basis
	$Layers/StarsLayer/Stars.position = (-transform.origin / 10000)
	$Layers/StarsLayer/Galaxies.position = ((-transform.origin / 100000) / 100000)

	$Layers/GameLayer/Speed.text = "Speed: " + str($Layers/GameLayer/Camera.accelerator)

func load_galaxy(galaxy_directroy: String) -> void:
	pass
