extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ScreenStack.set_screens(["Title", "MenuScene"])
