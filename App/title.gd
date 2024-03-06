class_name Title extends Screen

func _connect_signals() -> void:
	$Options/Singleplayer.pressed.connect(_on_singleplayer_pressed)
	$Options/Multiplayer.pressed.connect(_on_multiplayer_pressed)
	$Options/Options.pressed.connect(_on_options_pressed)
	$Options/Exit.pressed.connect(_on_exit_pressed)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()

func _on_singleplayer_pressed() -> void:
	push_screens(["MainMenu", "Controls"], {"tab": "singleplayer"})

func _on_multiplayer_pressed() -> void:
	push_screens(["MainMenu", "Controls"], {"tab": "multiplayer"})

func _on_options_pressed() -> void:
	push_screens(["MainMenu", "Controls"], {"tab": "options"})

func _on_exit_pressed() -> void:
	pop_screens()
