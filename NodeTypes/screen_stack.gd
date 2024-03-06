class_name ScreenStack extends Node

signal state_pushed(state: PackedStringArray)
signal state_popped(state: PackedStringArray)
signal emptied

var _state_stack: Array[PackedStringArray]

func _update_screens() -> void:
	var screen_count: int = get_child_count()
	
	for screen: Screen in get_children():
		screen.layer = screen.get_index()

func _clear_screens() -> void:
	for screen: Screen in get_children():
		screen.set_visible(false)

func _set_current_state(screen_names: PackedStringArray) -> void:
	_clear_screens()
	
	var index: int = 0
	
	print("transitioning to screens " + str(screen_names))
	
	for screen_name in screen_names:
		var screen: Screen = find_child(screen_name, false)
		
		screen.set_visible(true)
		move_child(screen, index)
		
		index += 1
		
func _get_current_state() -> PackedStringArray:
	var state: PackedStringArray
	
	for screen: Screen in get_children():
		if (screen.visible):
			state.append(screen.get_name())
		
	return state

func _enter_tree() -> void:
	_state_stack.clear()
	_clear_screens()
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			_update_screens()
			
## Set the current state
func set_screens(screen_names: PackedStringArray) -> void:
	_set_current_state(screen_names)
	
## Get the screens in the current state
func get_screens() -> PackedStringArray:
	return _get_current_state()
		
## Push a new state on the stack
func push_screens(screen_names: PackedStringArray, args: Dictionary = {}) -> void:
	_state_stack.append(_get_current_state())
	_set_current_state(screen_names)
	
	state_pushed.emit(screen_names)
	
	for screen_name in screen_names:
		find_child(screen_name, false)._on_push(args)

## Pop the current state
func pop_screens() -> void:
	for screen: Screen in get_children():
		if (screen.visible):
			screen._on_pop()
		
	state_popped.emit(_get_current_state())
	
	if (_state_stack.size() == 0):
		_clear_screens()
		emptied.emit()
		
	else:
		_set_current_state(_state_stack.pop_back())

## Overlay a screen on the current state
func overlay_screen(screen_name: String, to_overlay: String = "") -> void:
	var screen: Node = find_child(screen_name, false)
	
	screen.set_visible(true)
	
	if to_overlay.is_empty():
		move_child(screen, 0)
	else:
		move_child(screen, find_child(to_overlay).get_index())

## Underlay a screen on the current state
func underlay_screen(screen_name: String, to_underlay: String = "") -> void:
	var screen: Node = find_child(screen_name, false)
	
	screen.set_visible(true)
	
	if to_underlay.is_empty():
		move_child(screen, -1)
	else:
		move_child(screen, find_child(to_underlay, false).get_index() + 1)
