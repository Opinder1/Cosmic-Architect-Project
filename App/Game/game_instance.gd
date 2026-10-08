extends Node

signal return_to_menu

@export var save_directory: String
var simulation := CosmicSimulation.new()
var _status_timer := 0.0

func start(path: String) -> Error:
	# Initialization is explicit so the caller can report load errors before adding this node.
	save_directory = path
	return simulation.initialize({"path": path, "fragment_type": "offline"})

func _ready() -> void:
	$DimensionView.simulation = simulation
	_apply_observer()
	$Camera.make_current()
	$HUD/Panel/Content/Return.pressed.connect(func(): return_to_menu.emit())
	$HUD/Panel/Content/Explore.pressed.connect(explore_nearest)
	$HUD/Panel/Content/Leave.pressed.connect(return_to_parent)
	_update_status()

func stop() -> Error:
	# Disable input before disconnecting the view, then let the simulation persist its state.
	$Camera.set_controls_active(false)
	if not simulation.is_initialized():
		return OK
	simulation.set_observer_transform(_observer_pose())
	$PlanetAvatar.leave_planet()
	$DimensionView.simulation = null
	return simulation.uninitialize()

func _exit_tree() -> void:
	var error := stop()
	if error != OK:
		push_error("Could not save universe: " + error_string(error))

func set_controls_active(active: bool) -> void:
	$Camera.set_controls_active(active)
	if not active and $PlanetAvatar.active:
		$PlanetAvatar.walk(0.0, Vector2.ZERO, $Camera.rotation.y, false)

func _observer_pose() -> Transform3D:
	return $PlanetAvatar.transform if $PlanetAvatar.active else $Camera.transform

func _process(delta: float) -> void:
	if not simulation.is_initialized():
		return
	if $PlanetAvatar.active:
		$PlanetAvatar.follow_camera($Camera)
	else:
		$Camera.do_camera_controls(delta)
	simulation.process(delta)
	_status_timer += delta
	if _status_timer >= 0.2:
		_status_timer = 0.0
		_update_status()

func _physics_process(delta: float) -> void:
	if simulation.is_initialized():
		if $PlanetAvatar.active:
			var direction := Vector2.ZERO
			if $Camera.controls_active and $Camera.enabled:
				direction = Input.get_vector("left", "right", "forward", "backward")
			$PlanetAvatar.walk(delta, direction, $Camera.rotation.y, Input.is_action_pressed("speed"))
			simulation.set_observer_transform(_observer_pose())
		simulation.physics_process(delta)

func _update_status() -> void:
	var info := simulation.get_universe_info()
	if info.is_empty():
		return
	var galaxy_id := simulation.get_observer_galaxy()
	var system_id := simulation.get_observer_star_system()
	var planet_id := simulation.get_observer_planet()
	var in_galaxy := galaxy_id >= 0
	var in_system := system_id >= 0
	var in_planet := planet_id >= 0
	var location := "Universe"
	if in_planet:
		var body := simulation.get_planet_info(planet_id)
		location = "%s %d · System %d" % ["Moon" if body.parent_planet >= 0 else "Planet", body.ordinal + 1, simulation.get_star_system_info(system_id).ordinal + 1]
	elif in_system:
		location = "System %d · Galaxy %d" % [simulation.get_star_system_info(system_id).ordinal + 1, galaxy_id]
	elif in_galaxy:
		location = "Galaxy %d" % galaxy_id
	$HUD/Panel/Content/Title.text = save_directory.get_file() + " · " + location
	var population := "%d resident voxel chunks" % simulation.get_loaded_planet_chunk_count() if in_planet else ("%d stars · %d planets and moons" % [simulation.get_loaded_star_count(), simulation.get_loaded_planet_count()] if in_system else ("%s star systems" % simulation.get_loaded_star_system_count() if in_galaxy else "%s galaxies" % info.galaxy_count))
	$HUD/Panel/Content/Status.text = "%s\nPosition %s\nSpeed %.0f" % [
		population, _observer_pose().origin, $PlanetAvatar.movement_speed if in_planet else $Camera.speed * $Camera.accelerator]
	$HUD/Panel/Content/Controls.text = "Mouse — look around · X — release / capture\nClick world — capture mouse\nWASD — walk · Shift — run\nG — return to system · Escape — pause" if in_planet else "Mouse — look around · X — release / capture\nClick world — capture mouse\nWASD — fly · Space / Ctrl — rise / fall\nQ / E — roll · Shift — accelerate\nEscape — pause / resume"
	$HUD/Panel/Content/Explore.visible = not in_planet
	$HUD/Panel/Content/Leave.visible = in_galaxy
	$HUD/Panel/Content/Explore.text = "Explore nearest planet (F)" if in_system else ("Explore nearest system (F)" if in_galaxy else "Explore nearest galaxy (F)")
	$HUD/Panel/Content/Leave.text = "Return to system (G)" if in_planet else ("Return to galaxy (G)" if in_system else "Return to universe (G)")
	if in_planet:
		$HUD/Panel/Content/Target.text = "Walking on the planet surface"
		return
	var target := _nearest_object()
	if target.is_empty():
		$HUD/Panel/Content/Target.text = "No nearby objects"
		$HUD/Panel/Content/Explore.disabled = true
	else:
		$HUD/Panel/Content/Explore.disabled = false
		var name: String = ("Moon %d" % (target.ordinal + 1) if target.parent_planet >= 0 else "Planet %d" % (target.ordinal + 1)) if in_system else ("System %d" % (target.ordinal + 1) if in_galaxy else "Galaxy %d" % target.id)
		var position: Vector3 = target.position if in_galaxy else target.transform.origin
		$HUD/Panel/Content/Target.text = "Nearest: %s\nDistance: %.1f local units" % [name, position.distance_to($Camera.position)]

