extends SubViewportContainer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$GameLayer/Camera.do_camera_controls(delta)
	
	var transform: Transform3D = $GameLayer/Camera.transform
	
	$StarsLayer/Camera.transform.basis = transform.basis
	$StarsLayer/Stars.position = (-transform.origin / 10000)
	$StarsLayer/Galaxies.position = ((-transform.origin / 100000) / 100000)

	$GameLayer/Speed.text = "Speed: " + str($GameLayer/Camera.accelerator)
