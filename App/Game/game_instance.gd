extends Node

signal return_to_menu

@export var save_directory: String
var simulation := CosmicSimulation.new()
var _status_timer := 0.0
var _networked := false
var _network_parent_id := Vector4i.ZERO
var _pending_arrival := ""
var _controls_allowed := true
var _last_pilot := Vector4i.ZERO

func start_network(address: String, port: int, player_id: Vector4i) -> Error:
	_networked = true
	save_directory = address + ":" + str(port)
	return simulation.initialize({"fragment_type": "client", "node_id": player_id,
		"server_address": address, "server_port": port})

func start(path: String) -> Error:
	# Initialization is explicit so the caller can report load errors before adding this node.
	save_directory = path
	return simulation.initialize({"path": path, "fragment_type": "offline"})

func _ready() -> void:
	$DimensionView.simulation = simulation
	$SpaceShips.simulation = simulation
	simulation.ships_changed.connect(_sync_ship_mode)
	simulation.ship_command_result.connect(_on_ship_command_result)
	if _networked:
		simulation.world_changed.connect(_on_network_world_changed)
		$Camera.set_controls_active(false)
		$HUD/Panel/Content/Title.text = "Connecting to " + save_directory
	else:
		_apply_observer()
	$Camera.make_current()
	$HUD/Panel/Content/Return.pressed.connect(func(): return_to_menu.emit())
	$HUD/Panel/Content/Explore.pressed.connect(explore_nearest)
	$HUD/Panel/Content/Leave.pressed.connect(return_to_parent)
	$HUD/Panel/Content/Ship.pressed.connect(toggle_ship)
	$HUD/Panel/Content/ShipLanding.pressed.connect(toggle_ship_landing)
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
	_controls_allowed = active
	$Camera.set_controls_active(active and (not _networked or simulation.is_world_ready()))
	if not active and (simulation.get_piloted_ship() != Vector4i.ZERO):
		simulation.set_ship_controls(Vector3.ZERO, Vector3.ZERO, false)
	if not active and $PlanetAvatar.active:
		$PlanetAvatar.walk(0.0, Vector2.ZERO, $Camera.rotation.y, false)

func _observer_pose() -> Transform3D:
	if (simulation.get_piloted_ship() != Vector4i.ZERO):
		return simulation.get_space_ship_info(simulation.get_piloted_ship()).world_transform
	return $PlanetAvatar.transform if $PlanetAvatar.active else $Camera.transform

func _process(delta: float) -> void:
	if not simulation.is_initialized():
		return
	if _networked:
		simulation.process(delta)
		if not simulation.is_world_ready():
			return
	_sync_ship_mode()
	$SpaceShips.refresh()
	if (simulation.get_piloted_ship() != Vector4i.ZERO):
		$SpaceShips.follow_camera($Camera, simulation.get_space_ship_info(simulation.get_piloted_ship()))
	elif $PlanetAvatar.active:
		$PlanetAvatar.follow_camera($Camera)
	else:
		$Camera.do_camera_controls(delta)
		if _networked:
			simulation.set_observer_transform(_observer_pose())
	if not _networked:
		simulation.process(delta)
	_status_timer += delta
	if _status_timer >= 0.2:
		_status_timer = 0.0
		_update_status()