func _nearest_object() -> Dictionary:
	if simulation.get_observer_planet() >= 0:
		return {}
	var in_galaxy := simulation.get_observer_galaxy() >= 0
	var in_system := simulation.get_observer_star_system() >= 0
	var info := simulation.get_star_system_info(simulation.get_observer_star_system()) if in_system else (simulation.get_galaxy_info(simulation.get_observer_galaxy()) if in_galaxy else simulation.get_universe_info())
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
		ids = simulation.find_planets(position, radius) if in_system else (simulation.find_star_systems(position, radius) if in_galaxy else simulation.find_galaxies(position, radius))
		if radius >= limit:
			break
		radius = min(radius * 2.0, limit)
	var nearest: Dictionary = {}
	var distance := INF
	for id in ids:
		var item := simulation.get_planet_info(id) if in_system else (simulation.get_star_system_info(id) if in_galaxy else simulation.get_galaxy_info(id))
		var item_position: Vector3 = item.position if in_galaxy else item.transform.origin
		var candidate := position.distance_squared_to(item_position)
		if candidate < distance:
			distance = candidate
			nearest = item
	return nearest

func _apply_observer() -> void:
	$Camera.transform = simulation.get_observer_transform()
	var in_galaxy := simulation.get_observer_galaxy() >= 0
	var in_system := simulation.get_observer_star_system() >= 0
	var in_planet := simulation.get_observer_planet() >= 0
	var info := simulation.get_planet_info(simulation.get_observer_planet()) if in_planet else (simulation.get_star_system_info(simulation.get_observer_star_system()) if in_system else (simulation.get_galaxy_info(simulation.get_observer_galaxy()) if in_galaxy else simulation.get_universe_info()))
	if info.is_empty():
		return
	var extent: float = info.local_radius if in_galaxy else info.half_extent
	$Camera.speed = 24.0 if in_planet else extent * (0.015 if in_system else 0.075)
	$Camera.accelerator = 1.0
	$Camera.far = max($DimensionView.get_render_extent() + $Camera.position.length(), 3500.0 if in_planet else max(extent * 8.0, 100.0))
	$Camera.space_movement = not in_planet
	if in_planet:
		$PlanetAvatar.enter_planet(simulation, simulation.get_observer_transform())
		$Camera.rotation = Vector3(-0.2, $PlanetAvatar.rotation.y, 0)
		$PlanetAvatar.follow_camera($Camera)
		simulation.set_observer_transform(_observer_pose())
	else:
		$PlanetAvatar.leave_planet()

func explore_nearest_galaxy() -> void:
	if not $Camera.controls_active or simulation.get_observer_galaxy() >= 0:
		return
	var target := _nearest_object()
	if target.is_empty():
		return
	simulation.set_observer_transform(_observer_pose())
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

func explore_nearest_star_system() -> void:
	if not $Camera.controls_active or simulation.get_observer_galaxy() < 0 or simulation.get_observer_star_system() >= 0:
		return
	var target := _nearest_object()
	if target.is_empty():
		return
	simulation.set_observer_transform(_observer_pose())
	var error := simulation.enter_star_system(target.id)
	if error != OK:
		$HUD/Panel/Content/Error.text = "Could not enter system: " + error_string(error)
		$HUD/Panel/Content/Error.show()
		return
	var arrival := Transform3D(Basis.IDENTITY, Vector3(0, -0.35, 1.15) * target.local_radius)
	arrival = arrival.looking_at(Vector3.ZERO, Vector3.UP)
	simulation.set_observer_transform(arrival)
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func explore_nearest() -> void:
	if simulation.get_observer_galaxy() < 0:
		explore_nearest_galaxy()
	elif simulation.get_observer_star_system() < 0:
		explore_nearest_star_system()
	else:
		explore_nearest_planet()

func explore_nearest_planet() -> void:
	if not $Camera.controls_active or simulation.get_observer_star_system() < 0 or simulation.get_observer_planet() >= 0:
		return
	var target := _nearest_object()
	if target.is_empty():
		return
	simulation.set_observer_transform(_observer_pose())
	var error := simulation.enter_planet(target.id)
	if error != OK:
		$HUD/Panel/Content/Error.text = "Could not enter planet: " + error_string(error)
		$HUD/Panel/Content/Error.show()
		return
	var height: float = simulation.get_planet_surface_height(0.0, 0.0)
	var arrival := Transform3D(Basis.IDENTITY, Vector3(0, height, 0))
	simulation.set_observer_transform(arrival)
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func return_to_universe() -> void:
	if not $Camera.controls_active:
		return
	simulation.set_observer_transform(_observer_pose())
	var error := simulation.leave_galaxy()
	if error != OK:
		$HUD/Panel/Content/Error.text = "Could not return: " + error_string(error)
		$HUD/Panel/Content/Error.show()
		return
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func return_to_parent() -> void:
	if not $Camera.controls_active:
		return
	if simulation.get_observer_planet() >= 0:
		simulation.set_observer_transform(_observer_pose())
		var error := simulation.leave_planet()
		if error != OK:
			$HUD/Panel/Content/Error.text = "Could not return: " + error_string(error)
			$HUD/Panel/Content/Error.show()
			return
		_apply_observer()
		$HUD/Panel/Content/Error.hide()
		_update_status()
		return
	if simulation.get_observer_star_system() < 0:
		return_to_universe()
		return
	simulation.set_observer_transform(_observer_pose())
	var error := simulation.leave_star_system()
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
			explore_nearest()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			return_to_parent()
			get_viewport().set_input_as_handled()
