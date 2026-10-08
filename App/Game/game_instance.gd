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
	$Camera.transform = simulation.get_observer_transform()
	$Camera.make_current()
	$HUD/Panel/Content/Return.pressed.connect(func(): return_to_menu.emit())
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
	var nearby := simulation.find_galaxies($Camera.position, info.half_extent * 0.1)
	$HUD/Panel/Content/Title.text = save_directory.get_file() + " · Universe exploration"
	$HUD/Panel/Content/Status.text = "Seed %s\n%s galaxies · %s nearby\nPosition %s\nSpeed %.0f" % [
		info.public_seed, info.galaxy_count, nearby.size(), $Camera.position,
		$Camera.speed * $Camera.accelerator]