extends Node3D

const VoxelMesh = preload("res://App/Game/voxel_mesh.gd")

var simulation: CosmicSimulation
var _ships: Dictionary = {}
var _stations: Dictionary = {}

func refresh() -> void:
	if simulation == null or not simulation.is_world_ready():
		for ship in _ships.values(): ship.free()
		_ships.clear()
		for station in _stations.values(): station.free()
		_stations.clear()
		return
	var present := {}
	for info in simulation.get_space_ships():
		present[info.id] = true
		if not _ships.has(info.id):
			var instance := MeshInstance3D.new()
			instance.name = "Ship_" + CosmicSimulation.instance_id_to_string(info.id)
			instance.mesh = VoxelMesh.build(simulation.get_space_ship_volume(info.id))
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.vertex_color_use_as_albedo = true
			instance.material_override = material
			add_child(instance)
			_ships[info.id] = instance
		var ship: MeshInstance3D = _ships[info.id]
		ship.transform = info.world_transform
		ship.scale = Vector3.ONE * info.voxel_size
	for id in _ships.keys():
		if not present.has(id):
			_ships[id].free()
			_ships.erase(id)
	var current_stations := {}
	for info in simulation.get_space_stations():
		current_stations[info.id] = true
		if not _stations.has(info.id):
			var station := MeshInstance3D.new()
			station.name = "Station_" + CosmicSimulation.instance_id_to_string(info.id)
			var deck := BoxMesh.new()
			deck.size = Vector3(info.radius * 2, info.radius / 8.0, info.radius * 2)
			station.mesh = deck
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.18, 0.23, 0.32)
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			station.material_override = material
			add_child(station)
			_stations[info.id] = station
		_stations[info.id].transform = info.transform * Transform3D(Basis.IDENTITY, Vector3(0, -info.radius / 16.0, 0))
	for id in _stations.keys():
		if not current_stations.has(id):
			_stations[id].free()
			_stations.erase(id)

func nearest_dock(ship: Dictionary) -> Dictionary:
	var result := {}
	var distance := INF
	var origin: Vector3 = ship.world_transform.origin
	for info in simulation.get_space_ships():
		if info.id == ship.id or info.voxel_size < ship.voxel_size * 3 or info.velocity.length() > 1.0: continue
		var berth: Vector3 = info.world_transform * Vector3(0, info.voxel_size * 3 + ship.voxel_size * 5, 0)
		var candidate := origin.distance_to(berth)
		if candidate < distance and candidate <= info.voxel_size * 3 + 80 * ship.voxel_size:
			result = {"type": "space_ship", "id": info.id}
			distance = candidate
	for station in simulation.get_space_stations():
		if station.radius < ship.voxel_size * 16: continue
		var berth: Vector3 = station.transform * Vector3(0, ship.voxel_size * 5, 0)
		var candidate := origin.distance_to(berth)
		if candidate < distance and candidate <= station.radius + 80 * ship.voxel_size:
			result = {"type": "space_station", "id": station.id}
			distance = candidate
	return result

func follow_camera(camera: Camera3D, info: Dictionary) -> void:
	var pose: Transform3D = info.world_transform
	var unit: float = info.voxel_size
	camera.transform = pose * Transform3D(Basis(), Vector3(0, 9, 27) * unit)
	camera.look_at(pose.origin, pose.basis.y)
	camera.near = maxf(unit * 0.02, 0.00001)
