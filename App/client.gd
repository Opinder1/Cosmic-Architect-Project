extends ScreenStack

@onready var instance_schematic = preload("res://App/Game/game_instance.tscn")

func _connect_signals() -> void:
	$MainMenu.game_selected.connect(_on_game_selected)
	
func _on_game_selected(save_directory: String, is_multiplayer: bool) -> void:
	set_screen($LoadOverlay)
	
	var instance = instance_schematic.instantiate()
	instance.save_directory = save_directory
	
	$Game.add_child(instance)

	set_screen($Game)
	overlay_screen($DebugOverlay)

func _on_update_debug_info(debug_info: String) -> void:
	$DebugOverlay/DebugStats.text = debug_info
	
func _ready() -> void:
	print(OS.get_cmdline_args())
	print(OS.get_cmdline_user_args())
	
	_connect_signals()
	
	set_screen($MenuScene)
	overlay_screen($MainMenu)
	overlay_screen($DebugOverlay)
	
func _process(delta: float) -> void:
	pass
	
func _enter_tree() -> void:
	pass
	
func _exit_tree() -> void:
	pass

func _input(event):
	if event.is_action_released("in_game_pause_open"):
		overlay_screen($MainMenu)
