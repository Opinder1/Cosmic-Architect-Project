class_name App extends Node

func _connect_signals() -> void:
	$ScreenStack.emptied.connect(_on_emptied)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	
	$ScreenStack.set_screens(["MenuScene", "Title"])

func _on_emptied() -> void:
	get_tree().quit()