func _physics_process(delta: float) -> void:
	if simulation.is_initialized() and (not _networked or simulation.is_world_ready()):
		if (simulation.get_piloted_ship() != Vector4i.ZERO):
			var thrust := Vector3.ZERO
			var turn := Vector3.ZERO
			if $Camera.controls_active and $Camera.enabled:
				var direction := Input.get_vector("left", "right", "forward", "backward")
				thrust = Vector3(direction.x, Input.get_axis("down", "up"), direction.y).limit_length()
				turn = Vector3(-$Camera.ship_look.y, -$Camera.ship_look.x, 0) / maxf(delta, 0.001)
				turn.z = Input.get_axis("roll_left", "roll_right")
			$Camera.ship_look = Vector2.ZERO
			simulation.set_ship_controls(thrust, turn, Input.is_action_pressed("speed") and $Camera.controls_active)
		elif $PlanetAvatar.active:
			var direction := Vector2.ZERO
			if $Camera.controls_active and $Camera.enabled:
				direction = Input.get_vector("left", "right", "forward", "backward")
			$PlanetAvatar.walk(delta, direction, $Camera.rotation.y, Input.is_action_pressed("speed"))
			simulation.set_observer_transform(_observer_pose())
		if _controls_allowed: simulation.physics_process(delta)
		if (simulation.get_piloted_ship() != Vector4i.ZERO) and _networked:
			simulation.set_observer_transform(_observer_pose())

func _on_network_world_changed() -> void:
	if not simulation.is_world_ready():
		_network_parent_id = Vector4i.ZERO
		$Camera.set_controls_active(false)
		$PlanetAvatar.leave_planet()
		$HUD/Panel/Content/Title.text = "Waiting for server data"
		return
	var parent_id: Vector4i = simulation.get_parent_info().id
	if parent_id != _network_parent_id:
		if (simulation.get_piloted_ship() != Vector4i.ZERO):
			_pending_arrival = ""
		elif _pending_arrival == "galaxy" or _pending_arrival == "star_system":
			var info := simulation.get_galaxy_info(simulation.get_observer_galaxy()) if _pending_arrival == "galaxy" else simulation.get_star_system_info(simulation.get_observer_star_system())
			var offset := Vector3(0, -0.6, 1.4) if _pending_arrival == "galaxy" else Vector3(0, -0.35, 1.15)
			var arrival := Transform3D(Basis.IDENTITY, offset * info.local_radius).looking_at(Vector3.ZERO, Vector3.UP)
			simulation.set_observer_transform(arrival)
		elif _pending_arrival == "planet":
			simulation.set_observer_transform(Transform3D())
		if (simulation.get_observer_planet() != Vector4i.ZERO):
			var position := simulation.get_observer_transform().origin
			if not is_finite(simulation.get_planet_surface_height(position.x, position.z)):
				return
		_apply_observer()
		_network_parent_id = parent_id
		_pending_arrival = ""
		$Camera.set_controls_active(_controls_allowed)
	_update_status()

