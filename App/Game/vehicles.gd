extends Node3D

const VoxelMesh = preload("res://App/Game/voxel_mesh.gd")
var simulation: CosmicSimulation
var _vehicles: Dictionary = {}

func refresh() -> void:
	if simulation == null or not simulation.is_world_ready():
		for vehicle in _vehicles.values(): vehicle.free()
		_vehicles.clear()
		return
	var present := {}
	for info in simulation.get_vehicles():
		present[info.id] = true
		if not _vehicles.has(info.id):
			var vehicle := MeshInstance3D.new()
			vehicle.name = "Vehicle_" + CosmicSimulation.instance_id_to_string(info.id)
			vehicle.mesh = VoxelMesh.build(simulation.get_vehicle_volume(info.id))
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.vertex_color_use_as_albedo = true
			vehicle.material_override = material
			add_child(vehicle)
			_vehicles[info.id] = vehicle
		_vehicles[info.id].transform = info.world_transform
		_vehicles[info.id].scale = Vector3.ONE * info.voxel_size
	for id in _vehicles.keys():
		if not present.has(id):
			_vehicles[id].free()
			_vehicles.erase(id)

func follow_camera(camera: Camera3D, info: Dictionary) -> void:
	var pose: Transform3D = info.world_transform
	var unit: float = info.voxel_size
	var target := pose * (Vector3(0, 2, 0) * unit)
	# Keep mouse look as an orbit around the rover, independently of steering.
	camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(65), deg_to_rad(10))
	camera.position = target + camera.basis.z * 28 * unit
	if simulation.get_observer_planet() != Vector4i.ZERO:
		var height := simulation.get_planet_surface_height(camera.position.x, camera.position.z)
		if is_finite(height): camera.position.y = maxf(camera.position.y, height + unit)
	camera.look_at(target, pose.basis.y)
	camera.near = maxf(unit * 0.02, 0.00001)
