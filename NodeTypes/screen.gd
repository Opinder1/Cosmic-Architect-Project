class_name Screen extends CanvasLayer

var screen_stack : Node

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			screen_stack = get_parent()
			
		NOTIFICATION_UNPARENTED:
			screen_stack = null

func set_screen(screen_name: String) -> void:
	screen_stack.set_screen(screen_name)

func overlay_screen(screen_name: String) -> void:
	screen_stack.overlay_screen(screen_name)

func underlay_screen(screen_name: String) -> void:
	screen_stack.underlay_screen(screen_name)
