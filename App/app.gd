class_name App extends ScreenStack

func _connect_signals() -> void:
	$Controls/Back.pressed.connect(_on_quit)
	
	$Title/Options/Singleplayer.pressed.connect(_on_singleplayer_pressed)
	$Title/Options/Multiplayer.pressed.connect(_on_multiplayer_pressed)
	$Title/Options/Options.pressed.connect(_on_options_pressed)
	$Title/Options/Exit.pressed.connect(_on_exit_pressed)
	
	$MainMenu/Tabs/Singleplayer.selected_save.connect(_on_select_singleplayer_save)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_signals()
	
	set_screen($Title)
	underlay_screen($MenuScene, $Title)

func _on_quit() -> void:
	get_tree().quit()

func _on_singleplayer_pressed() -> void:
	push_screens(["MainMenu", "Controls"], {"tab": "singleplayer"})

func _on_multiplayer_pressed() -> void:
	push_screens(["MainMenu", "Controls"], {"tab": "multiplayer"})

func _on_options_pressed() -> void:
	push_screens(["MainMenu", "Controls"], {"tab": "options"})

func _on_exit_pressed() -> void:
	pop_screens()


func _on_select_singleplayer_save(save_directory: String) -> void:
	print("selected singleplayer save: ", save_directory)
	
	push_screens(["Game", "Controls"])

func _on_select_multiplayer_save(save_directory: String) -> void:
	print("selected multiplayer save: ", save_directory)
	
