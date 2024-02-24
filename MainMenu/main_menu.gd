extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	find_child("MenuSwitch").set_menu("Title")
