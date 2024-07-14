extends ScreenStack

func _connect_signals() -> void:
	$MainMenu.game_selected.connect(_on_game_selected)
	
func _on_game_selected(save_directory: String, is_multiplayer: bool) -> void:
	set_screen($LoadOverlay)
	$Game.start_game(save_directory)
	set_screen($Game)
	
func _ready() -> void:
	_connect_signals()
	
	set_screen($MenuScene)
	overlay_screen($MainMenu)
	
func _process(delta: float) -> void:
	CommandQueueServer.flush()

func _input(event):
	if event.is_action_released("in_game_pause_open"):
		overlay_screen($MainMenu)
