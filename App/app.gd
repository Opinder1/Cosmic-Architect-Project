extends ScreenStack

@onready var instance_schematic = preload("res://App/Game/game_instance.tscn")

func _connect_signals() -> void:
	$MainMenu.game_selected.connect(_on_game_selected)
	UniverseServer.connect("update_debug_info", _on_update_debug_info)
	
func _on_game_selected(save_directory: String, is_multiplayer: bool) -> void:
	set_screen($LoadOverlay)
	
	UniverseServer.start_local_universe(save_directory, "full_universe", UniverseServer.SERVER_TYPE_LOCAL, get_viewport().find_world_3d().scenario)
	
	$Game.add_child(instance_schematic.instantiate())

	set_screen($Game)
	overlay_screen($DebugOverlay)

func _on_update_debug_info(debug_info: String) -> void:
	$DebugOverlay/DebugStats.text = debug_info
	
func _ready() -> void:
	_connect_signals()
	
	set_screen($MenuScene)
	overlay_screen($MainMenu)
	overlay_screen($DebugOverlay)
	
func _process(delta: float) -> void:
	CommandServer.flush()
	
	UniverseServer.progress(delta)
	
func _enter_tree() -> void:
	UniverseServer.start_simulation(UniverseServer.THREAD_MODE_MULTI_THREADED)
	
func _exit_tree() -> void:
	UniverseServer.disconnect_from_universe()
	
	UniverseServer.stop_simulation()
	
	UniverseServer.wait_until_stopped()
	
	# Final flush for any left over commands
	while CommandServer.has_commands_left():
		CommandServer.flush()

func _input(event):
	if event.is_action_released("in_game_pause_open"):
		overlay_screen($MainMenu)
