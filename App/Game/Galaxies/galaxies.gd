extends MultiMeshInstance3D

func generate_galaxies() -> void:
	multimesh.instance_count = 10000
	
	for i in range(10000):
		var rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
		var position = Vector3(randfn(0, 8000), randfn(0, 8000), randfn(0, 8000))
		
		var transform: Transform3D
		transform.basis = Basis.from_euler(rotation, EULER_ORDER_XYZ)
		transform.origin = position
		
		multimesh.set_instance_transform(i, transform)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_galaxies()