func _update_status() -> void:
	var info := simulation.get_universe_info()
	if info.is_empty():
		return
	var galaxy_id := simulation.get_observer_galaxy()
	var system_id := simulation.get_observer_star_system()
	var planet_id := simulation.get_observer_planet()
	var in_galaxy := (galaxy_id != Vector4i.ZERO)
	var in_system := (system_id != Vector4i.ZERO)
	var in_planet := (planet_id != Vector4i.ZERO)
	var piloting := (simulation.get_piloted_ship() != Vector4i.ZERO)
	var location := "Universe"
	if in_planet:
		var body := simulation.get_planet_info(planet_id)
		location = "%s %d · System %d" % ["Moon" if (body.parent_planet != Vector4i.ZERO) else "Planet", body.ordinal + 1, simulation.get_star_system_info(system_id).ordinal + 1]
	elif in_system:
		location = "System %d · Galaxy %d" % [simulation.get_star_system_info(system_id).ordinal + 1, simulation.get_galaxy_info(galaxy_id).ordinal + 1]
	elif in_galaxy:
		location = "Galaxy %d" % (simulation.get_galaxy_info(galaxy_id).ordinal + 1)
	$HUD/Panel/Content/Title.text = save_directory.get_file() + " · " + location
	_update_ancestry(galaxy_id, system_id, planet_id)
	var population := "%d resident voxel chunks" % simulation.get_loaded_planet_chunk_count() if in_planet else ("%d stars · %d planets and moons" % [simulation.get_loaded_star_count(), simulation.get_loaded_planet_count()] if in_system else ("%s star systems" % simulation.get_loaded_star_system_count() if in_galaxy else "%s galaxies" % info.galaxy_count))
	$HUD/Panel/Content/Status.text = "%s\nPosition %s\nSpeed %.0f" % [
		population, _observer_pose().origin, $PlanetAvatar.movement_speed if in_planet else $Camera.speed * $Camera.accelerator]
	$HUD/Panel/Content/Controls.text = "Mouse — look around · X — release / capture\nClick world — capture mouse\nWASD — walk · Shift — run\nG — return to system · Escape — pause" if in_planet else "Mouse — look around · X — release / capture\nClick world — capture mouse\nWASD — fly · Space / Ctrl — rise / fall\nQ / E — roll · Shift — accelerate\nEscape — pause / resume"
	$HUD/Panel/Content/Ship.visible = in_system
	$HUD/Panel/Content/ShipLanding.visible = piloting
	$HUD/Panel/Content/Ship.text = "Disembark (B)" if piloting else "Board / deploy scout (B)"
	if piloting:
		var ship := simulation.get_space_ship_info(simulation.get_piloted_ship())
		$HUD/Panel/Content/Status.text = "%s · %s\nSpeed %.1f · Position %s" % [ship.name, "Landed" if ship.landed else "Flying", ship.velocity.length(), ship.world_transform.origin]
		$HUD/Panel/Content/Controls.text = "Mouse — steer · X — release / capture\nWASD — thrust · Space / Ctrl — rise / fall\nQ / E — roll · Shift — boost\nRelease thrust — brake\nL — land / launch · B — disembark\nF — approach planet · G — return to system"
		$HUD/Panel/Content/ShipLanding.text = "Launch (L)" if ship.landed else ("Land (L)" if in_planet else "Dock nearby (L)")
		$HUD/Panel/Content/Leave.visible = in_planet
	$HUD/Panel/Content/Explore.visible = not in_planet
	$HUD/Panel/Content/Leave.visible = in_planet if piloting else in_galaxy
	$HUD/Panel/Content/Explore.text = "Explore nearest planet (F)" if in_system else ("Explore nearest system (F)" if in_galaxy else "Explore nearest galaxy (F)")
	$HUD/Panel/Content/Leave.text = "Return to system (G)" if in_planet else ("Return to galaxy (G)" if in_system else "Return to universe (G)")
	if in_planet:
		$HUD/Panel/Content/Target.text = "Land within 80 units of the surface, below speed 20" if piloting else "Walking on the planet surface"
		return
	var target := _nearest_object()
	if target.is_empty():
		$HUD/Panel/Content/Target.text = "No nearby objects"
		$HUD/Panel/Content/Explore.disabled = true
	else:
		$HUD/Panel/Content/Explore.disabled = false
		var name: String = ("Moon %d" % (target.ordinal + 1) if (target.parent_planet != Vector4i.ZERO) else "Planet %d" % (target.ordinal + 1)) if in_system else ("System %d" % (target.ordinal + 1) if in_galaxy else "Galaxy %d" % (target.ordinal + 1))
		var position: Vector3 = target.position if in_galaxy else target.transform.origin
		$HUD/Panel/Content/Target.text = "Nearest: %s\nDistance: %.1f local units" % [name, position.distance_to($Camera.position)]

func _update_ancestry(galaxy_id: Vector4i, system_id: Vector4i, planet_id: Vector4i) -> void:
	var entries := PackedStringArray()
	var universe := simulation.get_universe_info()
	if not universe.is_empty():
		entries.append(_ancestry_entry("Universe", universe.id))
	if galaxy_id != Vector4i.ZERO:
		var galaxy := simulation.get_galaxy_info(galaxy_id)
		if not galaxy.is_empty():
			entries.append(_ancestry_entry("Galaxy %d" % (galaxy.ordinal + 1), galaxy.id))
	if system_id != Vector4i.ZERO:
		var system := simulation.get_star_system_info(system_id)
		if not system.is_empty():
			entries.append(_ancestry_entry("System %d" % (system.ordinal + 1), system.id))
	if planet_id != Vector4i.ZERO:
		var body := simulation.get_planet_info(planet_id)
		if not body.is_empty():
			if body.parent_planet != Vector4i.ZERO:
				var parent_body := simulation.get_planet_info(body.parent_planet)
				if not parent_body.is_empty():
					entries.append(_ancestry_entry("Planet %d" % (parent_body.ordinal + 1), parent_body.id))
			var body_type := "Moon" if body.parent_planet != Vector4i.ZERO else "Planet"
			entries.append(_ancestry_entry("%s %d" % [body_type, body.ordinal + 1], body.id))
	$HUD/Panel/Content/Ancestry.text = "Node ancestry\n" + "\n".join(entries)

