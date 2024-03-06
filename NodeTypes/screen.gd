class_name Screen extends CanvasLayer

var _screen_stack : Node

func _on_push(args: Dictionary) -> void: pass # virtual
	
func _on_pop() -> void: pass # virtual
	
func _on_activate() -> void: pass # virtual
	
func _on_deactivate() -> void: pass # virtual

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_screen_stack = get_parent()
			assert(_screen_stack is ScreenStack, "The parent of '" + get_name() + "' is a '" + get_parent().get_class() + "' and not a ScreenStack")
			
		NOTIFICATION_UNPARENTED:
			_screen_stack = null

## Push screens onto the screen stack this screen is part of with optional arguments
func push_screens(screen_names: PackedStringArray, args: Dictionary = {}) -> void:
	_screen_stack.push_screens(screen_names, args)

## Overlay a screen onto the screen stack state
func overlay_screen(screen_name: String) -> void:
	_screen_stack.overlay_screens(screen_name, self.get_name())

## Underlay a screen onto the screen stack state
func underlay_screen(screen_name: String) -> void:
	_screen_stack.underlay_screens(screen_name, self.get_name())

func pop_screens() -> void:
	_screen_stack.pop_screens()
