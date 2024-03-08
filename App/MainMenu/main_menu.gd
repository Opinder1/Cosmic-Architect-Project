extends ScreenSwitch

signal game_selected(save_directory: String, multiplayer: bool)

func _connect_signals() -> void:
	$Title/Options/Singleplayer.pressed.connect(_on_singleplayer_pressed)
	$Title/Options/Multiplayer.pressed.connect(_on_multiplayer_pressed)
	$Title/Options/Options.pressed.connect(_on_options_pressed)
	$Title/Options/Exit.pressed.connect(_on_exit_pressed)
	
	$Menus/Tabs/Singleplayer.selected_save.connect(_selected_singleplayer_save)
	
	$Menus/Controls/Back.pressed.connect(_on_back)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_singleplayer_pressed() -> void:
	push_screen($Menus)
	$Menus/Tabs.current_tab = $Menus/Tabs/Singleplayer.get_index()

func _on_multiplayer_pressed() -> void:
	push_screen($Menus)
	$Menus/Tabs.current_tab = $Menus/Tabs/Multiplayer.get_index()

func _on_options_pressed() -> void:
	push_screen($Menus)
	$Menus/Tabs.current_tab = $Menus/Tabs/Options.get_index()
	
func _selected_singleplayer_save(save_directory: String) -> void:
	game_selected.emit(save_directory, false)
	
func _on_back() -> void:
	pop_screen()

func _ready() -> void:
	_connect_signals()
	
	transition_screen($Title)
