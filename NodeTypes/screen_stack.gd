class_name ScreenStack
extends Node

func _enter_tree() -> void:
	for child in get_children():
		child.set_visible(false)

func set_screen(screen_name: String) -> void:
	for child in get_children():
		child.set_visible(false)
		
	var child: Node = find_child(screen_name)
		
	child.set_visible(true)
	move_child(child, 0)

func overlay_screen(screen_name: String) -> void:
	var child: Node = find_child(screen_name)
	
	child.set_visible(true)
	move_child(child, 0)

func underlay_screen(screen_name: String) -> void:
	var child: Node = find_child(screen_name)
	
	child.set_visible(true)
	move_child(child, -1)
