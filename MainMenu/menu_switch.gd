class_name MenuSwitch
extends Node


func _enter_tree():
	for child in get_children():
		child.set_visible(false)


func set_menu(menu):
	for child in get_children():
		child.set_visible(false)
		
	find_child(menu).set_visible(true)
