class_name ScreenStack extends Screen

func _update_screens() -> void:
	var screen_count: int = get_child_count()
	
	for screen: Screen in get_children():
		screen.layer = screen.get_index()

func _clear_screens() -> void:
	for screen: Screen in get_children():
		screen.set_visible(false)

func _enter_tree() -> void:
	_clear_screens()
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			_update_screens()
			
## Set the current state
func set_screen(screen: Screen) -> void:
	_clear_screens()
	
	screen.set_visible(true)

## Overlay a screen on the current state
func overlay_screen(screen: Screen, to_overlay: Screen) -> void:
	screen.set_visible(true)
	
	if to_overlay.is_empty():
		move_child(screen, 0)
	else:
		move_child(screen, to_overlay.get_index())

## Underlay a screen on the current state
func underlay_screen(screen: Screen, to_underlay: Screen) -> void:
	screen.set_visible(true)
	
	if to_underlay.is_empty():
		move_child(screen, -1)
	else:
		move_child(screen, to_underlay.get_index() + 1)
