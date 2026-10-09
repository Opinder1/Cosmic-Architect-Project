extends Node3D

@export var walk_speed: float = 6.0
@export var run_speed: float = 12.0
var active := false
var simulation: CosmicSimulation
var movement_speed := 0.0
var _stride := 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []

func _ready() -> void:
	var suit := _material(Color(0.82, 0.88, 0.95))
	var dark := _material(Color(0.08, 0.16, 0.25))
	var visor := _material(Color(0.15, 0.65, 0.85))
	_add_box(self, Vector3(0.7, 0.8, 0.4), Vector3(0, 1.2, 0), suit)
	_add_box(self, Vector3(0.48, 0.65, 0.25), Vector3(0, 1.22, 0.3), dark)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	head.mesh = sphere
	head.material_override = suit
	head.position.y = 1.9
	add_child(head)
	_add_box(self, Vector3(0.43, 0.24, 0.12), Vector3(0, 1.9, -0.25), visor)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.21, 0.8, 0)
		add_child(leg)
		_add_box(leg, Vector3(0.26, 0.65, 0.28), Vector3(0, -0.325, 0), suit)
		_add_box(leg, Vector3(0.3, 0.15, 0.42), Vector3(0, -0.725, -0.07), dark)
		_legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.5, 1.55, 0)
		add_child(arm)
		_add_box(arm, Vector3(0.23, 0.7, 0.25), Vector3(0, -0.35, 0), suit)
		_arms.append(arm)
	hide()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _add_box(parent: Node3D, size: Vector3, offset: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.material_override = material
	instance.position = offset
	parent.add_child(instance)

func enter_planet(sim: CosmicSimulation, pose: Transform3D) -> void:
	simulation = sim
	active = true
	position = pose.origin
	position.y = ground_height(position.x, position.z)
	rotation = Vector3(0, pose.basis.get_euler().y, 0)
	movement_speed = 0.0
	_stride = 0.0
	show()

func leave_planet() -> void:
	active = false
	movement_speed = 0.0
	simulation = null
	hide()

func ground_height(x: float, z: float) -> float:
	# Interpolate the same two triangles as DimensionView, not the smoother
	# generator between vertices, so the avatar stays on the visible mesh.
	var cell_size: float = simulation.get_planet_info(simulation.get_observer_planet()).chunk_size / 16.0
	var gx := floorf(x / cell_size) * cell_size
	var gz := floorf(z / cell_size) * cell_size
	var fx := (x - gx) / cell_size
	var fz := (z - gz) / cell_size
	var h00 := simulation.get_planet_surface_height(gx, gz)
	var h10 := simulation.get_planet_surface_height(gx + cell_size, gz)
	var h01 := simulation.get_planet_surface_height(gx, gz + cell_size)
	if fx + fz <= 1.0:
		return h00 + (h10 - h00) * fx + (h01 - h00) * fz
	var h11 := simulation.get_planet_surface_height(gx + cell_size, gz + cell_size)
	return h11 + (h01 - h11) * (1.0 - fx) + (h10 - h11) * (1.0 - fz)

func walk(delta: float, input: Vector2, camera_yaw: float, running: bool) -> void:
	if not active:
		return
	var direction := Vector3(input.x, 0, input.y).limit_length().rotated(Vector3.UP, camera_yaw)
	var speed := run_speed if running else walk_speed
	var destination := position + direction * speed * delta
	# Match the simulation's supported surface coordinate range.
	destination.x = clamp(destination.x, -1e7, 1e7)
	destination.z = clamp(destination.z, -1e7, 1e7)
	destination.y = ground_height(destination.x, destination.z)
	if not is_finite(destination.y):
		movement_speed = 0.0
		return
	position = destination
	movement_speed = direction.length() * speed
	if direction.length_squared() > 0.0001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), min(delta * 12.0, 1.0))
		_stride += movement_speed * delta * 2.0
	for index in range(_legs.size()):
		var swing := sin(_stride + index * PI) * 0.45 if movement_speed > 0.0 else 0.0
		_legs[index].rotation.x = swing
		_arms[index].rotation.x = -swing

func follow_camera(camera: Camera3D) -> void:
	if not active:
		return
	var target := position + Vector3(0, 1.5, 0)
	# Avoid moving the orbit camera below the terrain when looking upward.
	camera.rotation.x = clamp(camera.rotation.x, -deg_to_rad(65.0), deg_to_rad(10.0))
	camera.position = target + camera.basis.z * 8.0
	camera.position.y = max(camera.position.y, ground_height(camera.position.x, camera.position.z) + 0.5)
	camera.look_at(target, Vector3.UP)
