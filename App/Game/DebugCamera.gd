class_name TestCamera extends Camera3D

@export var speed: float = 300.0
@export var space_movement: bool = true
@export var mouse_sensitivity: float = 0.002
var accelerator: float = 1.0
var enabled: bool = false
var controls_active: bool = true

func _ready() -> void:
	_set_mouse_look_enabled(controls_active)

func _set_mouse_look_enabled(active: bool) -> void:
	enabled = active and controls_active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE

func set_controls_active(active: bool) -> void:
	controls_active = active
	_set_mouse_look_enabled(active)

func _input(event: InputEvent) -> void:
	if not controls_active or not enabled or not event is InputEventMouseMotion:
		return
	if space_movement:
		rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)
		rotate_object_local(Vector3.UP, -event.relative.x * mouse_sensitivity)
	else:
		rotation.x = clamp(rotation.x - event.relative.y * mouse_sensitivity, -deg_to_rad(89.0), deg_to_rad(89.0))
		rotation.y -= event.relative.x * mouse_sensitivity
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not controls_active:
		return
	if event is InputEventKey and event.keycode == KEY_X and event.is_released():
		_set_mouse_look_enabled(not enabled)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not enabled:
		_set_mouse_look_enabled(true)
		get_viewport().set_input_as_handled()

func do_camera_controls(delta: float) -> void:
	if not enabled or not controls_active:
		return
	var direction := Input.get_vector("left", "right", "forward", "backward")
	var movement := Vector3(direction.x, Input.get_axis("down", "up"), direction.y)
	if space_movement:
		movement = transform.basis * movement
		rotate_object_local(Vector3.BACK, Input.get_axis("roll_left", "roll_right") * delta)
	else:
		movement = movement.rotated(Vector3.UP, rotation.y)
	position += movement.limit_length() * delta * accelerator * speed
	var acceleration := 1.0 + delta
	accelerator = clamp(accelerator * acceleration if Input.is_action_pressed("speed") else accelerator / acceleration, 1.0, 100.0)
