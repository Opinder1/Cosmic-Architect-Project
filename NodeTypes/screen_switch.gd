class_name ScreenSwitch extends Screen

var _state_stack: Array[Screen]

func _clear_screens() -> void:
	_state_stack.clear()
	for screen: Screen in get_children():
		screen.set_visible(false)

func _enter_tree() -> void:
	_clear_screens()
			
## Clear the history and set the current screen
func transition_screen(screen: Screen) -> void:
	_clear_screens()
	
	_state_stack.push_back(screen)
	screen.set_visible(true)
	
## Push a new screen on the stack
func push_screen(screen: Screen) -> void:
	if _state_stack.size() > 0:
		_state_stack.back().set_visible(false)
		
	_state_stack.push_back(screen)
	screen.set_visible(true)

## Pop the current screen
func pop_screen() -> void:
	if _state_stack.size() > 0:
		_state_stack.pop_back().set_visible(false)
	
	if _state_stack.size() > 0:
		_state_stack.back().set_visible(true)
