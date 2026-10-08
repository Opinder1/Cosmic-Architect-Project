class_name TestCamera extends Camera3D

@export var speed: float = 300.0
@export var space_movement: bool = true
var accelerator: float = 1.0
var enabled: bool = false
var controls_active: bool = true

func set_controls_active(active: bool) -> void:
	controls_active = active
	if not active:
		enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not controls_active:
		return
	if event is InputEventKey and event.keycode == KEY_X and event.is_released():
		enabled = not enabled
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	if enabled and event is InputEventMouseMotion:
		if space_movement:
			rotate_object_local(Vector3.RIGHT, event.relative.y * -0.002)
			rotate_object_local(Vector3.UP, event.relative.x * -0.002)
		else:
			rotation.x = clamp(rotation.x - event.relative.y * 0.002, -PI * 0.5, PI * 0.5)
			rotation.y -= event.relative.x * 0.002

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