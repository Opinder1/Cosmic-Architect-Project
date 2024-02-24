extends Screen

signal singleplayer_pressed
signal multiplayer_pressed
signal options_pressed

func _connect_signals() -> void:
	$Options/Singleplayer.pressed.connect(_on_singleplayer_pressed)
	$Options/Multiplayer.pressed.connect(_on_multiplayer_pressed)
	$Options/Options.pressed.connect(_on_options_pressed)
	$Options/Exit.pressed.connect(_on_exit_pressed)

func _ready() -> void:
	_connect_signals()

func _on_singleplayer_pressed() -> void:
	set_screen("MainMenu")

func _on_multiplayer_pressed() -> void:
	pass

func _on_options_pressed() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()
