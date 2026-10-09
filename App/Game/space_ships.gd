extends Node3D

var simulation: CosmicSimulation
var _ships: Dictionary = {}
var _ports: Dictionary = {}

func refresh() -> void:
	if simulation == null or not simulation.is_world_ready():
		for ship in _ships.values(): ship.free()
		_ships.clear()
		for port in _ports.values(): port.free()
		_ports.clear()
		return
	var present := {}
	for info in simulation.get_space_ships():
		present[info.id] = true
		if not _ships.has(info.id):
			var instance := MeshInstance3D.new()
			instance.name = "Ship_" + str(info.id)
			instance.mesh = _voxel_mesh(simulation.get_space_ship_volume(info.id))
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
	var current_ports := {}
	for info in simulation.get_ship_ports():
		current_ports[info.id] = true
		if not _ports.has(info.id):
			var port := MeshInstance3D.new()
			var deck := BoxMesh.new()
			deck.size = Vector3(info.radius * 2, info.radius / 8.0, info.radius * 2)
			port.mesh = deck
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.18, 0.23, 0.32)
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			port.material_override = material
			add_child(port)
			_ports[info.id] = port
		_ports[info.id].transform = info.transform * Transform3D(Basis.IDENTITY, Vector3(0, -info.radius / 16.0, 0))
	for id in _ports.keys():
		if not current_ports.has(id):
			_ports[id].free()
			_ports.erase(id)

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
	for port in simulation.get_ship_ports():
		if port.radius < ship.voxel_size * 16: continue
		var berth: Vector3 = port.transform * Vector3(0, ship.voxel_size * 5, 0)
		var candidate := origin.distance_to(berth)
		if candidate < distance and candidate <= port.radius + 80 * ship.voxel_size:
			result = {"type": "space_station", "id": port.id}
			distance = candidate
	return result

func _voxel_mesh(blocks: PackedByteArray) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var normals := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	var palette := [Color.TRANSPARENT, Color(0.55, 0.64, 0.75), Color(0.08, 0.3, 0.5), Color(0.1, 0.65, 0.85), Color(0.15, 0.21, 0.3)]
	for y in 16:
		for z in 16:
			for x in 16:
				var block: int = blocks[(y * 16 + z) * 16 + x]
				if block == 0: continue
				var center := Vector3(x, y, z) + Vector3.ONE * 0.5 - Vector3.ONE * 8
				for normal in normals:
					var next := Vector3i(x, y, z) + Vector3i(normal)
					if next.x >= 0 and next.x < 16 and next.y >= 0 and next.y < 16 and next.z >= 0 and next.z < 16:
						if blocks[(next.y * 16 + next.z) * 16 + next.x] != 0: continue
					var u: Vector3 = Vector3.UP if absf(normal.y) < 0.5 else Vector3.RIGHT
					var v: Vector3 = normal.cross(u)
					var first := vertices.size()
					var shade := 1.0 if block == 3 else 0.55 + 0.45 * maxf(normal.dot(Vector3(-0.4, 0.8, -0.3).normalized()), 0)
					var color: Color = palette[mini(block, 4)]
					for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
						vertices.append(center + normal * 0.5 + (u * corner.x + v * corner.y) * 0.5)
						colors.append(Color(color.r * shade, color.g * shade, color.b * shade))
					indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func follow_camera(camera: Camera3D, info: Dictionary) -> void:
	var pose: Transform3D = info.world_transform
	var unit: float = info.voxel_size
	camera.transform = pose * Transform3D(Basis(), Vector3(0, 9, 27) * unit)
	camera.look_at(pose.origin, pose.basis.y)
	camera.near = maxf(unit * 0.02, 0.00001)