func _ancestry_entry(node_name: String, node_id: Vector4i) -> String:
	return "%s · %s" % [node_name, CosmicSimulation.instance_id_to_string(node_id)]

func _nearest_object() -> Dictionary:
	if (simulation.get_observer_planet() != Vector4i.ZERO):
		return {}
	var in_galaxy := (simulation.get_observer_galaxy() != Vector4i.ZERO)
	var in_system := (simulation.get_observer_star_system() != Vector4i.ZERO)
	var info := simulation.get_star_system_info(simulation.get_observer_star_system()) if in_system else (simulation.get_galaxy_info(simulation.get_observer_galaxy()) if in_galaxy else simulation.get_universe_info())
	if info.is_empty():
		return {}
	var extent: float = info.local_radius if in_galaxy else info.half_extent
	var position: Vector3 = _observer_pose().origin
	# Expand a sphere until it contains an object. Every closer object is then
	# included, so selecting its minimum gives the true nearest object.
	var radius: float = max(extent * 0.05, position.length() - extent * 1.75)
	var limit: float = position.length() + extent * 2.0
	var ids: Array[Vector4i] = []
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
	var in_galaxy := (simulation.get_observer_galaxy() != Vector4i.ZERO)
	var in_system := (simulation.get_observer_star_system() != Vector4i.ZERO)
	var in_planet := (simulation.get_observer_planet() != Vector4i.ZERO)
	var info := simulation.get_planet_info(simulation.get_observer_planet()) if in_planet else (simulation.get_star_system_info(simulation.get_observer_star_system()) if in_system else (simulation.get_galaxy_info(simulation.get_observer_galaxy()) if in_galaxy else simulation.get_universe_info()))
	if info.is_empty():
		return
	var extent: float = info.local_radius if in_galaxy else info.half_extent
	$Camera.speed = 24.0 if in_planet else extent * (0.015 if in_system else 0.075)
	$Camera.accelerator = 1.0
	$Camera.far = max($DimensionView.get_render_extent() + $Camera.position.length(), 3500.0 if in_planet else max(extent * 8.0, 100.0))
	$Camera.space_movement = not in_planet
	if (simulation.get_piloted_ship() != Vector4i.ZERO):
		_sync_ship_mode()
		$SpaceShips.refresh()
		$SpaceShips.follow_camera($Camera, simulation.get_space_ship_info(simulation.get_piloted_ship()))
		return
	if in_planet:
		$PlanetAvatar.enter_planet(simulation, simulation.get_observer_transform())
		$Camera.rotation = Vector3(-0.2, $PlanetAvatar.rotation.y, 0)
		$PlanetAvatar.follow_camera($Camera)
		simulation.set_observer_transform(_observer_pose())
	else:
		$PlanetAvatar.leave_planet()

func _sync_ship_mode() -> void:
	var pilot := simulation.get_piloted_ship()
	$Camera.ship_controls = (pilot != Vector4i.ZERO)
	if pilot == _last_pilot: return
	_last_pilot = pilot
	$Camera.ship_look = Vector2.ZERO
	if (pilot != Vector4i.ZERO):
		$PlanetAvatar.leave_planet()
	elif simulation.is_world_ready():
		$Camera.near = 0.1
		_apply_observer()
	_update_status()

