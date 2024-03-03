extends SubViewportContainer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var transform: Transform3D = $GameLayer/Camera.transform
	
	$StarsLayer/Camera.transform.basis = transform.basis
	$StarsLayer/Stars.position = (-transform.origin / 1000000000)
	$StarsLayer/Galaxies.position = ((-transform.origin / 1000000000) / 1000000000)

	$GameLayer/Speed.text = "Speed: " + str($GameLayer/Camera.accelerator)
