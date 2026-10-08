extends Node

signal return_to_menu

@export var save_directory: String
var simulation := CosmicSimulation.new()
var _status_timer := 0.0

func start(path: String) -> Error:
	save_directory = path
	return simulation.initialize({"path": path, "fragment_type": "offline"})

func _ready() -> void:
	$DimensionView.simulation = simulation
	_apply_observer()
	$Camera.make_current()
	$HUD/Panel/Content/Return.pressed.connect(func(): return_to_menu.emit())
	$HUD/Panel/Content/Explore.pressed.connect(explore_nearest_galaxy)
	$HUD/Panel/Content/Leave.pressed.connect(return_to_universe)
	_update_status()

func stop() -> Error:
	$Camera.set_controls_active(false)
	if not simulation.is_initialized():
		return OK
	simulation.set_observer_transform($Camera.transform)
	$DimensionView.simulation = null
	return simulation.uninitialize()

func _exit_tree() -> void:
	var error := stop()
	if error != OK:
		push_error("Could not save universe: " + error_string(error))

func set_controls_active(active: bool) -> void:
	$Camera.set_controls_active(active)

func _process(delta: float) -> void:
	if not simulation.is_initialized():
		return
	$Camera.do_camera_controls(delta)
	simulation.process(delta)
	_status_timer += delta
	if _status_timer >= 0.2:
		_status_timer = 0.0
		_update_status()

func _physics_process(delta: float) -> void:
	if simulation.is_initialized():
		simulation.physics_process(delta)

func _update_status() -> void:
	var info := simulation.get_universe_info()
	if info.is_empty():
		return
	var galaxy_id := simulation.get_observer_galaxy()
	var in_galaxy := galaxy_id >= 0
	var location := "Galaxy %d" % galaxy_id if in_galaxy else "Universe"
	$HUD/Panel/Content/Title.text = save_directory.get_file() + " · " + location
	var population := "%s star systems" % simulation.get_loaded_star_system_count() if in_galaxy else "%s galaxies" % info.galaxy_count
	$HUD/Panel/Content/Status.text = "%s\nPosition %s\nSpeed %.0f" % [
		population, $Camera.position, $Camera.speed * $Camera.accelerator]
	$HUD/Panel/Content/Explore.visible = not in_galaxy
	$HUD/Panel/Content/Leave.visible = in_galaxy
	var target := _nearest_object()
	if target.is_empty():
		$HUD/Panel/Content/Target.text = "No nearby objects"
		$HUD/Panel/Content/Explore.disabled = true
	else:
		$HUD/Panel/Content/Explore.disabled = false
		var name: String = "System %d" % (target.ordinal + 1) if in_galaxy else "Galaxy %d" % target.id
		var position: Vector3 = target.position if in_galaxy else target.transform.origin
		$HUD/Panel/Content/Target.text = "Nearest: %s\nDistance: %.1f local units" % [name, position.distance_to($Camera.position)]

func _nearest_object() -> Dictionary:
	var in_galaxy := simulation.get_observer_galaxy() >= 0
	var info := simulation.get_galaxy_info(simulation.get_observer_galaxy()) if in_galaxy else simulation.get_universe_info()
	if info.is_empty():
		return {}
	var extent: float = info.local_radius if in_galaxy else info.half_extent
	var position: Vector3 = $Camera.position
	# Expand a sphere until it contains an object. Every closer object is then
	# included, so selecting its minimum gives the true nearest object.
	var radius: float = max(extent * 0.05, position.length() - extent * 1.75)
	var limit: float = position.length() + extent * 2.0
	var ids := PackedInt64Array()
	while ids.is_empty():
		ids = simulation.find_star_systems(position, radius) if in_galaxy else simulation.find_galaxies(position, radius)
		if radius >= limit:
			break
		radius = min(radius * 2.0, limit)
	var nearest: Dictionary = {}
	var distance := INF
	for id in ids:
		var item := simulation.get_star_system_info(id) if in_galaxy else simulation.get_galaxy_info(id)
		var item_position: Vector3 = item.position if in_galaxy else item.transform.origin
		var candidate := position.distance_squared_to(item_position)
		if candidate < distance:
			distance = candidate
			nearest = item
	return nearest

func _apply_observer() -> void:
	$Camera.transform = simulation.get_observer_transform()
	var in_galaxy := simulation.get_observer_galaxy() >= 0
	var info := simulation.get_galaxy_info(simulation.get_observer_galaxy()) if in_galaxy else simulation.get_universe_info()
	if info.is_empty():
		return
	var extent: float = info.local_radius if in_galaxy else info.half_extent
	$Camera.speed = extent * 0.075
	$Camera.accelerator = 1.0
	$Camera.far = max(extent * 8.0, 100.0)

func explore_nearest_galaxy() -> void:
	if not $Camera.controls_active or simulation.get_observer_galaxy() >= 0:
		return
	var target := _nearest_object()
	if target.is_empty():
		return
	simulation.set_observer_transform($Camera.transform)
	var error := simulation.enter_galaxy(target.id)
	if error != OK:
		$HUD/Panel/Content/Error.text = "Could not enter galaxy: " + error_string(error)
		$HUD/Panel/Content/Error.show()
		return
	# Explore is an explicit trip to a useful overview of the selected galaxy.
	# The simulation also supports exact coordinate conversion without this trip.
	var arrival := Transform3D(Basis.IDENTITY, Vector3(0, -0.6, 1.4) * target.local_radius)
	arrival = arrival.looking_at(Vector3.ZERO, Vector3.UP)
	simulation.set_observer_transform(arrival)
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func return_to_universe() -> void:
	if not $Camera.controls_active:
		return
	simulation.set_observer_transform($Camera.transform)
	var error := simulation.leave_galaxy()
	if error != OK:
		$HUD/Panel/Content/Error.text = "Could not return: " + error_string(error)
		$HUD/Panel/Content/Error.show()
		return
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and $Camera.controls_active:
		if event.keycode == KEY_F:
			explore_nearest_galaxy()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			return_to_universe()
			get_viewport().set_input_as_handled()