func _on_ship_command_result(action: String, error: int) -> void:
	if error != OK:
		$HUD/Panel/Content/Error.text = "Ship " + action + ": " + error_string(error)
		$HUD/Panel/Content/Error.show()
	else:
		$HUD/Panel/Content/Error.hide()

func toggle_ship() -> void:
	if not $Camera.controls_active or not simulation.is_world_ready(): return
	simulation.set_observer_transform(_observer_pose())
	var error := simulation.disembark_space_ship() if (simulation.get_piloted_ship() != Vector4i.ZERO) else simulation.deploy_space_ship()
	_on_ship_command_result("boarding", error)
	_sync_ship_mode()
	$SpaceShips.refresh()
	_update_status()

func toggle_ship_landing() -> void:
	if not $Camera.controls_active or (simulation.get_piloted_ship() == Vector4i.ZERO): return
	var info := simulation.get_space_ship_info(simulation.get_piloted_ship())
	var error: int
	if info.landed:
		error = simulation.launch_space_ship()
	elif (simulation.get_observer_planet() != Vector4i.ZERO):
		error = simulation.land_space_ship()
	else:
		var dock: Dictionary = $SpaceShips.nearest_dock(info)
		error = ERR_DOES_NOT_EXIST if dock.is_empty() else simulation.dock_space_ship(dock.type, dock.id)
	_on_ship_command_result("landing", error)
	_update_status()

func explore_nearest_galaxy() -> void:
	if not $Camera.controls_active or (simulation.get_observer_galaxy() != Vector4i.ZERO):
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
	if _networked:
		_pending_arrival = "galaxy"
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
	if not $Camera.controls_active or (simulation.get_observer_galaxy() == Vector4i.ZERO) or (simulation.get_observer_star_system() != Vector4i.ZERO):
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
	if _networked:
		_pending_arrival = "star_system"
		return
	var arrival := Transform3D(Basis.IDENTITY, Vector3(0, -0.35, 1.15) * target.local_radius)
	arrival = arrival.looking_at(Vector3.ZERO, Vector3.UP)
	simulation.set_observer_transform(arrival)
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func explore_nearest() -> void:
	if (simulation.get_observer_galaxy() == Vector4i.ZERO):
		explore_nearest_galaxy()
	elif (simulation.get_observer_star_system() == Vector4i.ZERO):
		explore_nearest_star_system()
	else:
		explore_nearest_planet()

func explore_nearest_planet() -> void:
	if not $Camera.controls_active or (simulation.get_observer_star_system() == Vector4i.ZERO) or (simulation.get_observer_planet() != Vector4i.ZERO):
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
	if _networked:
		_pending_arrival = "planet"
		return
	if (simulation.get_piloted_ship() != Vector4i.ZERO):
		_apply_observer()
		_update_status()
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
	if _networked:
		return
	_apply_observer()
	$HUD/Panel/Content/Error.hide()
	_update_status()

func return_to_parent() -> void:
	if not $Camera.controls_active:
		return
	if (simulation.get_observer_planet() != Vector4i.ZERO):
		simulation.set_observer_transform(_observer_pose())
		var error := simulation.leave_planet()
		if error != OK:
			$HUD/Panel/Content/Error.text = "Could not return: " + error_string(error)
			$HUD/Panel/Content/Error.show()
			return
		if _networked:
			return
		_apply_observer()
		$HUD/Panel/Content/Error.hide()
		_update_status()
		return
	if (simulation.get_observer_star_system() == Vector4i.ZERO):
		return_to_universe()
		return
	simulation.set_observer_transform(_observer_pose())
	var error := simulation.leave_star_system()
	if error != OK:
		$HUD/Panel/Content/Error.text = "Could not return: " + error_string(error)
		$HUD/Panel/Content/Error.show()
		return
	if _networked:
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
		elif event.keycode == KEY_B:
			toggle_ship()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L:
			toggle_ship_landing()
			get_viewport().set_input_as_handled()
