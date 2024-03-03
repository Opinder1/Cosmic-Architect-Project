class_name ScreenStack extends Node

func _update_screens() -> void:
	var screen_count: int = get_child_count()
	
	for screen: Node in get_children():
		screen.layer = screen_count - screen.get_index()

func _enter_tree() -> void:
	clear_screens()
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			_update_screens()

func clear_screens() -> void:
	for screen: Node in get_children():
		screen.set_visible(false)

func set_screen(screen_name: String) -> void:
	clear_screens()
		
	var screen: Node = find_child(screen_name)
		
	screen.set_visible(true)
	move_child(screen, 0)

func set_screens(screen_names: PackedStringArray) -> void:
	clear_screens()
	
	var index: int = 0
	
	for screen_name in screen_names:
		var screen: Node = find_child(screen_name)
		
		screen.set_visible(true)
		move_child(screen, index)
		
		index += 1

func overlay_screen(screen_name: String, to_overlay: String = "") -> void:
	var screen: Node = find_child(screen_name)
	
	screen.set_visible(true)
	
	if to_overlay.is_empty():
		move_child(screen, 0)
	else:
		move_child(screen, find_child(to_overlay).get_index())

func underlay_screen(screen_name: String, to_underlay: String = "") -> void:
	var screen: Node = find_child(screen_name)
	
	screen.set_visible(true)
	
	if to_underlay.is_empty():
		move_child(screen, -1)
	else:
		move_child(screen, find_child(to_underlay).get_index() + 1)
