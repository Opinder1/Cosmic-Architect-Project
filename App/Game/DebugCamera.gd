class_name TestCamera extends Camera3D

@export var speed: float = 1
@export var space_movement: bool = true
var accelerator: float = 1
var enabled: float = false

func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_X and event.is_released():
			enabled = !enabled
			
			if enabled:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func movement_fps(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("forward", "backward", "left", "right").rotated(rotation.y)
	
	var vertical: float = Input.get_axis("down", "up")
	
	position += (Vector3(direction.y, vertical, direction.x)) * delta * speed
		
	rotation.x -= Input.get_last_mouse_velocity().y * delta * 0.001
	rotation.y -= Input.get_last_mouse_velocity().x * delta * 0.001
	
	rotation_degrees.x = clamp(rotation_degrees.x, -90, 90)


func movement_space(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	
	var vertical: float = Input.get_axis("down", "up")
	
	position += (transform.basis * Vector3(direction.x, vertical, direction.y)).normalized() * delta * accelerator * speed
	
	rotate_object_local(Vector3(1, 0, 0), Input.get_last_mouse_velocity().y * delta * -0.001)
	rotate_object_local(Vector3(0, 1, 0), Input.get_last_mouse_velocity().x * delta * -0.001)
	
	rotate_object_local(Vector3(0, 0, 1), Input.get_axis("roll_left", "roll_right") * delta)
	
	if Input.is_action_pressed("speed"):
		accelerator *= 1 + delta
	else:
		accelerator /= 1 + delta
		
	#accelerator = clamp(accelerator, 1, 100000)
	accelerator = max(accelerator, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func do_camera_controls(delta: float) -> void:
	if not enabled:
		return
	
	if space_movement:
		movement_space(delta)
	else:
		movement_fps(delta)
